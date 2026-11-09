# Correspondances - Regional Railway Ticketing Platform

> Enterprise-grade relational database architecture, high-volume data generation (520k+ rows), Spring Data JPA layer, temporal migrations, and query performance optimization.

---

## 1. Project Overview & Deliverables
This repository contains the complete implementation of the **Correspondances** system:
1. **Conceptual, Logical, and Physical Data Models (MCD, MLD, MPD)**: Available in `docs/` with justifications in `docs/data_model_justification.md`.
2. **PostgreSQL 16 Schema & Constraints**: Flyway versioned migrations under `src/main/resources/db/migration/`.
3. **Repeatable Volume Dataset Generator**: Seeding script `db/seed_data.sql` generating over 520,000 consistent bookings.
4. **Spring Boot / Spring Data JPA Access Layer**: Read-only REST endpoints and interactive Swagger UI.
5. **Specification Evolution & In-Place Migration**: Flyway `V2__price_history.sql` introducing temporal price tracking without rebuilding the database.
6. **Performance & Query Optimization Dossier**: `docs/performance_report.md` with `EXPLAIN ANALYZE` benchmarks, composite index justifications, and N+1 query resolutions.
7. **Advanced SQL Queries**: `db/queries.sql` featuring multi-table joins, analytic window functions (`DENSE_RANK`, `LAG`), and a recursive CTE connection engine (`Cannes -> Monaco` transfer search).
8. **Automated Cleanup Migration**: `db/cleanup_migration_scenario.sql` handling pre-migration data sanitization and auditing.
9. **Native Partitioning Benchmark**: `db/partitioning_benchmark.sql` demonstrating monthly partition pruning benefits and full-scan overhead.

---

## 2. Quick Start & Launch Instructions

### Prerequisites
- Java 21 JDK
- Maven 3.9+
- Docker Desktop (or local PostgreSQL 16)

### Step 1: Start PostgreSQL 16
```bash
docker-compose up -d
```
PostgreSQL will be running on `localhost:5432` (User: `postgres`, Password: `postgrespassword`, Database: `correspondances`).

### Step 2: Seed 520,000 Bookings (Repeatable)
Execute the high-volume data generator:
```bash
# On Linux / macOS / Git Bash:
docker exec -i correspondances-db psql -U postgres -d correspondances < db/seed_data.sql

# On Windows PowerShell:
Get-Content db/seed_data.sql -Raw | docker exec -i correspondances-db psql -U postgres -d correspondances
```

### Step 3: Run Spring Boot Application
```bash
mvn spring-boot:run
```
The application will start on port `8080`. Flyway migrations `V1` and `V2` are applied automatically.

### Step 4: Access Swagger UI Documentation
Open your browser at:
👉 **http://localhost:8080/swagger-ui.html**

Key endpoints:
- `GET /api/stations`: List all regional stations.
- `GET /api/lines`: List all railway lines.
- `GET /api/bookings/{reference}`: Lookup booking by reference code.
- `GET /api/bookings/benchmark/naive`: Observe N+1 query issue.
- `GET /api/bookings/benchmark/optimized`: Observe single-query `JOIN FETCH` resolution.

---

## 3. Directory Layout
```text
Correspondances/
├── db/
│   ├── schema_v1.sql                    # Pure DDL script for MPD
│   ├── seed_data.sql                    # 520,000 bookings dataset generator
│   ├── queries.sql                      # 5 advanced queries + CTE recursive transfer
│   ├── cleanup_migration_scenario.sql   # Audited pre-migration cleanup
│   └── partitioning_benchmark.sql       # Native range partitioning benchmark
├── docs/
│   ├── MCD.png                          # Conceptual Data Model diagram
│   ├── MPD.png                          # Physical Data Model diagram
│   ├── data_model_justification.md      # Detailed model design & constraint justifications
│   └── performance_report.md            # EXPLAIN ANALYZE benchmarks, indexes, N+1 report
├── src/
│   ├── main/java/Correspondances/LaPlateforme/
│   │   ├── controller/RailwayController.java
│   │   ├── dto/BookingSummaryDto.java
│   │   ├── entity/ (Station, Line, Train, Car, Seat, Service, Booking)
│   │   └── repository/ (BookingRepository, StationRepository, LineRepository)
│   └── main/resources/
│       ├── application.properties
│       └── db/migration/
│           ├── V1__init_schema.sql
│           └── V2__price_history.sql
├── docker-compose.yml
├── pom.xml
└── README.md
```
