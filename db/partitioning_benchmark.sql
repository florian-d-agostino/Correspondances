-- ==============================================================================
-- db/partitioning_benchmark.sql
-- Step 8 & Deliverables: Native PostgreSQL 16 Table Partitioning Benchmark
-- Scenario:
--   1. Partition the booking table by YEAR / MONTH using range partitioning.
--   2. Measure execution plan with EXPLAIN ANALYZE for targeted monthly query
--      (Demonstrating Partition Pruning where unneeded partitions are excluded).
--   3. Measure execution plan for cross-year/full-table query
--      (Demonstrating the overhead of scanning across multiple partition trees).
-- ==============================================================================

-- 1. Create a partitioned clone table: booking_partitioned
CREATE TABLE booking_partitioned (
    id BIGINT NOT NULL,
    booking_reference VARCHAR(40) NOT NULL,
    passenger_name VARCHAR(120) NOT NULL,
    traveler_profile VARCHAR(30) NOT NULL,
    departure_station_id BIGINT NOT NULL,
    arrival_station_id BIGINT NOT NULL,
    service_id BIGINT NOT NULL,
    seat_id BIGINT NOT NULL,
    travel_date DATE NOT NULL,
    total_price NUMERIC(10, 2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    pricing_id BIGINT,
    PRIMARY KEY (id, travel_date)
) PARTITION BY RANGE (travel_date);

-- 2. Create monthly partitions for the full 2026 operating year
CREATE TABLE booking_p_2026_01 PARTITION OF booking_partitioned
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE TABLE booking_p_2026_02 PARTITION OF booking_partitioned
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');

CREATE TABLE booking_p_2026_03 PARTITION OF booking_partitioned
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');

CREATE TABLE booking_p_2026_04 PARTITION OF booking_partitioned
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');

CREATE TABLE booking_p_2026_05 PARTITION OF booking_partitioned
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');

CREATE TABLE booking_p_2026_06 PARTITION OF booking_partitioned
    FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');

CREATE TABLE booking_p_2026_07 PARTITION OF booking_partitioned
    FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');

CREATE TABLE booking_p_2026_08 PARTITION OF booking_partitioned
    FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');

CREATE TABLE booking_p_2026_09 PARTITION OF booking_partitioned
    FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');

CREATE TABLE booking_p_2026_10 PARTITION OF booking_partitioned
    FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');

CREATE TABLE booking_p_2026_11 PARTITION OF booking_partitioned
    FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');

CREATE TABLE booking_p_2026_12 PARTITION OF booking_partitioned
    FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');

-- 3. Populate partitioned table from base booking table
INSERT INTO booking_partitioned
SELECT id, booking_reference, passenger_name, traveler_profile, 
       departure_station_id, arrival_station_id, service_id, seat_id, 
       travel_date, total_price, created_at, pricing_id
FROM booking;

-- 4. Benchmark A: Filtered on single month with PARTITION PRUNING
-- PostgreSQL will dynamically prune 11 out of 12 partitions!
EXPLAIN ANALYZE
SELECT count(*), sum(total_price)
FROM booking_partitioned
WHERE travel_date >= '2026-03-01' AND travel_date < '2026-04-01';

-- 5. Benchmark B: Full-table scan across all partitions
-- Overhead: Coordinator must route and combine sub-plans from 12 distinct physical tables
EXPLAIN ANALYZE
SELECT count(*), sum(total_price)
FROM booking_partitioned;
