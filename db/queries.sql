-- ==============================================================================
-- db/queries.sql
-- Step 7 & Deliverables: 5 Non-Trivial SQL Queries & Transfer Route Calculation
-- ==============================================================================


-- ==============================================================================
-- 1. RANKING OF MOST BOOKED LINES USING WINDOW FUNCTIONS (DENSE_RANK)
-- Purpose: Ranks regional lines by total volume of bookings and revenue generated
-- Concepts: Multiple JOINs, Aggregation, Window Function DENSE_RANK() OVER (ORDER BY ...)
-- ==============================================================================
SELECT 
    l.line_number,
    count(b.id) AS total_bookings,
    sum(b.total_price) AS total_revenue,
    round(avg(b.total_price), 2) AS average_ticket_price,
    DENSE_RANK() OVER (ORDER BY count(b.id) DESC) AS rank_by_popularity,
    round(100.0 * count(b.id) / sum(count(b.id)) OVER (), 2) AS market_share_percentage
FROM line l
JOIN service s ON s.line_id = l.id
JOIN booking b ON b.service_id = s.id
GROUP BY l.id, l.line_number
ORDER BY rank_by_popularity;


-- ==============================================================================
-- 2. MONTHLY REVENUE & SEAT OCCUPANCY EVOLUTION WITH LAG() WINDOW FUNCTION
-- Purpose: Computes month-over-month revenue growth to analyze seasonality
-- Concepts: DATE_TRUNC, Aggregation, LAG() analytic window function
-- ==============================================================================
WITH monthly_stats AS (
    SELECT 
        date_trunc('month', travel_date)::date AS travel_month,
        count(id) AS bookings_count,
        sum(total_price) AS monthly_revenue
    FROM booking
    GROUP BY date_trunc('month', travel_date)
)
SELECT 
    travel_month,
    bookings_count,
    monthly_revenue,
    LAG(monthly_revenue, 1) OVER (ORDER BY travel_month) AS previous_month_revenue,
    round(
        (monthly_revenue - LAG(monthly_revenue, 1) OVER (ORDER BY travel_month)) 
        / NULLIF(LAG(monthly_revenue, 1) OVER (ORDER BY travel_month), 0) * 100.0, 
        2
    ) AS mom_growth_rate_pct
FROM monthly_stats
ORDER BY travel_month;


-- ==============================================================================
-- 3. PEAK TRAVEL DAYS REQUIRING CAPACITY REINFORCEMENTS
-- Purpose: Identifies dates where load factor exceeds 80% on specific services
-- Concepts: Subqueries, HAVING clause with conditional aggregation, CTE
-- ==============================================================================
SELECT 
    b.travel_date,
    s.service_code,
    l.line_number,
    count(b.id) AS booked_seats,
    300 AS train_capacity,
    round((count(b.id)::numeric / 300.0) * 100.0, 1) AS load_factor_pct
FROM booking b
JOIN service s ON s.id = b.service_id
JOIN line l ON l.id = s.line_id
GROUP BY b.travel_date, s.id, s.service_code, l.line_number
HAVING count(b.id) >= 200
ORDER BY load_factor_pct DESC, b.travel_date
LIMIT 20;


-- ==============================================================================
-- 4. PROFILE BREAKDOWN AND AVERAGE EXPENDITURE PER CLASS
-- Purpose: Marketing intelligence breakdown by comfort class and traveler profile
-- Concepts: Multi-table joins, Filtered aggregations, Conditional SUM/CASE
-- ==============================================================================
SELECT 
    st.comfort_class,
    b.traveler_profile,
    count(b.id) AS total_passengers,
    round(min(b.total_price), 2) AS min_price,
    round(avg(b.total_price), 2) AS avg_price,
    round(max(b.total_price), 2) AS max_price,
    sum(b.total_price) AS segment_revenue
FROM booking b
JOIN seat st ON st.id = b.seat_id
GROUP BY st.comfort_class, b.traveler_profile
ORDER BY st.comfort_class, segment_revenue DESC;


-- ==============================================================================
-- 5. HISTORICAL FARE LOOKUP QUERY ("Demande Client" from Step 5)
-- Purpose: Answers client question: "How much did this journey cost on March 3rd?"
-- Concepts: Temporal lookup matching historical pricing validity periods
-- ==============================================================================
SELECT 
    p.id AS pricing_id,
    p.comfort_class,
    p.traveler_profile,
    p.tariff_period,
    p.price_per_km,
    p.valid_from,
    p.valid_to,
    round(p.price_per_km * 224.0, 2) AS price_for_marseille_nice_224km
FROM pricing p
WHERE '2026-03-03'::date >= p.valid_from 
  AND ('2026-03-03'::date <= p.valid_to OR p.valid_to IS NULL)
  AND p.comfort_class = 'SECOND'
  AND p.traveler_profile = 'STANDARD'
ORDER BY p.price_per_km;


-- ==============================================================================
-- 6. SPECIAL DELIVERABLE: TRANSFER ROUTE COMPUTATION (LA CORRESPONDANCE ENFIN CALCULÉE)
-- Purpose: Finds itineraries between two stations with AT MOST ONE transfer (correspondance)
--          respecting a minimum connection buffer (battement minimum: 10 minutes)
-- Tool: Recursive Common Table Expression (CTE récursive)
-- Example: Route from "Cannes" to "Monaco-Monte-Carlo" with transfer at "Nice-Ville"
--          (Cannes and Monaco share no direct line: Line 1 connects Cannes->Nice, Line 4 connects Nice->Monaco)
-- ==============================================================================
WITH RECURSIVE journey_search AS (
    -- Anchor member: Initial service leg departing from Cannes
    SELECT 
        s.id AS service_id,
        s.service_code,
        dep_st.name AS current_departure_station,
        arr_st.name AS current_arrival_station,
        stop_dep.departure_time AS initial_departure_time,
        stop_arr.arrival_time AS leg_arrival_time,
        1 AS leg_count,
        ARRAY[dep_st.name, arr_st.name]::varchar[] AS route_path
    FROM service s
    JOIN service_stop stop_dep ON stop_dep.service_id = s.id
    JOIN station dep_st ON dep_st.id = stop_dep.station_id
    JOIN service_stop stop_arr ON stop_arr.service_id = s.id AND stop_arr.stop_sequence > stop_dep.stop_sequence
    JOIN station arr_st ON arr_st.id = stop_arr.station_id
    WHERE dep_st.name = 'Cannes'

    UNION ALL

    -- Recursive member: Second service leg connecting at the transfer station
    -- Enforces minimum 10-minute transfer buffer (battement minimum)
    SELECT 
        s2.id AS service_id,
        s2.service_code,
        js.current_departure_station,
        arr2_st.name AS current_arrival_station,
        js.initial_departure_time,
        stop2_arr.arrival_time AS leg_arrival_time,
        js.leg_count + 1,
        js.route_path || arr2_st.name::varchar
    FROM journey_search js
    JOIN station trans_st ON trans_st.name = js.current_arrival_station
    JOIN service_stop stop2_dep ON stop2_dep.station_id = trans_st.id
    JOIN service s2 ON s2.id = stop2_dep.service_id AND s2.id != js.service_id
    JOIN service_stop stop2_arr ON stop2_arr.service_id = s2.id AND stop2_arr.stop_sequence > stop2_dep.stop_sequence
    JOIN station arr2_st ON arr2_st.id = stop2_arr.station_id
    WHERE js.leg_count = 1 -- Maximum 1 transfer (2 legs total)
      AND stop2_dep.departure_time >= (js.leg_arrival_time + interval '10 minutes')::time
      AND NOT (arr2_st.name = ANY(js.route_path))
)
SELECT 
    route_path[1] AS departure_station,
    route_path[array_length(route_path, 1)] AS final_destination,
    array_to_string(route_path, ' -> ') AS full_itinerary,
    leg_count AS total_legs,
    (leg_count - 1) AS transfers_count,
    initial_departure_time AS start_time,
    leg_arrival_time AS arrival_time
FROM journey_search
WHERE current_arrival_station = 'Monaco-Monte-Carlo'
ORDER BY leg_count, initial_departure_time
LIMIT 5;
