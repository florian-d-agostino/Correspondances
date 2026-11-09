# Railway Ticketing System - Data Model Design (MCD, MLD, MPD)

## 1. Domain Overview
The railway ticketing platform models a regional network consisting of:
- Stations and interconnected lines enabling transfer points (correspondances).
- Train rolling stock partitioned into cars and numbered seats across two comfort classes (`FIRST`, `SECOND`).
- Scheduled services operating on specific calendar dates, serving stations with strict arrival and departure timetables.
- Multi-dimensional fare calculation based on distance, class, traveler profile, and tariff period.
- Point-to-point bookings where seats are reserved across elementary route segments rather than entire train runs, preventing seat under-utilization and eliminating overbooking.

---

## 2. Models Hierarchy & Design Choices

### 2.1 Conceptual Data Model (MCD)
- Located in: `docs/MCD.png`
- Core entities: `Station`, `Line`, `Train`, `Car`, `Seat`, `Service`, `ServiceStop`, `ServiceCalendar`, `Segment`, `Pricing`, `Booking`, `BookingSegment`.
- Key associations:
  - `Line` to `Station` via line positions with progressive distances.
  - `Train` composition into `Car` and `Seat`.
  - `Booking` reservation referencing a sequence of unit `Segment` legs.

### 2.2 Logical Data Model (MLD)
Relational translation ensuring third normal form (3NF):
- `station(id, name)`
- `line(id, line_number)`
- `line_station(line_id, station_id, position, distance_from_start)`
- `train(id, train_number)`
- `car(id, train_id, car_number)`
- `seat(id, car_id, seat_number, comfort_class)`
- `service(id, train_id, line_id, service_code)`
- `service_stop(id, service_id, station_id, stop_sequence, arrival_time, departure_time)`
- `service_calendar(id, service_id, operating_date)`
- `service_segment(id, service_id, segment_sequence, departure_stop_id, arrival_stop_id, distance_km)`
- `pricing(id, comfort_class, traveler_profile, tariff_period, price_per_km)`
- `booking(id, booking_reference, passenger_name, traveler_profile, departure_station_id, arrival_station_id, service_id, seat_id, travel_date, total_price, created_at)`
- `booking_segment(booking_id, segment_id, service_id, seat_id, travel_date)`

### 2.3 Physical Data Model (MPD) & PostgreSQL 16 Implementation
- Located in: `docs/MPD.png` and `db/schema_v1.sql` (Flyway migration `V1__init_schema.sql`).
- PostgreSQL specific data types:
  - `BIGSERIAL` / `BIGINT` for foreign keys and primary keys to handle large volumes (500k+ rows).
  - `NUMERIC(8,2)` / `NUMERIC(6,4)` for distance and pricing precision without floating point inaccuracies.
  - `TIME`, `DATE`, and `TIMESTAMPTZ` for precise operational scheduling.
  - `VARCHAR` with explicit constraints.

---

## 3. Core Database Constraints & Justifications

### 3.1 Referential Integrity (`ON DELETE` Strategy)
- **`RESTRICT`**: Applied to foundational network catalog entities (`station`, `line`, `train`). A station cannot be deleted if active lines, stops, or bookings depend on it.
- **`CASCADE`**: Applied to tight composition hierarchies (`train` -> `car` -> `seat`, `booking` -> `booking_segment`, `service` -> `service_stop`). Deleting a car automatically removes its associated seats.

### 3.2 Anti-Overbooking Segment Guarantee (Subject Core Rule)
A passenger traveling from station A to B occupies seat $S$. Another passenger traveling from B to C on the exact same train run can legally occupy seat $S$.
To guarantee consistency purely at the database engine level, table `booking_segment` enforces:
```sql
CONSTRAINT uq_seat_segment_date UNIQUE (service_id, travel_date, seat_id, segment_id);
```
Any concurrent attempt to double-book the same physical seat on the same route segment and date will trigger an immediate unique constraint violation error in PostgreSQL.

### 3.3 Domain `CHECK` Constraints
- Sequence & positive numbers:
  - `line_station.position > 0`, `distance_from_start >= 0`
  - `car.car_number > 0`, `seat.seat_number > 0`
  - `service_stop.stop_sequence > 0`
  - `service_segment.distance_km > 0`
  - `booking.total_price >= 0`
  - `pricing.price_per_km > 0`
- Timetable validation:
  - `service_stop.arrival_time <= service_stop.departure_time` (arrival cannot occur after departure).
- Enumerated domain domains:
  - `comfort_class IN ('FIRST', 'SECOND')`
  - `traveler_profile IN ('STANDARD', 'YOUTH', 'SENIOR', 'SUBSCRIBER')`
  - `tariff_period IN ('OFF_PEAK', 'PEAK', 'HOLIDAY')`
