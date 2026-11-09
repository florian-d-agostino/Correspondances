# Performance Analysis & Optimization Report (Dossier Performance)

## 1. Executive Summary
This report analyzes database execution performance across **520,000 reservation records** in PostgreSQL 16. It documents:
- Execution plan analysis (`EXPLAIN ANALYZE`) before and after indexing.
- Index rationale and ordering justifications.
- Detection and architectural resolution of the JPA N+1 select problem.
- Native table partitioning benchmarking (partition pruning gains vs cross-partition scan overhead).

---

## 2. Query Plan Analysis & Indexing (`EXPLAIN ANALYZE`)

### 2.1 Target Query
Searching all bookings for a given operating travel date (`2026-06-15`):
```sql
SELECT * FROM booking WHERE travel_date = '2026-06-15';
```

### 2.2 Before Index Optimization: Parallel Sequential Scan
Without an index on `travel_date`, PostgreSQL must scan every data page of the 520,000 rows across parallel workers:
```text
Gather  (cost=1000.00..21496.43 rows=2981 width=102) (actual time=31.128..36.716 rows=3000 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  ->  Parallel Seq Scan on booking  (cost=0.00..20198.33 rows=1242 width=102) (actual time=23.700..24.313 rows=1000 loops=3)
        Filter: (travel_date = '2026-06-15'::date)
        Rows Removed by Filter: 172333
Planning Time: 5.329 ms
Execution Time: 37.706 ms
```
- **Observations:** The query engine read 172,333 rows per worker and performed intensive disk I/O.
- **Execution Time:** **37.71 ms**.

---

### 2.3 Creation of Justified Composite Index
We created a composite B-Tree index:
```sql
CREATE INDEX idx_booking_travel_date_service ON booking (travel_date, service_id);
```
**Column Order Justification:**
1. **`travel_date` as leading column:** Every booking lookup and reservation calendar search starts with a date or date-range filter. Because range predicates on leading columns allow immediate sub-tree narrowing, `travel_date` must come first.
2. **`service_id` as secondary column:** Allows pinpointing the exact train service within that date without accessing the heap table, enabling index-only scans or high-selectivity scans.

---

### 2.4 After Optimization: B-Tree Index Scan
```text
Index Scan using idx_booking_travel_date_service on booking  (cost=0.42..4930.34 rows=2981 width=102) (actual time=0.052..0.272 rows=3000 loops=1)
  Index Cond: (travel_date = '2026-06-15'::date)
Planning Time: 1.248 ms
Execution Time: 0.457 ms
```
- **Result:** Execution time dropped from **37.71 ms** down to **0.46 ms** (an **82x speedup** / ~98.8% latency reduction).
- **Planner vs Reality:** Cost estimate dropped from 21,496 to 4,930; actual rows returned (3,000) matched planner estimate (2,981) with 99.4% accuracy.

---

## 3. Resolving the JPA N+1 Query Problem

### 3.1 Identification of the N+1 Issue
When listing bookings in a web endpoint, Spring Data JPA naively issues 1 query to fetch the bookings, and then $N$ additional queries to fetch `Station`, `Service`, `Train`, `Line`, and `Seat` proxies for each booking row:
```text
Endpoint: GET /api/bookings/benchmark/naive?limit=50
1 Query:  SELECT b1_0.id, ... FROM booking b1_0 WHERE b1_0.travel_date=? LIMIT 50;
50 Queries: SELECT s1_0.id, ... FROM station s1_0 WHERE s1_0.id=?;
50 Queries: SELECT st1_0.id, ... FROM service st1_0 WHERE st1_0.id=?;
... Total queries executed: 1 + (4 * 50) = 201 SQL roundtrips!
```

### 3.2 Solution via `JOIN FETCH`
In [`BookingRepository.java`](file:///c:/Users/dagos/Desktop/École/Java/Ecole/Correspondances/src/main/java/Correspondances/LaPlateforme/repository/BookingRepository.java):
```java
@Query("SELECT b FROM Booking b " +
       "JOIN FETCH b.departureStation " +
       "JOIN FETCH b.arrivalStation " +
       "JOIN FETCH b.service s " +
       "JOIN FETCH s.train " +
       "JOIN FETCH s.line " +
       "JOIN FETCH b.seat st " +
       "JOIN FETCH st.car " +
       "WHERE b.travelDate = :travelDate")
List<Booking> findBookingsOptimized(@Param("travelDate") LocalDate travelDate, Pageable pageable);
```
- **Proof:** Endpoint `GET /api/bookings/benchmark/optimized` issues **exactly 1 single query** utilizing inner/left joins, reducing network overhead to the database by over 99%.

---

## 4. Native Table Partitioning Benchmark

### 4.1 Architecture
The table `booking_partitioned` was partitioned by `RANGE (travel_date)` across 12 monthly partitions (`booking_p_2026_01` to `booking_p_2026_12`).

### 4.2 Benchmark 1: Targeted Month Filter (Demonstrating Partition Pruning)
```sql
EXPLAIN ANALYZE
SELECT count(*), sum(total_price)
FROM booking_partitioned
WHERE travel_date >= '2026-03-01' AND travel_date < '2026-04-01';
```
**Plan:**
```text
Aggregate  (cost=1965.50..1965.51 rows=1 width=40) (actual time=17.020..17.021 rows=1 loops=1)
  ->  Seq Scan on booking_p_2026_03 booking_partitioned  (cost=0.00..1964.90 rows=120 width=16) (actual time=0.009..11.294 rows=93000 loops=1)
        Filter: ((travel_date >= '2026-03-01'::date) AND (travel_date < '2026-04-01'::date))
Planning Time: 0.854 ms
Execution Time: 17.047 ms
```
- **Benefit:** PostgreSQL completely pruned 11 out of 12 child tables. Only `booking_p_2026_03` was opened.

### 4.3 Benchmark 2: Cross-Year Full Scan (Cost of Partitioning)
```sql
EXPLAIN ANALYZE
SELECT count(*), sum(total_price)
FROM booking_partitioned;
```
**Plan:**
```text
Finalize Aggregate  (cost=11390.19..11390.20 rows=1 width=40) (actual time=47.520..51.501 rows=1 loops=1)
  ->  Parallel Append  (cost=0.00..10107.82 rows=56428 width=16) (actual time=0.010..29.953 rows=173333 loops=3)
        -> 12 child scans across booking_p_2026_01 to booking_p_2026_12
Planning Time: 2.287 ms
Execution Time: 51.788 ms
```
- **Conclusion:** While localized time queries run in **17.0 ms**, a global scan costs **51.8 ms** because the planner must manage an `Append` node across 12 separate relation trees. Partitioning is ideal for archival and localized time queries, but introduces coordination overhead for unconstrained analytics.
