# CLAUDE.md – FleetMaster (NHL Stenden, Data Processing INFB24V2DP, 2026-2027)

Group assignment (4 students). Build an API + relational database + client application for the
**FleetMaster** use case (fleet/transport-order platform). Graded with a scoring rubric.
Deadline: end of week 8. Scrum demos in weeks 2, 5 and 7.

## Grading rules that shape every decision

- **Hard requirements (otherwise grade 1.0):** approved framework, README with start instructions,
  and a Docker setup that automatically starts the API and the client, initialises the DB with
  test data, exposes the DB externally (DataGrip/DBeaver), and works with **zero extra configuration**.
- **Bold rubric criteria (otherwise max grade 5.0):** architecture + class diagram (≤10 errors),
  ERD in 3NF, Swagger documents every endpoint, all input validated, full CRUD, ≥1 external public
  API, correct HTTP methods, authentication + authorisation, project builds with ≥50% line coverage
  (target 70%), client uses only the API and its authentication, API uses its own DB account without
  root/sa rights, PKs and FKs, backup & recovery protocol.
- Weights: API categories 50% in total, DB integrity 10%, DB authorisation 5%, backup 5%, ERD 10%,
  client application only 5%. Put effort into DB + API; keep the client simple.

## Decisions (keep docs/decisions.md in sync)

| Topic | Decision |
|---|---|
| API | Java 21, Spring Boot 4.1.2 (Maven), REST |
| DB | MySQL 8.4 (pinned image `mysql:8.4`) |
| Data access | Hybrid: Spring Data JPA for operational tables (vehicles, maintenance, orders, route events); `JdbcTemplate` calling views/stored procedures for sensitive data (passwords, licences, invoices, discount activation) |
| Formats | JSON + XML via content negotiation (`Accept` / `Content-Type`), every CRUD operation in both |
| Auth | JWT via Spring Security OAuth2 Resource Server, stateless (`SessionCreationPolicy.STATELESS`) |
| Docs | springdoc-openapi 3.2.0 (Swagger UI at `/swagger-ui.html`) |
| Coverage | JaCoCo (`./mvnw verify` → `target/site/jacoco/index.html`) |
| Client | **Not decided yet**: web app (in its own container) or CLI tool. A desktop app must start without extra tooling. Phone apps are not allowed. |
| External API | **Not decided yet**: must need no API key (zero-config rule). Candidates: Nominatim (geocoding), OSRM (route duration), Open-Meteo (weather) |

Open question for the teacher: the assignment asks for OpenAPI 3.2, but springdoc generates 3.0/3.1.

## Repository layout

```
fleetmaster/
├── api/                 Spring Boot project (Dockerfile inside)
├── client/              web app or CLI
├── database/init/       run by MySQL on first start, in name order
│   01_schema.sql  02_roles_and_users.sql  03_views.sql
│   04_procedures.sql  05_triggers.sql  06_test_data.sql
├── docs/                decisions.md, backup-recovery.md, diagrams/
├── docker-compose.yml
├── README.md
├── .gitignore
└── .gitattributes       (*.sh and *.sql must be eol=lf)
```

## Hard rules – never break these

- `spring.jpa.hibernate.ddl-auto: none`. The schema comes **only** from `database/init/*.sql`.
  No Flyway/Liquibase, no Hibernate schema generation (the API account has no DDL rights).
- The API connects as `api_user_account`. Never root, never the `MYSQL_USER` from the image's
  env vars (the image gives that user ALL rights on the database). Create `api_user_account` in
  `02_roles_and_users.sql` with only the grants the API needs, and justify them in the docs.
- Passwords and financial data (licences, invoices, discounts) are only accessed through views or
  stored procedures, never through JPA entities on those tables.
- The client never talks to the database; everything goes through the API.
- Every query is scoped to the caller's company (multi-tenancy): no role may see or change another
  company's data.
- No secrets the examiner has to provide: dev passwords live in `docker-compose.yml` or a committed
  dev-only `.env`.
- Don't use Spring Data REST or the Spring Boot Docker Compose support module.

## MySQL notes

- Granted roles are inactive until `SET DEFAULT ROLE ... TO user` (or `activate_all_roles_on_login`).
- Init scripts only run on an empty data volume: reset with `docker compose down -v` (in README).
- In stored procedures: `SET TRANSACTION ISOLATION LEVEL ...` **before** `START TRANSACTION`.
- CHECK constraints are enforced (MySQL ≥ 8.0.16).
- Backup story: nightly `mysqldump` + binary logs for point-in-time recovery; document where backups
  are stored and for how long.

## Required database objects (from the use case)

- Views for internal roles: **junior** (company accounts, vehicles, simple order status),
  **mid** (limited operational changes, no financial data), **senior** (everything incl. licences,
  invoices, full route/vehicle history). Internal employees use the DBMS only, never the API.
- Trigger: inserting a route event of type ARRIVAL marks the transport order as completed.
- Stored procedure: activate the invitation discount for **both** companies in one transaction
  (justify the isolation level; a UNIQUE constraint ensures one discount per company).
- Constraints where the use case requires them, e.g. refrigerated loads need a refrigerated vehicle,
  licence limits on vehicles/drivers/orders, 3 failed logins → temporary block.
- Test data in every table covering every scenario (overdue invoice, blocked account, interrupted
  order, used invitation, trial period, etc.).

## App roles (API) vs DB roles

- App roles: company administrator (users, licence, invoices), planner (orders, assignments,
  vehicle data), driver (own orders + own route progress only), warehouse employee (orders and
  vehicles at own location, register loading/unloading).
- DB roles: junior, mid, senior, api_user_account.

## API conventions

- Prefix `/api/v1/`, plural nouns, no verbs in URLs. Non-CRUD actions as sub-resources or PATCH
  (e.g. `POST /api/v1/orders/{id}/route-events`, `PATCH /api/v1/orders/{id}` for cancel).
- Status codes: 201 + `Location` on create, 204 on delete, 400 validation, 401 vs 403 correctly,
  404, 409 conflicts. Never leak 500s or stack traces.
- One error-response format via `@ControllerAdvice`; pagination with `Pageable`.
- Every endpoint documented in Swagger, including error responses.
- Bean Validation (`@Valid`) on every request body and parameter.

## Current state (end of chat hand-off)

- `api/` generated with Spring Initializr and extended: springdoc, jackson-dataformat-xml
  (`tools.jackson.dataformat`, Jackson 3), JaCoCo, `application.yaml` with env-var DB settings,
  a starter `SecurityConfig` (stateless, Swagger public, rest 401), a two-stage Dockerfile.
- `./mvnw verify` passes (3 tests). Unauthenticated requests return 401 (`HttpStatusEntryPoint`).
- Root files done: `docker-compose.yml` (db/api/client, healthcheck, binlog on), `.gitignore`,
  `.gitattributes`, placeholder `client/` (nginx, port 3000), `database/init/01_schema.sql` (empty) and
  `02_roles_and_users.sql` (creates `api_user_account`, no grants yet). Verified: `docker compose up --build`
  starts everything, Swagger loads, `api_user_account` can log in from the host on port 3306.
- Not done yet: tables, DB roles/views/procedures/triggers/test data, ERD, real client, docs/.

## Week 1 goals

1. Cover page submitted (names, student numbers, languages, frameworks, use case, repo link).
2. docs/decisions.md written; ERD v1 in 3NF reviewed by the whole group.
3. Access matrices (app roles × resources, DB roles × tables/views/procedures) + draft endpoint list.
4. `docker compose up` on a fresh clone starts MySQL (port 3306 exposed), the API and a placeholder
   client; DataGrip connects; Swagger loads.
5. Scrum demo 1 slides prepared (week 2).

## Working agreements

- Coding conventions: NHL Stenden conventions (Blackboard). Tables/columns `snake_case`, Java `camelCase`.
- Branches `feature/<issue>-short-name`, merge to `main` via PR with one approval.
- Keep README, decisions.md and diagrams updated when changing the system: the class and
  architecture diagrams must match the delivered code.
