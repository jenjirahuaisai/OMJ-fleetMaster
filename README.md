# OMJ-fleetMaster

# FleetMaster

Data Processing final assignment, NHL Stenden 2026-2027.
Group: Michael O. Boateng
       Jenira huaisai
       Oleh 

FleetMaster lets transport companies manage vehicles, drivers and transport orders.
Parts: **application** → **REST API** (Java, Spring Boot) → **MySQL database**.

## Quick start

Requirements: Docker with Compose v2, and free ports 3306, 8080 and <app port>.

```bash
git clone < git@github.com:jenjirahuaisai/OMJ-fleetMaster.git>
cd fleetmaster
docker compose up --build
```

Wait until the log shows `<ready message>`. Everything starts automatically, including the database with test data.

| Service | URL |
|---|---|
| Application | http://localhost:<app port> |
| API | http://localhost:8080/api/v1 |
| Swagger docs | http://localhost:8080/swagger-ui.html |
| MySQL | localhost:3306, database `fleetmaster` |

Stop: `docker compose down`. Reset all data: `docker compose down -v`.

## Test accounts

Application (all passwords are test data):

| Role | Email | Password |
|---|---|---|
| Company administrator | <...> | <...> |
| Planner | <...> | <...> |
| Driver | <...> | <...> |
| Warehouse employee | <...> | <...> |

Database (DBeaver or DataGrip):

| Account | Password | Role |
|---|---|---|
| `junior_user` | <...> | Junior |
| `mid_user` | <...> | Mid-level |
| `senior_user` | <...> | Senior |
| `API_user_account` | <...> | API (views and procedures only) |

## Demo of the full use case

1. Register a company and verify it (<where the email can be seen>).
2. Planner: add a vehicle and a maintenance record, create an order.
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

## Tests

```bash
cd api && ./mvnw verify
```

Coverage report: `api/target/site/jacoco/index.html`

## Assumptions

- <assumption 1>
- <assumption 2>

## Troubleshooting

- Port already in use: change it in `docker-compose.yml`.
- The API fails on first start: MySQL needs about <n> seconds. Wait, or run `docker compose restart api`.
