-- Database accounts. The API never connects as root.
-- Passwords are development-only test values; they must match docker-compose.yml.

-- Account used by the API. Grants are added per table/view/procedure once 01_schema.sql has tables,
-- following the least-privilege principle (no DDL, no GRANT OPTION). Justification: docs/permissions.md.
CREATE USER IF NOT EXISTS 'api_user_account'@'%' IDENTIFIED BY 'api_dev_password';

-- TODO (week 1): roles junior/mid/senior + users junior_user/mid_user/senior_user,
-- followed by SET DEFAULT ROLE ... TO ... (granted roles are inactive otherwise).
