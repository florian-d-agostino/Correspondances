-- ==============================================================================
-- db/seed_data.sql
-- Volume & Referential Dataset Generator for Correspondances Project
-- Generates > 500,000 consistent bookings over a full 1-year operating period
-- Re-runnable: clean and idempotent execution
-- ==============================================================================

-- Clear existing data in reverse dependency order
TRUNCATE TABLE booking_segment, booking, pricing, service_segment, 
               service_calendar, service_stop, service, seat, car, train, 
               line_station, line, station RESTART IDENTITY CASCADE;

BEGIN;

-- ==============================================================================
-- 1. Stations (30 Regional Stations in Southern / Southeastern France)
-- ==============================================================================
INSERT INTO station (name) VALUES
('Marseille-Saint-Charles'),
('Aix-en-Provence TGV'),
('Aix-en-Provence Centre'),
('Avignon TGV'),
('Avignon Centre'),
('Arles'),
('Nimes'),
('Montpellier-Saint-Roch'),
('Toulon'),
('Hyeres'),
('Saint-Raphael-Valescure'),
('Cannes'),
('Antibes'),
('Nice-Ville'),
('Monaco-Monte-Carlo'),
('Menton'),
('Gap'),
('Briancon'),
('Orange'),
('Montelimar'),
('Valence TGV'),
('Valence-Ville'),
('Lyon-Part-Dieu'),
('Lyon-Perrache'),
('Miramas'),
('Aubagne'),
('La Ciotat'),
('La Seyne-Six-Fours'),
('Les Arcs-Draguignan'),
('Grasse');

-- ==============================================================================
-- 2. Lines (12 Regional Lines)
-- ==============================================================================
INSERT INTO line (line_number) VALUES
('LINE_1_MARSEILLE_NICE'),
('LINE_2_MARSEILLE_LYON'),
('LINE_3_MARSEILLE_MONTPELLIER'),
('LINE_4_NICE_MENTON'),
('LINE_5_MARSEILLE_BRIANCON'),
('LINE_6_AIX_MARSEILLE'),
('LINE_7_CANNES_GRASSE'),
('LINE_8_AVIGNON_VALENCE'),
('LINE_9_TOULON_HYERES'),
('LINE_10_MIRAMAS_MARSEILLE'),
('LINE_11_LYON_VALENCE'),
('LINE_12_NIMES_AVIGNON');

-- ==============================================================================
-- 3. Line Stations (Ordered route stations with cumulative distance from origin)
-- ==============================================================================
-- LINE 1: Marseille-Saint-Charles -> Toulon -> Saint-Raphael -> Cannes -> Antibes -> Nice-Ville (224 km)
INSERT INTO line_station (line_id, station_id, position, distance_from_start)
SELECT l.id, s.id, pos, dist
FROM line l
CROSS JOIN (VALUES 
    ('Marseille-Saint-Charles', 1, 0.0),
    ('Aubagne', 2, 17.0),
    ('La Ciotat', 3, 37.0),
    ('Toulon', 4, 67.0),
    ('Saint-Raphael-Valescure', 5, 161.0),
    ('Cannes', 6, 193.0),
    ('Antibes', 7, 205.0),
    ('Nice-Ville', 8, 224.0)
) AS st(name, pos, dist)
JOIN station s ON s.name = st.name
WHERE l.line_number = 'LINE_1_MARSEILLE_NICE';

-- LINE 2: Marseille-Saint-Charles -> Arles -> Avignon Centre -> Montelimar -> Valence-Ville -> Lyon-Part-Dieu (325 km)
INSERT INTO line_station (line_id, station_id, position, distance_from_start)
SELECT l.id, s.id, pos, dist
FROM line l
CROSS JOIN (VALUES 
    ('Marseille-Saint-Charles', 1, 0.0),
    ('Miramas', 2, 53.0),
    ('Arles', 3, 77.0),
    ('Avignon Centre', 4, 114.0),
    ('Montelimar', 5, 198.0),
    ('Valence-Ville', 6, 243.0),
    ('Lyon-Part-Dieu', 7, 325.0)
) AS st(name, pos, dist)
JOIN station s ON s.name = st.name
WHERE l.line_number = 'LINE_2_MARSEILLE_LYON';

-- LINE 3: Marseille-Saint-Charles -> Arles -> Nimes -> Montpellier-Saint-Roch (175 km)
INSERT INTO line_station (line_id, station_id, position, distance_from_start)
SELECT l.id, s.id, pos, dist
FROM line l
CROSS JOIN (VALUES 
    ('Marseille-Saint-Charles', 1, 0.0),
    ('Miramas', 2, 53.0),
    ('Arles', 3, 77.0),
    ('Nimes', 4, 125.0),
    ('Montpellier-Saint-Roch', 5, 175.0)
) AS st(name, pos, dist)
JOIN station s ON s.name = st.name
WHERE l.line_number = 'LINE_3_MARSEILLE_MONTPELLIER';

-- LINE 4: Nice-Ville -> Monaco-Monte-Carlo -> Menton (30 km)
INSERT INTO line_station (line_id, station_id, position, distance_from_start)
SELECT l.id, s.id, pos, dist
FROM line l
CROSS JOIN (VALUES 
    ('Nice-Ville', 1, 0.0),
    ('Monaco-Monte-Carlo', 2, 16.0),
    ('Menton', 3, 30.0)
) AS st(name, pos, dist)
JOIN station s ON s.name = st.name
WHERE l.line_number = 'LINE_4_NICE_MENTON';

-- LINE 5: Marseille-Saint-Charles -> Aix-en-Provence Centre -> Gap -> Briancon (250 km)
INSERT INTO line_station (line_id, station_id, position, distance_from_start)
SELECT l.id, s.id, pos, dist
FROM line l
CROSS JOIN (VALUES 
    ('Marseille-Saint-Charles', 1, 0.0),
    ('Aix-en-Provence Centre', 2, 33.0),
    ('Gap', 3, 160.0),
    ('Briancon', 4, 250.0)
) AS st(name, pos, dist)
JOIN station s ON s.name = st.name
WHERE l.line_number = 'LINE_5_MARSEILLE_BRIANCON';

-- LINE 6: Marseille-Saint-Charles -> Aix-en-Provence Centre (33 km)
INSERT INTO line_station (line_id, station_id, position, distance_from_start)
SELECT l.id, s.id, pos, dist
FROM line l
CROSS JOIN (VALUES 
    ('Marseille-Saint-Charles', 1, 0.0),
    ('Aix-en-Provence Centre', 2, 33.0)
) AS st(name, pos, dist)
JOIN station s ON s.name = st.name
WHERE l.line_number = 'LINE_6_AIX_MARSEILLE';

-- LINE 7: Cannes -> Grasse (20 km)
INSERT INTO line_station (line_id, station_id, position, distance_from_start)
SELECT l.id, s.id, pos, dist
FROM line l
CROSS JOIN (VALUES 
    ('Cannes', 1, 0.0),
    ('Grasse', 2, 20.0)
) AS st(name, pos, dist)
JOIN station s ON s.name = st.name
WHERE l.line_number = 'LINE_7_CANNES_GRASSE';

-- LINE 8: Avignon Centre -> Orange -> Montelimar -> Valence-Ville (129 km)
INSERT INTO line_station (line_id, station_id, position, distance_from_start)
SELECT l.id, s.id, pos, dist
FROM line l
CROSS JOIN (VALUES 
    ('Avignon Centre', 1, 0.0),
    ('Orange', 2, 28.0),
    ('Montelimar', 3, 84.0),
    ('Valence-Ville', 4, 129.0)
) AS st(name, pos, dist)
JOIN station s ON s.name = st.name
WHERE l.line_number = 'LINE_8_AVIGNON_VALENCE';

-- LINE 9: Toulon -> La Seyne -> Hyeres (25 km)
INSERT INTO line_station (line_id, station_id, position, distance_from_start)
SELECT l.id, s.id, pos, dist
FROM line l
CROSS JOIN (VALUES 
    ('Toulon', 1, 0.0),
    ('La Seyne-Six-Fours', 2, 6.0),
    ('Hyeres', 3, 25.0)
) AS st(name, pos, dist)
JOIN station s ON s.name = st.name
WHERE l.line_number = 'LINE_9_TOULON_HYERES';

-- LINE 10: Miramas -> Marseille (53 km)
INSERT INTO line_station (line_id, station_id, position, distance_from_start)
SELECT l.id, s.id, pos, dist
FROM line l
CROSS JOIN (VALUES 
    ('Miramas', 1, 0.0),
    ('Marseille-Saint-Charles', 2, 53.0)
) AS st(name, pos, dist)
JOIN station s ON s.name = st.name
WHERE l.line_number = 'LINE_10_MIRAMAS_MARSEILLE';

-- LINE 11: Valence-Ville -> Lyon-Part-Dieu (105 km)
INSERT INTO line_station (line_id, station_id, position, distance_from_start)
SELECT l.id, s.id, pos, dist
FROM line l
CROSS JOIN (VALUES 
    ('Valence-Ville', 1, 0.0),
    ('Lyon-Perrache', 2, 100.0),
    ('Lyon-Part-Dieu', 3, 105.0)
) AS st(name, pos, dist)
JOIN station s ON s.name = st.name
WHERE l.line_number = 'LINE_11_LYON_VALENCE';

-- LINE 12: Nimes -> Avignon Centre (45 km)
INSERT INTO line_station (line_id, station_id, position, distance_from_start)
SELECT l.id, s.id, pos, dist
FROM line l
CROSS JOIN (VALUES 
    ('Nimes', 1, 0.0),
    ('Avignon Centre', 2, 45.0)
) AS st(name, pos, dist)
JOIN station s ON s.name = st.name
WHERE l.line_number = 'LINE_12_NIMES_AVIGNON';

-- ==============================================================================
-- 4. Rolling Stock: Trains (10 Rakes), Cars (5 cars/train), Seats (60 seats/car)
-- Total seats = 10 * 5 * 60 = 3,000 physical seats
-- ==============================================================================
INSERT INTO train (train_number)
SELECT 'TER_' || lpad(i::text, 4, '0')
FROM generate_series(8701, 8710) AS i;

-- Cars per train: Cars 1 & 2 are FIRST class (60 seats), Cars 3, 4, 5 are SECOND class
INSERT INTO car (train_id, car_number)
SELECT t.id, c
FROM train t
CROSS JOIN generate_series(1, 5) AS c;

-- Seats per car: 60 seats per car
INSERT INTO seat (car_id, seat_number, comfort_class)
SELECT 
    c.id, 
    s, 
    CASE WHEN c.car_number <= 2 THEN 'FIRST' ELSE 'SECOND' END
FROM car c
CROSS JOIN generate_series(1, 60) AS s;

-- ==============================================================================
-- 5. Pricing Grid (Initial v1: 2 classes x 4 traveler profiles x 3 periods = 24 entries)
-- ==============================================================================
INSERT INTO pricing (comfort_class, traveler_profile, tariff_period, price_per_km) VALUES
-- FIRST class
('FIRST', 'STANDARD', 'OFF_PEAK', 0.1600),
('FIRST', 'STANDARD', 'PEAK', 0.2200),
('FIRST', 'STANDARD', 'HOLIDAY', 0.2500),
('FIRST', 'YOUTH', 'OFF_PEAK', 0.1200),
('FIRST', 'YOUTH', 'PEAK', 0.1700),
('FIRST', 'YOUTH', 'HOLIDAY', 0.1900),
('FIRST', 'SENIOR', 'OFF_PEAK', 0.1100),
('FIRST', 'SENIOR', 'PEAK', 0.1500),
('FIRST', 'SENIOR', 'HOLIDAY', 0.1700),
('FIRST', 'SUBSCRIBER', 'OFF_PEAK', 0.0800),
('FIRST', 'SUBSCRIBER', 'PEAK', 0.1100),
('FIRST', 'SUBSCRIBER', 'HOLIDAY', 0.1300),

-- SECOND class
('SECOND', 'STANDARD', 'OFF_PEAK', 0.1100),
('SECOND', 'STANDARD', 'PEAK', 0.1500),
('SECOND', 'STANDARD', 'HOLIDAY', 0.1800),
('SECOND', 'YOUTH', 'OFF_PEAK', 0.0800),
('SECOND', 'YOUTH', 'PEAK', 0.1100),
('SECOND', 'YOUTH', 'HOLIDAY', 0.1300),
('SECOND', 'SENIOR', 'OFF_PEAK', 0.0750),
('SECOND', 'SENIOR', 'PEAK', 0.1000),
('SECOND', 'SENIOR', 'HOLIDAY', 0.1200),
('SECOND', 'SUBSCRIBER', 'OFF_PEAK', 0.0550),
('SECOND', 'SUBSCRIBER', 'PEAK', 0.0750),
('SECOND', 'SUBSCRIBER', 'HOLIDAY', 0.0900);

-- ==============================================================================
-- 6. Services (Train runs operating on specific lines)
-- 10 main daily services
-- ==============================================================================
INSERT INTO service (train_id, line_id, service_code)
VALUES
((SELECT id FROM train WHERE train_number = 'TER_8701'), (SELECT id FROM line WHERE line_number = 'LINE_1_MARSEILLE_NICE'), 'SRV_MN_01'),
((SELECT id FROM train WHERE train_number = 'TER_8702'), (SELECT id FROM line WHERE line_number = 'LINE_1_MARSEILLE_NICE'), 'SRV_MN_02'),
((SELECT id FROM train WHERE train_number = 'TER_8703'), (SELECT id FROM line WHERE line_number = 'LINE_2_MARSEILLE_LYON'), 'SRV_ML_01'),
((SELECT id FROM train WHERE train_number = 'TER_8704'), (SELECT id FROM line WHERE line_number = 'LINE_2_MARSEILLE_LYON'), 'SRV_ML_02'),
((SELECT id FROM train WHERE train_number = 'TER_8705'), (SELECT id FROM line WHERE line_number = 'LINE_3_MARSEILLE_MONTPELLIER'), 'SRV_MM_01'),
((SELECT id FROM train WHERE train_number = 'TER_8706'), (SELECT id FROM line WHERE line_number = 'LINE_3_MARSEILLE_MONTPELLIER'), 'SRV_MM_02'),
((SELECT id FROM train WHERE train_number = 'TER_8707'), (SELECT id FROM line WHERE line_number = 'LINE_4_NICE_MENTON'), 'SRV_NM_01'),
((SELECT id FROM train WHERE train_number = 'TER_8708'), (SELECT id FROM line WHERE line_number = 'LINE_5_MARSEILLE_BRIANCON'), 'SRV_MB_01'),
((SELECT id FROM train WHERE train_number = 'TER_8709'), (SELECT id FROM line WHERE line_number = 'LINE_8_AVIGNON_VALENCE'), 'SRV_AV_01'),
((SELECT id FROM train WHERE train_number = 'TER_8710'), (SELECT id FROM line WHERE line_number = 'LINE_11_LYON_VALENCE'), 'SRV_LV_01');

-- ==============================================================================
-- 7. Service Stops (Timetable for each service following the line stations)
-- ==============================================================================
INSERT INTO service_stop (service_id, station_id, stop_sequence, arrival_time, departure_time)
SELECT 
    s.id AS service_id,
    ls.station_id,
    ls.position AS stop_sequence,
    -- Simple realistic progressive schedule starting around 07:00 or 14:00
    ('06:30:00'::time + (ls.position * interval '22 minutes'))::time AS arrival_time,
    ('06:33:00'::time + (ls.position * interval '22 minutes'))::time AS departure_time
FROM service s
JOIN line_station ls ON ls.line_id = s.line_id;

-- Correct terminus arrivals/departures
UPDATE service_stop SET arrival_time = NULL WHERE stop_sequence = 1;
UPDATE service_stop SET departure_time = NULL 
WHERE (service_id, stop_sequence) IN (
    SELECT service_id, max(stop_sequence) FROM service_stop GROUP BY service_id
);

-- ==============================================================================
-- 8. Service Segments (Consecutive route legs between consecutive stops)
-- ==============================================================================
INSERT INTO service_segment (service_id, segment_sequence, departure_stop_id, arrival_stop_id, distance_km)
SELECT 
    dep.service_id,
    dep.stop_sequence AS segment_sequence,
    dep.id AS departure_stop_id,
    arr.id AS arrival_stop_id,
    abs(ls_arr.distance_from_start - ls_dep.distance_from_start) AS distance_km
FROM service_stop dep
JOIN service_stop arr ON arr.service_id = dep.service_id AND arr.stop_sequence = dep.stop_sequence + 1
JOIN service s ON s.id = dep.service_id
JOIN line_station ls_dep ON ls_dep.line_id = s.line_id AND ls_dep.station_id = dep.station_id
JOIN line_station ls_arr ON ls_arr.line_id = s.line_id AND ls_arr.station_id = arr.station_id;

-- ==============================================================================
-- 9. Service Calendar: Operating Dates across 1 Full Year (365 days)
-- 2026-01-01 to 2026-12-31 for all 10 services = 3,650 operating service days
-- ==============================================================================
INSERT INTO service_calendar (service_id, operating_date)
SELECT s.id, d::date
FROM service s
CROSS JOIN generate_series('2026-01-01'::date, '2026-12-31'::date, '1 day'::interval) AS d;

COMMIT;

-- ==============================================================================
-- 10. GENERATION OF 500,000+ CONSISTENT BOOKINGS & SEGMENT RESERVATIONS
-- Realistic volume distribution over the operating year:
-- - 10 services x 365 operating days = 3,650 service runs
-- - Each service has 300 seats (5 cars x 60 seats)
-- - Total capacity across all services/dates = 3,650 * 300 = 1,095,000 seat-runs!
-- - We take exactly 520,000 unique (service_id, travel_date, seat_id, segment_id)
--   ensuring mathematical zero collision with uq_seat_segment_date.
-- ==============================================================================

-- Build indexed pool of available service runs and seats
CREATE TEMP TABLE tmp_service_seats AS
SELECT 
    s.id AS service_id,
    cal.operating_date AS travel_date,
    st.id AS seat_id,
    st.comfort_class,
    seg.id AS segment_id,
    dep_stop.station_id AS dep_station_id,
    arr_stop.station_id AS arr_station_id,
    seg.distance_km,
    row_number() OVER (ORDER BY cal.operating_date, s.id, st.id) AS slot_id
FROM service s
JOIN service_calendar cal ON cal.service_id = s.id
JOIN train t ON t.id = s.train_id
JOIN car c ON c.train_id = t.id
JOIN seat st ON st.car_id = c.id
JOIN service_segment seg ON seg.service_id = s.id AND seg.segment_sequence = 1
JOIN service_stop dep_stop ON dep_stop.id = seg.departure_stop_id
JOIN service_stop arr_stop ON arr_stop.id = seg.arrival_stop_id;

-- Insert 520,000 bookings directly from unique slots
INSERT INTO booking (
    id,
    booking_reference,
    passenger_name,
    traveler_profile,
    departure_station_id,
    arrival_station_id,
    service_id,
    seat_id,
    travel_date,
    total_price,
    created_at
)
SELECT 
    tss.slot_id AS id,
    'BK-' || lpad(tss.slot_id::text, 8, '0') AS booking_reference,
    'Passenger_' || tss.slot_id AS passenger_name,
    (ARRAY['STANDARD', 'STANDARD', 'YOUTH', 'SENIOR', 'SUBSCRIBER'])[1 + (tss.slot_id % 5)] AS traveler_profile,
    tss.dep_station_id AS departure_station_id,
    tss.arr_station_id AS arrival_station_id,
    tss.service_id,
    tss.seat_id,
    tss.travel_date,
    round((tss.distance_km * (CASE WHEN tss.comfort_class = 'FIRST' THEN 0.1800 ELSE 0.1200 END)), 2) AS total_price,
    (tss.travel_date - interval '10 days' + ((tss.slot_id % 24) * interval '1 hour'))::timestamptz AS created_at
FROM tmp_service_seats tss
WHERE tss.slot_id <= 520000;

-- Reset sequence for future bookings
SELECT setval('booking_id_seq', (SELECT max(id) FROM booking));

-- Insert 520,000 matching booking segments
INSERT INTO booking_segment (
    booking_id,
    segment_id,
    service_id,
    seat_id,
    travel_date
)
SELECT 
    tss.slot_id AS booking_id,
    tss.segment_id,
    tss.service_id,
    tss.seat_id,
    tss.travel_date
FROM tmp_service_seats tss
WHERE tss.slot_id <= 520000;

DROP TABLE tmp_service_seats;

-- Verification query
SELECT 'Total bookings generated: ' || count(*) FROM booking;
SELECT 'Total segment reservations: ' || count(*) FROM booking_segment;
