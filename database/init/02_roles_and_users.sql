-- Database accounts. The API never connects as root.
-- Passwords are development-only test values; they must match docker-compose.yml.

-- Account used by the API. Grants are added per table/view/procedure once 01_schema.sql has tables,
-- following the least-privilege principle (no DDL, no GRANT OPTION). Justification: docs/permissions.md.
CREATE USER IF NOT EXISTS 'api_user_account'@'%' IDENTIFIED BY 'api_dev_password';

-- Account used ONLY by Flyway at API startup to build and change the database structure.
-- ALL on fleetmaster.* = may create tables, views, procedures and triggers in THIS database only.
-- WITH GRANT OPTION = later migrations can give api_user_account its rights on views and procedures.
-- It has no global rights, so it cannot create users or touch other databases.
CREATE USER IF NOT EXISTS 'flyway_migrator'@'%' IDENTIFIED BY 'flyway_dev_password';
GRANT ALL PRIVILEGES ON fleetmaster.* TO 'flyway_migrator'@'%' WITH GRANT OPTION;