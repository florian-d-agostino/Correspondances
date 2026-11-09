-- ==============================================================================
-- CORRESPONDANCES PROJECT - POSTGRESQL 16 SCHEMA (MPD)
-- Compatible with Lucidchart ERD SQL Import & Database Initialization
-- ==============================================================================


-- ==============================================================================
-- 1. Stations & Railway Network Infrastructure
-- ==============================================================================

CREATE TABLE station (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(120) NOT NULL UNIQUE
);


CREATE TABLE line (
    id BIGSERIAL PRIMARY KEY,
    line_number VARCHAR(30) NOT NULL UNIQUE
);


CREATE TABLE line_station (
    line_id BIGINT NOT NULL,
    station_id BIGINT NOT NULL,
    position INT NOT NULL,
    distance_from_start NUMERIC(8, 2) NOT NULL,

    PRIMARY KEY (line_id, station_id),

    CONSTRAINT fk_line_station_line
        FOREIGN KEY (line_id) REFERENCES line(id) ON DELETE RESTRICT,

    CONSTRAINT fk_line_station_station
        FOREIGN KEY (station_id) REFERENCES station(id) ON DELETE RESTRICT,

    CONSTRAINT uq_line_station_position
        UNIQUE (line_id, position),

    CONSTRAINT chk_line_station_position
        CHECK (position > 0),

    CONSTRAINT chk_line_station_distance
        CHECK (distance_from_start >= 0)
);


-- ==============================================================================
-- 2. Rolling Stock (Trains, Cars, Seats)
-- ==============================================================================

CREATE TABLE train (
    id BIGSERIAL PRIMARY KEY,
    train_number VARCHAR(30) NOT NULL UNIQUE
);


CREATE TABLE car (
    id BIGSERIAL PRIMARY KEY,
    train_id BIGINT NOT NULL,
    car_number INT NOT NULL,

    CONSTRAINT fk_car_train
        FOREIGN KEY (train_id) REFERENCES train(id) ON DELETE CASCADE,

    CONSTRAINT uq_train_car
        UNIQUE (train_id, car_number),

    CONSTRAINT chk_car_number
        CHECK (car_number > 0)
);


CREATE TABLE seat (
    id BIGSERIAL PRIMARY KEY,
    car_id BIGINT NOT NULL,
    seat_number INT NOT NULL,
    comfort_class VARCHAR(20) NOT NULL,

    CONSTRAINT fk_seat_car
        FOREIGN KEY (car_id) REFERENCES car(id) ON DELETE CASCADE,

    CONSTRAINT uq_car_seat
        UNIQUE (car_id, seat_number),

    CONSTRAINT chk_seat_number
        CHECK (seat_number > 0),

    CONSTRAINT chk_seat_comfort_class
        CHECK (comfort_class IN ('FIRST', 'SECOND'))
);


-- ==============================================================================
-- 3. Operations, Services & Timetable Stops
-- ==============================================================================

CREATE TABLE service (
    id BIGSERIAL PRIMARY KEY,
    train_id BIGINT NOT NULL,
    line_id BIGINT NOT NULL,
    service_code VARCHAR(30) NOT NULL UNIQUE,

    CONSTRAINT fk_service_train 
        FOREIGN KEY (train_id) REFERENCES train(id) ON DELETE RESTRICT,

    CONSTRAINT fk_service_line 
        FOREIGN KEY (line_id) REFERENCES line(id) ON DELETE RESTRICT
);


CREATE TABLE service_stop (
    id BIGSERIAL PRIMARY KEY,
    service_id BIGINT NOT NULL,
    station_id BIGINT NOT NULL,
    stop_sequence INT NOT NULL,
    arrival_time TIME,
    departure_time TIME,

    CONSTRAINT fk_service_stop_service 
        FOREIGN KEY (service_id) REFERENCES service(id) ON DELETE CASCADE,

    CONSTRAINT fk_service_stop_station 
        FOREIGN KEY (station_id) REFERENCES station(id) ON DELETE RESTRICT,

    CONSTRAINT uq_service_stop_sequence 
        UNIQUE (service_id, stop_sequence),

    CONSTRAINT chk_service_stop_sequence 
        CHECK (stop_sequence > 0),

    CONSTRAINT chk_service_stop_times 
        CHECK (
            arrival_time IS NULL 
            OR departure_time IS NULL 
            OR arrival_time <= departure_time
        )
);


CREATE TABLE service_calendar (
    id BIGSERIAL PRIMARY KEY,
    service_id BIGINT NOT NULL,
    operating_date DATE NOT NULL,

    CONSTRAINT fk_service_calendar_service 
        FOREIGN KEY (service_id) REFERENCES service(id) ON DELETE CASCADE,

    CONSTRAINT uq_service_calendar 
        UNIQUE (service_id, operating_date)
);


-- ==============================================================================
-- 4. Route Segments (Consecutive Legs Between Stops)
-- ==============================================================================

CREATE TABLE service_segment (
    id BIGSERIAL PRIMARY KEY,
    service_id BIGINT NOT NULL,
    segment_sequence INT NOT NULL,
    departure_stop_id BIGINT NOT NULL,
    arrival_stop_id BIGINT NOT NULL,
    distance_km NUMERIC(8, 2) NOT NULL,

    CONSTRAINT fk_service_segment_service 
        FOREIGN KEY (service_id) REFERENCES service(id) ON DELETE CASCADE,

    CONSTRAINT fk_service_segment_dep_stop 
        FOREIGN KEY (departure_stop_id) REFERENCES service_stop(id) ON DELETE RESTRICT,

    CONSTRAINT fk_service_segment_arr_stop 
        FOREIGN KEY (arrival_stop_id) REFERENCES service_stop(id) ON DELETE RESTRICT,

    CONSTRAINT uq_service_segment_sequence 
        UNIQUE (service_id, segment_sequence),

    CONSTRAINT chk_service_segment_sequence 
        CHECK (segment_sequence > 0),

    CONSTRAINT chk_service_segment_distance 
        CHECK (distance_km > 0)
);


-- ==============================================================================
-- 5. Pricing Grid (Initial v1 Configuration)
-- ==============================================================================

CREATE TABLE pricing (
    id BIGSERIAL PRIMARY KEY,
    comfort_class VARCHAR(20) NOT NULL,
    traveler_profile VARCHAR(30) NOT NULL,
    tariff_period VARCHAR(30) NOT NULL,
    price_per_km NUMERIC(6, 4) NOT NULL,

    CONSTRAINT uq_pricing_rule 
        UNIQUE (comfort_class, traveler_profile, tariff_period),

    CONSTRAINT chk_pricing_class 
        CHECK (comfort_class IN ('FIRST', 'SECOND')),

    CONSTRAINT chk_pricing_profile 
        CHECK (traveler_profile IN ('STANDARD', 'YOUTH', 'SENIOR', 'SUBSCRIBER')),

    CONSTRAINT chk_pricing_period 
        CHECK (tariff_period IN ('OFF_PEAK', 'PEAK', 'HOLIDAY')),

    CONSTRAINT chk_pricing_price 
        CHECK (price_per_km > 0)
);


-- ==============================================================================
-- 6. Bookings & Segment-Level Concurrency Protection
-- ==============================================================================

CREATE TABLE booking (
    id BIGSERIAL PRIMARY KEY,
    booking_reference VARCHAR(40) NOT NULL UNIQUE,
    passenger_name VARCHAR(120) NOT NULL,
    traveler_profile VARCHAR(30) NOT NULL,
    departure_station_id BIGINT NOT NULL,
    arrival_station_id BIGINT NOT NULL,
    service_id BIGINT NOT NULL,
    seat_id BIGINT NOT NULL,
    travel_date DATE NOT NULL,
    total_price NUMERIC(10, 2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_booking_dep_station 
        FOREIGN KEY (departure_station_id) REFERENCES station(id) ON DELETE RESTRICT,

    CONSTRAINT fk_booking_arr_station 
        FOREIGN KEY (arrival_station_id) REFERENCES station(id) ON DELETE RESTRICT,

    CONSTRAINT fk_booking_service 
        FOREIGN KEY (service_id) REFERENCES service(id) ON DELETE RESTRICT,

    CONSTRAINT fk_booking_seat 
        FOREIGN KEY (seat_id) REFERENCES seat(id) ON DELETE RESTRICT,

    CONSTRAINT chk_booking_total_price 
        CHECK (total_price >= 0)
);


-- Critical table: enforces strict physical seat non-overlap per route segment
CREATE TABLE booking_segment (
    booking_id BIGINT NOT NULL,
    segment_id BIGINT NOT NULL,
    service_id BIGINT NOT NULL,
    seat_id BIGINT NOT NULL,
    travel_date DATE NOT NULL,

    PRIMARY KEY (booking_id, segment_id),

    CONSTRAINT fk_booking_segment_booking 
        FOREIGN KEY (booking_id) REFERENCES booking(id) ON DELETE CASCADE,

    CONSTRAINT fk_booking_segment_segment 
        FOREIGN KEY (segment_id) REFERENCES service_segment(id) ON DELETE RESTRICT,

    CONSTRAINT fk_booking_segment_service 
        FOREIGN KEY (service_id) REFERENCES service(id) ON DELETE RESTRICT,

    CONSTRAINT fk_booking_segment_seat 
        FOREIGN KEY (seat_id) REFERENCES seat(id) ON DELETE RESTRICT,

    -- Absolute domain rule: prevents duplicate booking of a physical seat on the same segment and date
    CONSTRAINT uq_seat_segment_date 
        UNIQUE (service_id, travel_date, seat_id, segment_id)
);
