# OMJ-fleetMaster

## FleetMaster

Data Processing final assignment, NHL Stenden 2026-2027.

| Member | Part |
|---|---|
| Michale O. Boateng | Accounts & Security (registration, login, JWT, roles) |
| Jenjira Huaisai | Fleet (vehicles, maintenance) + shared API rules |
| Herbert Dorothea | Orders & Routes + testing |
| Oleh Haliuk | Licences & Billing + database |

FleetMaster lets transport companies manage vehicles, drivers and transport orders.
Parts: **application** → **REST API** (Java 21, Spring Boot) → **MySQL 8.4 database**.

## Quick start

Requirements: Docker with Compose v2, and free ports **3307, 8081 and 3000**.

The host ports are deliberately not the defaults (3306 / 8080): the standard NHL Stenden
Docker environment already uses those, so FleetMaster can run next to it.

```bash
git clone git@github.com:jenjirahuaisai/OMJ-fleetMaster.git
cd OMJ-fleetMaster
docker compose up --build
```

Wait until the log shows `Started FleetmasterApiApplication`. The first build downloads
dependencies and takes a few minutes. Everything starts automatically, including the database
with test data.

| Service | URL |
|---|---|
| Application | http://localhost:3000 |
| API | http://localhost:8081/api/v1 |
| Swagger docs | http://localhost:8081/swagger-ui.html |
| MySQL (DataGrip / DBeaver) | `localhost:3307`, database `fleetmaster` |

Stop: `docker compose down`. Reset all data: `docker compose down -v`.

## Test accounts

Application (all passwords are test data):

| Role | Email | Password |
|---|---|---|
| Company administrator | <...> | <...> |
| Planner | <...> | <...> |
| Driver | <...> | <...> |
| Warehouse employee | <...> | <...> |

Database (DBeaver or DataGrip, host `localhost`, port `3307`):

| Account | Password | Role |
|---|---|---|
| `junior_user` | <...> | Junior: basic information only (companies, registered vehicles, simple order status) |
| `mid_user` | <...> | Mid-level: limited changes to operational data (e.g. vehicle status), no financial data |
| `senior_user` | <...> | Senior: all data, including licences, invoices and full history |
| `api_user_account` | `api_dev_password` | API: only the rights the API needs (DML on non-sensitive tables; sensitive data via views and procedures; no DDL, no root) |
| `flyway_migrator` | `flyway_dev_password` | Runs the Flyway migrations at API startup only (DDL rights on `fleetmaster`, nothing else) |
| `root` | `root_dev_password` | Administrator (setup only, never used by the API) |

## Demo of the full use case

1. Register a company and verify it (<where the email can be seen>).
2. Planner: add a vehicle (type, load capacity, load types, year) and a maintenance record; check the current maintenance status. Create an order.
3. Refrigerated order on a normal vehicle: expect a rejection.
4. Driver: record departure, stopover and arrival. The order becomes completed.
5. Administrator: view licence and invoices. An overdue invoice makes the account read-only.
6. Invitation: the invited company activates a paid licence. Both companies get the discount.

## Documentation

| Topic | File |
|---|---|
| Architecture diagram | `docs/architecture.png` |
| Class diagram | `docs/class-diagram.png` |
| ERD | `docs/erd.png` |
| Roles, rights and justification | `docs/permissions.md` |
| Transactions, views, procedures, triggers | `docs/integrity.md` |
| Backup and recovery | `docs/backup-recovery.md` |
| API conventions for the team | `docs/CONVENTIONS.md` |

## Tests

Requires JDK 21 (or run the tests inside Docker, see below).

```bash
cd api && ./mvnw verify      # macOS / Linux
cd api && mvnw.cmd verify    # Windows
```

Without a local JDK: `docker run --rm -v "$PWD/api:/app" -w /app eclipse-temurin:21-jdk sh ./mvnw verify`

Coverage report: `api/target/site/jacoco/index.html`

## Assumptions

- <assumption 1>
- <assumption 2>

## Troubleshooting

- **Port already in use:** another program uses 3307, 8081 or 3000. Stop it, or change the left
  (host) port in `docker-compose.yml`, e.g. `"3308:3306"`. Never change the right (container) port.
- **The API fails on first start:** the API waits for the MySQL health check, which can take up to
  a minute on first start (init scripts). If it still fails, run `docker compose restart api`.
- **Schema changes:** add a new Flyway migration in `api/src/main/resources/db/migration`, using
  your own number range: base V1–V99, Accounts V100–V199, Fleet V200–V299, Orders V300–V399,
  Licences & Billing V400–V499 (e.g. `V201__fleet_test_data.sql`). Never edit a migration that
  already ran: the API refuses to start with a checksum error. During development,
  `docker compose down -v` resets the database completely.
- **Database accounts** are created by `database/init/02_roles_and_users.sql`, which only runs on
  an empty volume. After changing it, run `docker compose down -v`.
- **DataGrip shows other tables:** you are probably connected to port 3306 (another MySQL/MariaDB,
  e.g. the NHL Stenden environment). FleetMaster's database is on port **3307**.