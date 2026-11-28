-- V200: Fleet tables (Member 2). Run by Flyway as flyway_migrator.
-- Order matters: a table can only reference tables created above it,
-- and the view must exist before it gets a GRANT.

-- ---------- 1. Missing load type ----------
-- The use case names normal, refrigerated and hazardous loads. V3 has no HAZARDOUS yet.
INSERT INTO load_type (code, description)
VALUES ('HAZARDOUS', 'Dangerous goods (ADR); needs a vehicle approved for hazardous loads');

-- ---------- 2. Vehicle types (lookup) ----------
-- Use case: "lorries, vans or refrigerated trucks".
-- has_refrigeration lets planners filter on "refrigeration system" and lets the API
-- check that refrigerated goods get a refrigerated vehicle.
CREATE TABLE vehicle_type
(
    vehicle_type_id   INT AUTO_INCREMENT PRIMARY KEY,
    code              VARCHAR(30)  NOT NULL UNIQUE,
    description       VARCHAR(255) NOT NULL,
    has_refrigeration BOOLEAN      NOT NULL DEFAULT FALSE
);

INSERT INTO vehicle_type (code, description, has_refrigeration)
VALUES ('LORRY', 'Heavy goods vehicle', FALSE),
       ('VAN', 'Light delivery van', FALSE),
       ('REFRIGERATED_TRUCK', 'Truck with a refrigeration unit', TRUE);

-- ---------- 3. Vehicles ----------
-- A lorry, van or refrigerated truck of one company.
-- status = operational status (AVAILABLE, IN_USE, IN_MAINTENANCE, OUT_OF_SERVICE),
--          changed by planners and mid-level employees ("adjusting vehicle status").
--          It is NOT the maintenance status: that is derived from maintenance (see 5b).
CREATE TABLE vehicle
(
    vehicle_id          INT AUTO_INCREMENT PRIMARY KEY,
    licence_plate       VARCHAR(15) NOT NULL UNIQUE,
    load_capacity_kg    INT         NOT NULL,
    year_of_manufacture INT         NOT NULL,
    status              VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE',
    company_id          INT         NOT NULL,
    vehicle_type_id     INT         NOT NULL,
    home_location_id    INT         NULL, -- warehouse employees see vehicles at their own location
    CONSTRAINT chk_vehicle_capacity CHECK (load_capacity_kg > 0),
    CONSTRAINT chk_vehicle_year CHECK (year_of_manufacture BETWEEN 1950 AND 2100),
    CONSTRAINT chk_vehicle_status
        CHECK (status IN ('AVAILABLE', 'IN_USE', 'IN_MAINTENANCE', 'OUT_OF_SERVICE')),
    CONSTRAINT fk_vehicle_company FOREIGN KEY (company_id)
        REFERENCES company (company_id) ON DELETE RESTRICT,
    CONSTRAINT fk_vehicle_type FOREIGN KEY (vehicle_type_id)
        REFERENCES vehicle_type (vehicle_type_id) ON DELETE RESTRICT,
    CONSTRAINT fk_vehicle_location FOREIGN KEY (home_location_id)
        REFERENCES location (location_id) ON DELETE SET NULL
);

-- ---------- 4. Which load types a vehicle is suitable for (many-to-many) ----------
-- Use case: "Not every vehicle is suitable for every type of load: for example,
-- refrigerated goods require a refrigerated vehicle."
-- A vehicle can carry several load types and a load type fits several vehicles,
-- so this junction table resolves the many-to-many between vehicle and load_type.
-- Constraint prefix "vlt" = vehicle_load_type (MySQL names are max 64 characters).
CREATE TABLE vehicle_load_type
(
    vehicle_id   INT NOT NULL,
    load_type_id INT NOT NULL,
    PRIMARY KEY (vehicle_id, load_type_id),
    CONSTRAINT fk_vlt_vehicle FOREIGN KEY (vehicle_id)
        REFERENCES vehicle (vehicle_id) ON DELETE CASCADE,
    CONSTRAINT fk_vlt_load_type FOREIGN KEY (load_type_id)
        REFERENCES load_type (load_type_id) ON DELETE RESTRICT
);

-- ---------- 5a. Maintenance types (lookup) ----------
-- Kind of maintenance, e.g. PERIODIC, REPAIR or MOT.
CREATE TABLE maintenance_type
(
    maintenance_type_id INT AUTO_INCREMENT PRIMARY KEY,
    code                VARCHAR(30)  NOT NULL UNIQUE,
    description         VARCHAR(255) NOT NULL
);

INSERT INTO maintenance_type (code, description)
VALUES ('PERIODIC', 'Scheduled periodic service'),
       ('REPAIR', 'Repair after a defect or damage'),
       ('MOT', 'Mandatory roadworthiness inspection (APK)');

-- ---------- 5b. Maintenance history ----------
-- One row = one maintenance of one vehicle (date, type and result).
-- Use case: "every maintenance is recorded with its date, type and result, so that
-- the current maintenance status and the full maintenance history can be consulted."
--
--   Full history   = all rows of a vehicle in this table.
--   Current status = the latest row of that vehicle (newest performed_on).
--
-- Design decision (3NF): the current maintenance status is DERIVED from this table,
-- never stored separately in vehicle. Storing it twice would:
--   1. break 3NF (it is a calculated value, so it would be redundant data), and
--   2. risk inconsistent data (a new maintenance row is added, but the copy in
--      vehicle is not updated).
-- The view v_vehicle_maintenance_status (section 6) calculates it instead.
CREATE TABLE maintenance
(
    maintenance_id      INT AUTO_INCREMENT PRIMARY KEY,
    vehicle_id          INT          NOT NULL,
    maintenance_type_id INT          NOT NULL,
    performed_on        DATE         NOT NULL,
    result              VARCHAR(20)  NOT NULL,
    notes               VARCHAR(500) NULL,
    INDEX idx_maintenance_vehicle_date (vehicle_id, performed_on), -- fast "latest maintenance per vehicle" (used by the view)
    CONSTRAINT chk_maintenance_result
        CHECK (result IN ('PASSED', 'FAILED', 'REPAIRED')),
    CONSTRAINT fk_maintenance_vehicle FOREIGN KEY (vehicle_id)
        REFERENCES vehicle (vehicle_id) ON DELETE CASCADE,
    CONSTRAINT fk_maintenance_type FOREIGN KEY (maintenance_type_id)
        REFERENCES maintenance_type (maintenance_type_id) ON DELETE RESTRICT
);

-- ---------- 6. Current maintenance status per vehicle (view) ----------
-- Use case: "the current maintenance status and the full maintenance history can be consulted."
-- Current status = the latest maintenance of each vehicle (newest performed_on; the highest
-- maintenance_id breaks ties on the same day). Vehicles without maintenance are included
-- with NULLs (LEFT JOIN). Derived, never stored, so the model stays in 3NF.
-- Used by the API and by the internal roles (junior / mid-level / senior).
CREATE VIEW v_vehicle_maintenance_status AS
SELECT v.vehicle_id,
       v.company_id,
       v.licence_plate,
       vt.code        AS vehicle_type,
       v.status       AS vehicle_status,
       m.performed_on AS last_maintenance_on,
       mt.code        AS last_maintenance_type,
       m.result       AS last_maintenance_result
FROM vehicle v
         JOIN vehicle_type vt ON vt.vehicle_type_id = v.vehicle_type_id
         LEFT JOIN maintenance m ON m.maintenance_id = (SELECT m2.maintenance_id
                                                        FROM maintenance m2
                                                        WHERE m2.vehicle_id = v.vehicle_id
                                                        ORDER BY m2.performed_on DESC, m2.maintenance_id DESC
        LIMIT 1)
        LEFT JOIN maintenance_type mt ON mt.maintenance_type_id = m.maintenance_type_id;

-- ---------- 7. Rights for the API account (least privilege) ----------
-- Use case: "The API_user_account has only the rights the API needs" and
-- "never has DDL, root/sa or other administrative rights."
-- Fleet data is not sensitive (no passwords or financial data), so the API may use
-- these tables directly via JPA (ORM). Lookup tables and the view are read-only for the API.
-- No CREATE / ALTER / DROP: the structure is only changed by Flyway (flyway_migrator).
-- Justification: docs/permissions.md
GRANT SELECT, INSERT, UPDATE, DELETE ON fleetmaster.vehicle TO 'api_user_account'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON fleetmaster.vehicle_load_type TO 'api_user_account'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON fleetmaster.maintenance TO 'api_user_account'@'%';
GRANT SELECT ON fleetmaster.vehicle_type TO 'api_user_account'@'%';
GRANT SELECT ON fleetmaster.maintenance_type TO 'api_user_account'@'%';
GRANT SELECT ON fleetmaster.load_type TO 'api_user_account'@'%';
GRANT SELECT ON fleetmaster.v_vehicle_maintenance_status TO 'api_user_account'@'%';