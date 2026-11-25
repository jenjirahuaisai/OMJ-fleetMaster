-- V2: shared base tables from ERD v1 (3NF). Run by Flyway as flyway_migrator.
-- Every member's own tables (V100+, V200+, V300+, V400+) reference these.
-- Order matters: a table can only reference tables created above it.

-- ---------- Lookup / independent tables ----------

CREATE TABLE company (
                         company_id     INT AUTO_INCREMENT PRIMARY KEY,
                         name           VARCHAR(100) NOT NULL,
                         contact_email  VARCHAR(255) NOT NULL,
                         registered_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
                         status         VARCHAR(30)  NOT NULL DEFAULT 'PENDING_VERIFICATION',
                         CONSTRAINT chk_company_status
                             CHECK (status IN ('PENDING_VERIFICATION', 'ACTIVE', 'DEACTIVATED'))
);

CREATE TABLE app_role (
                          role_id      INT AUTO_INCREMENT PRIMARY KEY,
                          code         VARCHAR(30)  NOT NULL UNIQUE,   -- COMPANY_ADMIN, PLANNER, DRIVER, WAREHOUSE
                          description  VARCHAR(255) NOT NULL
);

-- Shared by locations and transport orders (pickup/delivery), so addresses are not repeated.
CREATE TABLE address (
                         address_id    INT AUTO_INCREMENT PRIMARY KEY,
                         street        VARCHAR(100) NOT NULL,
                         house_number  VARCHAR(10)  NOT NULL,          -- '12a', '7-II'
                         postal_code   VARCHAR(10)  NOT NULL,          -- '9701 AB'
                         city          VARCHAR(100) NOT NULL,
                         country_code  CHAR(2)      NOT NULL,          -- ISO 3166: NL, DE, BE
                         latitude      DECIMAL(9,6) NULL,              -- filled later by geocoding (external API)
                         longitude     DECIMAL(9,6) NULL,
                         CONSTRAINT chk_address_latitude  CHECK (latitude  BETWEEN -90  AND 90),
                         CONSTRAINT chk_address_longitude CHECK (longitude BETWEEN -180 AND 180)
);

CREATE TABLE load_type (
                           load_type_id  INT AUTO_INCREMENT PRIMARY KEY,
                           code          VARCHAR(30)  NOT NULL UNIQUE,   -- GENERAL, REFRIGERATED, ...
                           description   VARCHAR(255) NOT NULL
);

-- ---------- Tables with foreign keys ----------

-- Home bases and warehouses of a company.
CREATE TABLE location (
                          location_id  INT AUTO_INCREMENT PRIMARY KEY,
                          name         VARCHAR(100) NOT NULL,
                          company_id   INT NOT NULL,
                          address_id   INT NOT NULL,
                          CONSTRAINT uq_location_company_name UNIQUE (company_id, name),
                          CONSTRAINT fk_location_company FOREIGN KEY (company_id)
                              REFERENCES company (company_id) ON DELETE RESTRICT,
                          CONSTRAINT fk_location_address FOREIGN KEY (address_id)
                              REFERENCES address (address_id) ON DELETE RESTRICT
);

CREATE TABLE user_account (
                              user_id        INT AUTO_INCREMENT PRIMARY KEY,
                              email          VARCHAR(255) NOT NULL UNIQUE,   -- login name, unique across all companies
                              password_hash  VARCHAR(255) NOT NULL,          -- BCrypt hash, never the password itself
                              full_name      VARCHAR(100) NOT NULL,
                              status         VARCHAR(30)  NOT NULL DEFAULT 'PENDING_VERIFICATION',
                              activated_at   DATETIME     NULL,              -- set when the email is verified
                              blocked_until  DATETIME     NULL,              -- set after 3 failed logins
                              created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
                              company_id     INT NOT NULL,
                              role_id        INT NOT NULL,
                              location_id    INT NULL,                       -- only for users tied to one place (e.g. warehouse)
                              CONSTRAINT chk_user_status
                                  CHECK (status IN ('PENDING_VERIFICATION', 'ACTIVE', 'DEACTIVATED')),
                              CONSTRAINT fk_user_company FOREIGN KEY (company_id)
                                  REFERENCES company (company_id) ON DELETE RESTRICT,
                              CONSTRAINT fk_user_role FOREIGN KEY (role_id)
                                  REFERENCES app_role (role_id) ON DELETE RESTRICT,
                              CONSTRAINT fk_user_location FOREIGN KEY (location_id)
                                  REFERENCES location (location_id) ON DELETE SET NULL
);