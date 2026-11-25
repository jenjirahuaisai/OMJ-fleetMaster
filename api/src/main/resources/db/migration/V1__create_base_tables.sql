-- V1: base tables from ERD v1 (3NF). Run by Flyway as flyway_migrator at API startup.

CREATE TABLE licence_level (
                               level_id           INT AUTO_INCREMENT PRIMARY KEY,
                               code               VARCHAR(20)   NOT NULL UNIQUE,
                               name               VARCHAR(50)   NOT NULL,
                               monthly_price      DECIMAL(10,2) NOT NULL CHECK (monthly_price >= 0),
                               max_vehicles       INT           NOT NULL CHECK (max_vehicles > 0),
                               max_drivers        INT           NOT NULL CHECK (max_drivers > 0),
                               max_active_orders  INT           NOT NULL CHECK (max_active_orders > 0)
);