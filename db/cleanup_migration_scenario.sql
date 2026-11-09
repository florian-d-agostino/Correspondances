-- ==============================================================================
-- db/cleanup_migration_scenario.sql
-- Deliverable: "La migration qui doit d'abord nettoyer"
-- Scenario:
--   A business requirement emerges: "A passenger cannot book multiple seats
--   on the exact same departure date and time under the same passenger name".
--   In our 520,000 legacy dataset, dummy names like 'Passenger_1' or repeated
--   passenger names conflict with this new strict business constraint.
--   A direct `ALTER TABLE booking ADD CONSTRAINT ...` will FAIL with a violation error.
--
-- This script:
--   1. Detects duplicate non-compliant rows
--   2. Decides on an auditable resolution (archives & de-duplicates)
--   3. Logs/traces the cleanup into an audit table
--   4. Safely applies the unique constraint
--   5. Is fully repeatable/re-runnable (idempotent)
-- ==============================================================================

BEGIN;

-- 1. Create audit/trace log table
CREATE TABLE IF NOT EXISTS migration_cleanup_audit (
    id BIGSERIAL PRIMARY KEY,
    cleaned_table VARCHAR(60) NOT NULL,
    record_id BIGINT NOT NULL,
    conflict_key TEXT NOT NULL,
    action_taken VARCHAR(100) NOT NULL,
    cleaned_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. Detect & trace conflicts
-- Find any duplicates on (passenger_name, travel_date, service_id)
WITH duplicates AS (
    SELECT 
        id,
        passenger_name,
        travel_date,
        service_id,
        row_number() OVER (
            PARTITION BY passenger_name, travel_date, service_id 
            ORDER BY id
        ) AS duplicate_rank
    FROM booking
)
INSERT INTO migration_cleanup_audit (cleaned_table, record_id, conflict_key, action_taken)
SELECT 
    'booking',
    d.id,
    d.passenger_name || ' | ' || d.travel_date || ' | service:' || d.service_id,
    'De-duplicated passenger identifier suffix to preserve historical booking'
FROM duplicates d
WHERE d.duplicate_rank > 1;

-- 3. Resolve the conflicts by making passenger references distinct and historical
WITH duplicates AS (
    SELECT 
        id,
        row_number() OVER (
            PARTITION BY passenger_name, travel_date, service_id 
            ORDER BY id
        ) AS duplicate_rank
    FROM booking
)
UPDATE booking b
SET passenger_name = b.passenger_name || '_dup_' || d.duplicate_rank
FROM duplicates d
WHERE b.id = d.id AND d.duplicate_rank > 1;

-- 4. Safely enforce the new unique constraint
DO $$ 
BEGIN 
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_booking_passenger_service_date'
    ) THEN
        ALTER TABLE booking 
            ADD CONSTRAINT uq_booking_passenger_service_date 
            UNIQUE (passenger_name, travel_date, service_id);
    END IF;
END $$;

COMMIT;

-- Verify audit trail count
SELECT count(*) AS total_cleaned_records FROM migration_cleanup_audit;
