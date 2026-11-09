-- ==============================================================================
-- V2__price_history.sql
-- Step 5: Evolution of Specifications - Tariff History with Validity Period
-- Migrates existing data in-place without rebuilding or destroying the database!
-- ==============================================================================

-- 1. Add temporal validity columns to the pricing table
ALTER TABLE pricing 
    ADD COLUMN IF NOT EXISTS valid_from DATE NOT NULL DEFAULT '2026-01-01',
    ADD COLUMN IF NOT EXISTS valid_to DATE;

-- 2. Drop the old unique constraint (comfort_class, traveler_profile, tariff_period)
ALTER TABLE pricing 
    DROP CONSTRAINT IF EXISTS uq_pricing_rule;

-- 3. Add new unique constraint including the validity start date
DO $$ 
BEGIN 
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_pricing_temporal'
    ) THEN
        ALTER TABLE pricing 
            ADD CONSTRAINT uq_pricing_temporal 
            UNIQUE (comfort_class, traveler_profile, tariff_period, valid_from);
    END IF;
END $$;

-- 4. Add check constraint to ensure valid_to is strictly greater than or equal to valid_from
DO $$ 
BEGIN 
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_pricing_validity_dates'
    ) THEN
        ALTER TABLE pricing 
            ADD CONSTRAINT chk_pricing_validity_dates 
            CHECK (valid_to IS NULL OR valid_to >= valid_from);
    END IF;
END $$;

-- 5. Add a foreign key link from booking to the applied pricing record
ALTER TABLE booking 
    ADD COLUMN IF NOT EXISTS pricing_id BIGINT;

-- Backfill pricing_id for existing 520,000 bookings
UPDATE booking b
SET pricing_id = (
    SELECT p.id 
    FROM pricing p 
    JOIN seat st ON st.id = b.seat_id 
    WHERE p.comfort_class = st.comfort_class 
      AND p.traveler_profile = b.traveler_profile 
      AND p.tariff_period = 'OFF_PEAK' 
    LIMIT 1
)
WHERE b.pricing_id IS NULL;

-- Enforce foreign key constraint
DO $$ 
BEGIN 
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_booking_pricing'
    ) THEN
        ALTER TABLE booking 
            ADD CONSTRAINT fk_booking_pricing 
            FOREIGN KEY (pricing_id) REFERENCES pricing(id) ON DELETE RESTRICT;
    END IF;
END $$;

-- 6. Insert new tariff evolution rules taking effect on 2026-07-01 (Summer rate increase)
-- The existing prices remain valid up to 2026-06-30
UPDATE pricing 
SET valid_to = '2026-06-30'
WHERE valid_to IS NULL AND valid_from = '2026-01-01';

-- Insert future tariffs from 2026-07-01 onwards (+10% indexation)
INSERT INTO pricing (comfort_class, traveler_profile, tariff_period, price_per_km, valid_from, valid_to)
SELECT 
    comfort_class, 
    traveler_profile, 
    tariff_period, 
    round(price_per_km * 1.10, 4), 
    '2026-07-01'::date, 
    NULL
FROM pricing
WHERE valid_to = '2026-06-30'
ON CONFLICT (comfort_class, traveler_profile, tariff_period, valid_from) DO NOTHING;
