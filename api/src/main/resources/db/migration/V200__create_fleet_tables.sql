-- V200: Fleet tables (Member 2). Run by Flyway as flyway_migrator.

-- ---------- 1. Missing load type ----------
-- The use case names normal, refrigerated and hazardous loads. V3 has no HAZARDOUS yet.

INSERT INTO load_type (code, description)
VALUES ('HAZARDOUS', 'Dangerous goods (ADR); needs a vehicle approved for hazardous loads');

-- ---------- 2. Vehicle types (lookup) ----------
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
