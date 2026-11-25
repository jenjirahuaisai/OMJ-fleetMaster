-- V3: fixed reference rows the application relies on (not test data).

INSERT INTO app_role (code, description) VALUES
                                             ('COMPANY_ADMIN', 'Manages users, licence and invoices of the company'),
                                             ('PLANNER',       'Creates and assigns transport orders, manages vehicles'),
                                             ('DRIVER',        'Sees own orders and records route progress'),
                                             ('WAREHOUSE',     'Sees orders and vehicles at own location, registers loading');

INSERT INTO load_type (code, description) VALUES
                                              ('GENERAL',      'General cargo without special requirements'),
                                              ('PALLETS',      'Palletised goods'),
                                              ('REFRIGERATED', 'Chilled or frozen goods; needs a refrigerated vehicle'),
                                              ('BULK',         'Loose bulk goods');