-- =============================================================================
-- KuboBank — Seed Data
-- Compatible with: PostgreSQL 15+
-- Managed by: Liquibase
-- Depends on: DATA_MODEL.sql
-- Version: 2.0.0
-- =============================================================================
-- ⚠️  FOR DEVELOPMENT / TESTING ONLY — DO NOT RUN IN PRODUCTION
-- =============================================================================


-- =============================================================================
-- SHARED — Currencies
-- =============================================================================

INSERT INTO currencies (code, type, decimals, symbol, active) VALUES
    ('USD', 'FIAT_FOREIGN', 2, '$',  TRUE),
    ('SVC', 'FIAT_LOCAL',   2, '₡',  TRUE),
    ('BTC', 'CRYPTO',       8, '₿',  TRUE),
    ('GTQ', 'FIAT_LOCAL',   2, 'Q',  FALSE),
    ('HNL', 'FIAT_LOCAL',   2, 'L',  FALSE);


-- =============================================================================
-- SHARED — Jurisdictions
-- =============================================================================

INSERT INTO jurisdictions (country_code, name) VALUES
    ('SV', 'El Salvador'),
    ('GT', 'Guatemala'),
    ('HN', 'Honduras');


-- =============================================================================
-- SHARED — Jurisdiction Currencies
-- =============================================================================

INSERT INTO jurisdiction_currencies (country_code, currency_code) VALUES
    ('SV', 'USD'), ('SV', 'SVC'), ('SV', 'BTC'),
    ('GT', 'GTQ'),
    ('HN', 'HNL');


-- =============================================================================
-- LEDGER — Chart of Accounts (Plan de Cuentas MVP)
-- One account per currency where applicable.
-- =============================================================================

INSERT INTO chart_of_accounts (code, name, category, currency_code, active) VALUES
    -- ASSET: Caja y Efectivo
    ('1100-USD', 'Caja y Efectivo USD',             'ASSET',     'USD', TRUE),
    ('1100-SVC', 'Caja y Efectivo SVC',             'ASSET',     'SVC', TRUE),
    ('1100-BTC', 'Caja y Efectivo BTC',             'ASSET',     'BTC', TRUE),
    -- LIABILITY: Depósitos de Clientes
    ('2100-USD', 'Depósitos de Clientes USD',       'LIABILITY', 'USD', TRUE),
    ('2100-SVC', 'Depósitos de Clientes SVC',       'LIABILITY', 'SVC', TRUE),
    ('2100-BTC', 'Depósitos de Clientes BTC',       'LIABILITY', 'BTC', TRUE),
    -- EQUITY
    ('3100-USD', 'Capital Social',                  'EQUITY',    'USD', TRUE),
    -- INCOME
    ('4100-USD', 'Comisiones por Transferencia',    'INCOME',    'USD', TRUE),
    ('4200-USD', 'Comisiones por Cambio FX',        'INCOME',    'USD', TRUE),
    -- EXPENSE
    ('5100-USD', 'Gastos Operativos',               'EXPENSE',   'USD', TRUE),
    ('5200-USD', 'Pérdidas por Reversiones',        'EXPENSE',   'USD', TRUE);


-- =============================================================================
-- IDENTITY — Customers
-- =============================================================================

INSERT INTO customers (customer_id, full_name, email, phone_country_code, phone_number, status, created_at, updated_at) VALUES
    ('a0000001-0000-0000-0000-000000000001', 'Rafael Mendoza',  'rafael.mendoza@kubobank.sv',  '+503', '70001001', 'ACTIVE',    NOW() - INTERVAL '30 days', NOW() - INTERVAL '29 days'),
    ('a0000001-0000-0000-0000-000000000002', 'Valentina Torres','valentina.torres@kubobank.sv','+503', '70001002', 'ACTIVE',    NOW() - INTERVAL '25 days', NOW() - INTERVAL '24 days'),
    ('a0000001-0000-0000-0000-000000000003', 'Diego Alfaro',    'diego.alfaro@kubobank.sv',    '+503', '70001003', 'PENDING',   NOW() - INTERVAL '2 days',  NOW() - INTERVAL '2 days'),
    ('a0000001-0000-0000-0000-000000000004', 'Lucia Herrera',   'lucia.herrera@kubobank.sv',   '+503', '70001004', 'SUSPENDED', NOW() - INTERVAL '60 days', NOW() - INTERVAL '5 days');


-- =============================================================================
-- ACCOUNT — Accounts
-- =============================================================================

INSERT INTO accounts (account_id, customer_id, account_number, type, country_code, status, created_at, updated_at) VALUES
    ('b0000002-0000-0000-0000-000000000001', 'a0000001-0000-0000-0000-000000000001', 'SV-00100001', 'SAVINGS',  'SV', 'ACTIVE', NOW() - INTERVAL '29 days', NOW() - INTERVAL '1 day'),
    ('b0000002-0000-0000-0000-000000000002', 'a0000001-0000-0000-0000-000000000001', 'SV-00100002', 'CHECKING', 'SV', 'ACTIVE', NOW() - INTERVAL '28 days', NOW() - INTERVAL '1 day'),
    ('b0000002-0000-0000-0000-000000000003', 'a0000001-0000-0000-0000-000000000002', 'SV-00200001', 'SAVINGS',  'SV', 'ACTIVE', NOW() - INTERVAL '24 days', NOW() - INTERVAL '2 days'),
    ('b0000002-0000-0000-0000-000000000004', 'a0000001-0000-0000-0000-000000000004', 'SV-00400001', 'SAVINGS',  'SV', 'FROZEN', NOW() - INTERVAL '55 days', NOW() - INTERVAL '5 days');


-- =============================================================================
-- ACCOUNT — Account Balances (final state after all seed transactions)
-- Rafael SAVINGS:   USD 2,350.00 | BTC 0.00450000 | SVC 500.00
-- Rafael CHECKING:  USD 800.00
-- Valentina SAVINGS: USD 1,500.00 | SVC 200.00
-- Lucia SAVINGS:    USD 300.00 (frozen)
-- =============================================================================

INSERT INTO account_balances (account_id, currency_code, amount) VALUES
    ('b0000002-0000-0000-0000-000000000001', 'USD', 2350.00000000),
    ('b0000002-0000-0000-0000-000000000001', 'BTC', 0.00450000),
    ('b0000002-0000-0000-0000-000000000001', 'SVC', 500.00000000),
    ('b0000002-0000-0000-0000-000000000002', 'USD', 800.00000000),
    ('b0000002-0000-0000-0000-000000000003', 'USD', 1500.00000000),
    ('b0000002-0000-0000-0000-000000000003', 'SVC', 200.00000000),
    ('b0000002-0000-0000-0000-000000000004', 'USD', 300.00000000);


-- =============================================================================
-- LEDGER — Journal Entries + Lines
-- One entry per completed transaction. Partida doble enforced.
-- =============================================================================

-- JE-001: DEPOSIT $3000 USD → Rafael SAVINGS
INSERT INTO journal_entries (journal_entry_id, transaction_id, entry_type, description, created_by, occurred_at) VALUES
    ('e0000005-0000-0000-0000-000000000001', 'c0000003-0000-0000-0000-000000000001', 'AUTOMATIC', 'DEPOSIT $3000 USD — Rafael SAVINGS', 'system', NOW() - INTERVAL '28 days');
INSERT INTO journal_entry_lines (journal_entry_id, account_code, side, amount, currency_code, bank_account_id) VALUES
    ('e0000005-0000-0000-0000-000000000001', '1100-USD', 'DEBIT',  3000.00, 'USD', NULL),
    ('e0000005-0000-0000-0000-000000000001', '2100-USD', 'CREDIT', 3000.00, 'USD', 'b0000002-0000-0000-0000-000000000001');

-- JE-002: DEPOSIT $500 SVC → Rafael SAVINGS
INSERT INTO journal_entries (journal_entry_id, transaction_id, entry_type, description, created_by, occurred_at) VALUES
    ('e0000005-0000-0000-0000-000000000002', 'c0000003-0000-0000-0000-000000000002', 'AUTOMATIC', 'DEPOSIT $500 SVC — Rafael SAVINGS', 'system', NOW() - INTERVAL '27 days');
INSERT INTO journal_entry_lines (journal_entry_id, account_code, side, amount, currency_code, bank_account_id) VALUES
    ('e0000005-0000-0000-0000-000000000002', '1100-SVC', 'DEBIT',  500.00, 'SVC', NULL),
    ('e0000005-0000-0000-0000-000000000002', '2100-SVC', 'CREDIT', 500.00, 'SVC', 'b0000002-0000-0000-0000-000000000001');

-- JE-003: DEPOSIT $1000 USD → Rafael CHECKING
INSERT INTO journal_entries (journal_entry_id, transaction_id, entry_type, description, created_by, occurred_at) VALUES
    ('e0000005-0000-0000-0000-000000000003', 'c0000003-0000-0000-0000-000000000003', 'AUTOMATIC', 'DEPOSIT $1000 USD — Rafael CHECKING', 'system', NOW() - INTERVAL '27 days');
INSERT INTO journal_entry_lines (journal_entry_id, account_code, side, amount, currency_code, bank_account_id) VALUES
    ('e0000005-0000-0000-0000-000000000003', '1100-USD', 'DEBIT',  1000.00, 'USD', NULL),
    ('e0000005-0000-0000-0000-000000000003', '2100-USD', 'CREDIT', 1000.00, 'USD', 'b0000002-0000-0000-0000-000000000002');

-- JE-004: DEPOSIT $2000 USD → Valentina SAVINGS
INSERT INTO journal_entries (journal_entry_id, transaction_id, entry_type, description, created_by, occurred_at) VALUES
    ('e0000005-0000-0000-0000-000000000004', 'c0000003-0000-0000-0000-000000000004', 'AUTOMATIC', 'DEPOSIT $2000 USD — Valentina SAVINGS', 'system', NOW() - INTERVAL '23 days');
INSERT INTO journal_entry_lines (journal_entry_id, account_code, side, amount, currency_code, bank_account_id) VALUES
    ('e0000005-0000-0000-0000-000000000004', '1100-USD', 'DEBIT',  2000.00, 'USD', NULL),
    ('e0000005-0000-0000-0000-000000000004', '2100-USD', 'CREDIT', 2000.00, 'USD', 'b0000002-0000-0000-0000-000000000003');

-- JE-005: DEPOSIT $200 SVC → Valentina SAVINGS
INSERT INTO journal_entries (journal_entry_id, transaction_id, entry_type, description, created_by, occurred_at) VALUES
    ('e0000005-0000-0000-0000-000000000005', 'c0000003-0000-0000-0000-000000000005', 'AUTOMATIC', 'DEPOSIT $200 SVC — Valentina SAVINGS', 'system', NOW() - INTERVAL '22 days');
INSERT INTO journal_entry_lines (journal_entry_id, account_code, side, amount, currency_code, bank_account_id) VALUES
    ('e0000005-0000-0000-0000-000000000005', '1100-SVC', 'DEBIT',  200.00, 'SVC', NULL),
    ('e0000005-0000-0000-0000-000000000005', '2100-SVC', 'CREDIT', 200.00, 'SVC', 'b0000002-0000-0000-0000-000000000003');

-- JE-006: DEPOSIT $300 USD → Lucia SAVINGS
INSERT INTO journal_entries (journal_entry_id, transaction_id, entry_type, description, created_by, occurred_at) VALUES
    ('e0000005-0000-0000-0000-000000000006', 'c0000003-0000-0000-0000-000000000006', 'AUTOMATIC', 'DEPOSIT $300 USD — Lucia SAVINGS', 'system', NOW() - INTERVAL '50 days');
INSERT INTO journal_entry_lines (journal_entry_id, account_code, side, amount, currency_code, bank_account_id) VALUES
    ('e0000005-0000-0000-0000-000000000006', '1100-USD', 'DEBIT',  300.00, 'USD', NULL),
    ('e0000005-0000-0000-0000-000000000006', '2100-USD', 'CREDIT', 300.00, 'USD', 'b0000002-0000-0000-0000-000000000004');

-- JE-007: WITHDRAWAL $200 USD — Rafael CHECKING
INSERT INTO journal_entries (journal_entry_id, transaction_id, entry_type, description, created_by, occurred_at) VALUES
    ('e0000005-0000-0000-0000-000000000007', 'c0000003-0000-0000-0000-000000000007', 'AUTOMATIC', 'WITHDRAWAL $200 USD — Rafael CHECKING', 'system', NOW() - INTERVAL '18 days');
INSERT INTO journal_entry_lines (journal_entry_id, account_code, side, amount, currency_code, bank_account_id) VALUES
    ('e0000005-0000-0000-0000-000000000007', '2100-USD', 'DEBIT',  200.00, 'USD', 'b0000002-0000-0000-0000-000000000002'),
    ('e0000005-0000-0000-0000-000000000007', '1100-USD', 'CREDIT', 200.00, 'USD', NULL);

-- JE-008: TRANSFER $150 USD Rafael SAVINGS → Valentina SAVINGS
INSERT INTO journal_entries (journal_entry_id, transaction_id, entry_type, description, created_by, occurred_at) VALUES
    ('e0000005-0000-0000-0000-000000000008', 'c0000003-0000-0000-0000-000000000008', 'AUTOMATIC', 'TRANSFER $150 USD Rafael → Valentina', 'system', NOW() - INTERVAL '15 days');
INSERT INTO journal_entry_lines (journal_entry_id, account_code, side, amount, currency_code, bank_account_id) VALUES
    ('e0000005-0000-0000-0000-000000000008', '2100-USD', 'DEBIT',  150.00, 'USD', 'b0000002-0000-0000-0000-000000000001'),
    ('e0000005-0000-0000-0000-000000000008', '2100-USD', 'CREDIT', 150.00, 'USD', 'b0000002-0000-0000-0000-000000000003');

-- JE-009: TRANSFER $500 USD Valentina → Rafael SAVINGS
INSERT INTO journal_entries (journal_entry_id, transaction_id, entry_type, description, created_by, occurred_at) VALUES
    ('e0000005-0000-0000-0000-000000000009', 'c0000003-0000-0000-0000-000000000009', 'AUTOMATIC', 'TRANSFER $500 USD Valentina → Rafael', 'system', NOW() - INTERVAL '14 days');
INSERT INTO journal_entry_lines (journal_entry_id, account_code, side, amount, currency_code, bank_account_id) VALUES
    ('e0000005-0000-0000-0000-000000000009', '2100-USD', 'DEBIT',  500.00, 'USD', 'b0000002-0000-0000-0000-000000000003'),
    ('e0000005-0000-0000-0000-000000000009', '2100-USD', 'CREDIT', 500.00, 'USD', 'b0000002-0000-0000-0000-000000000001');

-- JE-010: TRANSFER cross-currency $310 USD → ₿0.005 BTC (Rafael SAVINGS)
INSERT INTO journal_entries (journal_entry_id, transaction_id, entry_type, description, created_by, occurred_at) VALUES
    ('e0000005-0000-0000-0000-000000000010', 'c0000003-0000-0000-0000-000000000010', 'AUTOMATIC', 'CROSS-CURRENCY $310 USD → ₿0.005 BTC — Rafael', 'system', NOW() - INTERVAL '13 days');
INSERT INTO journal_entry_lines (journal_entry_id, account_code, side, amount, currency_code, bank_account_id) VALUES
    ('e0000005-0000-0000-0000-000000000010', '2100-USD', 'DEBIT',  310.00000000, 'USD', 'b0000002-0000-0000-0000-000000000001'),
    ('e0000005-0000-0000-0000-000000000010', '2100-BTC', 'CREDIT', 0.00500000,   'BTC', 'b0000002-0000-0000-0000-000000000001');

-- JE-011: TRANSFER cross-currency ₿0.0005 BTC → $30.56 USD (Rafael SAVINGS)
INSERT INTO journal_entries (journal_entry_id, transaction_id, entry_type, description, created_by, occurred_at) VALUES
    ('e0000005-0000-0000-0000-000000000011', 'c0000003-0000-0000-0000-000000000011', 'AUTOMATIC', 'CROSS-CURRENCY ₿0.0005 BTC → $30.56 USD — Rafael', 'system', NOW() - INTERVAL '12 days');
INSERT INTO journal_entry_lines (journal_entry_id, account_code, side, amount, currency_code, bank_account_id) VALUES
    ('e0000005-0000-0000-0000-000000000011', '2100-BTC', 'DEBIT',  0.00050000, 'BTC', 'b0000002-0000-0000-0000-000000000001'),
    ('e0000005-0000-0000-0000-000000000011', '2100-USD', 'CREDIT', 30.56,      'USD', 'b0000002-0000-0000-0000-000000000001');

-- JE-012: REVERSAL of TRF-SV-20250117-001 — erroneous transfer (MANUAL by ADMIN)
INSERT INTO journal_entries (journal_entry_id, transaction_id, entry_type, description, created_by, occurred_at) VALUES
    ('e0000005-0000-0000-0000-000000000012', 'c0000003-0000-0000-0000-000000000013', 'AUTOMATIC', 'REVERSAL of erroneous TRANSFER $100 USD Rafael → Valentina', 'system', NOW() - INTERVAL '10 days');
INSERT INTO journal_entry_lines (journal_entry_id, account_code, side, amount, currency_code, bank_account_id) VALUES
    ('e0000005-0000-0000-0000-000000000012', '2100-USD', 'DEBIT',  100.00, 'USD', 'b0000002-0000-0000-0000-000000000003'),
    ('e0000005-0000-0000-0000-000000000012', '2100-USD', 'CREDIT', 100.00, 'USD', 'b0000002-0000-0000-0000-000000000001');

-- JE-013: WITHDRAWAL $690 USD — Rafael SAVINGS
INSERT INTO journal_entries (journal_entry_id, transaction_id, entry_type, description, created_by, occurred_at) VALUES
    ('e0000005-0000-0000-0000-000000000013', 'c0000003-0000-0000-0000-000000000015', 'AUTOMATIC', 'WITHDRAWAL $690 USD — Rafael SAVINGS', 'system', NOW() - INTERVAL '9 days');
INSERT INTO journal_entry_lines (journal_entry_id, account_code, side, amount, currency_code, bank_account_id) VALUES
    ('e0000005-0000-0000-0000-000000000013', '2100-USD', 'DEBIT',  690.00, 'USD', 'b0000002-0000-0000-0000-000000000001'),
    ('e0000005-0000-0000-0000-000000000013', '1100-USD', 'CREDIT', 690.00, 'USD', NULL);

-- JE-014: MANUAL adjustment — Capital Social inicial
INSERT INTO journal_entries (journal_entry_id, transaction_id, entry_type, description, created_by, occurred_at) VALUES
    ('e0000005-0000-0000-0000-000000000014', NULL, 'MANUAL', 'Capital Social inicial — Kubo Bank MVP', 'auth0|admin001', NOW() - INTERVAL '60 days');
INSERT INTO journal_entry_lines (journal_entry_id, account_code, side, amount, currency_code, bank_account_id) VALUES
    ('e0000005-0000-0000-0000-000000000014', '1100-USD', 'DEBIT',  50000.00, 'USD', NULL),
    ('e0000005-0000-0000-0000-000000000014', '3100-USD', 'CREDIT', 50000.00, 'USD', NULL);


-- =============================================================================
-- TRANSACTION — Transactions
-- journal_entry_id linked to completed transactions.
-- FAILED and PENDING transactions have no journal entry.
-- =============================================================================

INSERT INTO transactions (
    transaction_id, origin_account_id, destination_account_id,
    amount, amount_currency_code,
    converted_amount, converted_currency_code,
    fx_rate, fx_fetched_at,
    type, status, reference, description,
    journal_entry_id, created_by,
    occurred_at, processed_at
) VALUES

    -- 1. DEPOSIT $3000 USD → Rafael SAVINGS (COMPLETED)
    ('c0000003-0000-0000-0000-000000000001', NULL, 'b0000002-0000-0000-0000-000000000001',
     3000.00, 'USD', NULL, NULL, NULL, NULL,
     'DEPOSIT', 'COMPLETED', 'DEP-SV-20250101-001', 'Initial USD deposit',
     'e0000005-0000-0000-0000-000000000001', 'auth0|operator001',
     NOW() - INTERVAL '28 days', NOW() - INTERVAL '28 days'),

    -- 2. DEPOSIT $500 SVC → Rafael SAVINGS (COMPLETED)
    ('c0000003-0000-0000-0000-000000000002', NULL, 'b0000002-0000-0000-0000-000000000001',
     500.00, 'SVC', NULL, NULL, NULL, NULL,
     'DEPOSIT', 'COMPLETED', 'DEP-SV-20250101-002', 'SVC deposit',
     'e0000005-0000-0000-0000-000000000002', 'auth0|operator001',
     NOW() - INTERVAL '27 days', NOW() - INTERVAL '27 days'),

    -- 3. DEPOSIT $1000 USD → Rafael CHECKING (COMPLETED)
    ('c0000003-0000-0000-0000-000000000003', NULL, 'b0000002-0000-0000-0000-000000000002',
     1000.00, 'USD', NULL, NULL, NULL, NULL,
     'DEPOSIT', 'COMPLETED', 'DEP-SV-20250101-003', 'Initial CHECKING deposit',
     'e0000005-0000-0000-0000-000000000003', 'auth0|operator001',
     NOW() - INTERVAL '27 days', NOW() - INTERVAL '27 days'),

    -- 4. DEPOSIT $2000 USD → Valentina SAVINGS (COMPLETED)
    ('c0000003-0000-0000-0000-000000000004', NULL, 'b0000002-0000-0000-0000-000000000003',
     2000.00, 'USD', NULL, NULL, NULL, NULL,
     'DEPOSIT', 'COMPLETED', 'DEP-SV-20250101-004', 'Initial deposit Valentina',
     'e0000005-0000-0000-0000-000000000004', 'auth0|operator001',
     NOW() - INTERVAL '23 days', NOW() - INTERVAL '23 days'),

    -- 5. DEPOSIT $200 SVC → Valentina SAVINGS (COMPLETED)
    ('c0000003-0000-0000-0000-000000000005', NULL, 'b0000002-0000-0000-0000-000000000003',
     200.00, 'SVC', NULL, NULL, NULL, NULL,
     'DEPOSIT', 'COMPLETED', 'DEP-SV-20250101-005', 'SVC deposit Valentina',
     'e0000005-0000-0000-0000-000000000005', 'auth0|operator001',
     NOW() - INTERVAL '22 days', NOW() - INTERVAL '22 days'),

    -- 6. DEPOSIT $300 USD → Lucia SAVINGS (COMPLETED)
    ('c0000003-0000-0000-0000-000000000006', NULL, 'b0000002-0000-0000-0000-000000000004',
     300.00, 'USD', NULL, NULL, NULL, NULL,
     'DEPOSIT', 'COMPLETED', 'DEP-SV-20250101-006', 'Deposit before suspension',
     'e0000005-0000-0000-0000-000000000006', 'auth0|operator001',
     NOW() - INTERVAL '50 days', NOW() - INTERVAL '50 days'),

    -- 7. WITHDRAWAL $200 USD — Rafael CHECKING (COMPLETED)
    ('c0000003-0000-0000-0000-000000000007', 'b0000002-0000-0000-0000-000000000002', NULL,
     200.00, 'USD', NULL, NULL, NULL, NULL,
     'WITHDRAWAL', 'COMPLETED', 'WDR-SV-20250110-001', 'ATM withdrawal',
     'e0000005-0000-0000-0000-000000000007', 'auth0|customer-rafael',
     NOW() - INTERVAL '18 days', NOW() - INTERVAL '18 days'),

    -- 8. TRANSFER $150 USD Rafael SAVINGS → Valentina SAVINGS (COMPLETED)
    ('c0000003-0000-0000-0000-000000000008',
     'b0000002-0000-0000-0000-000000000001', 'b0000002-0000-0000-0000-000000000003',
     150.00, 'USD', NULL, NULL, NULL, NULL,
     'TRANSFER', 'COMPLETED', 'TRF-SV-20250112-001', 'Shared rent payment',
     'e0000005-0000-0000-0000-000000000008', 'auth0|customer-rafael',
     NOW() - INTERVAL '15 days', NOW() - INTERVAL '15 days'),

    -- 9. TRANSFER $500 USD Valentina → Rafael SAVINGS (COMPLETED)
    ('c0000003-0000-0000-0000-000000000009',
     'b0000002-0000-0000-0000-000000000003', 'b0000002-0000-0000-0000-000000000001',
     500.00, 'USD', NULL, NULL, NULL, NULL,
     'TRANSFER', 'COMPLETED', 'TRF-SV-20250113-001', 'Transfer back to Rafael',
     'e0000005-0000-0000-0000-000000000009', 'auth0|customer-valentina',
     NOW() - INTERVAL '14 days', NOW() - INTERVAL '14 days'),

    -- 10. TRANSFER cross-currency $310 USD → ₿0.005 BTC — Rafael (COMPLETED)
    ('c0000003-0000-0000-0000-000000000010',
     'b0000002-0000-0000-0000-000000000001', 'b0000002-0000-0000-0000-000000000001',
     310.00, 'USD', 0.00500000, 'BTC', 0.0000161290, '2025-01-14 10:00:00+00',
     'TRANSFER', 'COMPLETED', 'TRF-SV-20250114-001', 'USD to BTC conversion',
     'e0000005-0000-0000-0000-000000000010', 'auth0|customer-rafael',
     NOW() - INTERVAL '13 days', NOW() - INTERVAL '13 days'),

    -- 11. TRANSFER cross-currency ₿0.0005 BTC → $30.56 USD — Rafael (COMPLETED)
    ('c0000003-0000-0000-0000-000000000011',
     'b0000002-0000-0000-0000-000000000001', 'b0000002-0000-0000-0000-000000000001',
     0.00050000, 'BTC', 30.56, 'USD', 61111.1100000000, '2025-01-15 14:30:00+00',
     'TRANSFER', 'COMPLETED', 'TRF-SV-20250115-001', 'BTC to USD partial sell',
     'e0000005-0000-0000-0000-000000000011', 'auth0|customer-rafael',
     NOW() - INTERVAL '12 days', NOW() - INTERVAL '12 days'),

    -- 12. DEPOSIT $50000 USD — FAILED (no journal entry)
    ('c0000003-0000-0000-0000-000000000012', NULL, 'b0000002-0000-0000-0000-000000000001',
     50000.00, 'USD', NULL, NULL, NULL, NULL,
     'DEPOSIT', 'FAILED', 'DEP-SV-20250116-001', 'Large deposit — rejected by compliance',
     NULL, 'auth0|operator002',
     NOW() - INTERVAL '11 days', NOW() - INTERVAL '11 days'),

    -- 13. TRANSFER $100 USD Rafael → Valentina — REVERSED
    ('c0000003-0000-0000-0000-000000000013',
     'b0000002-0000-0000-0000-000000000001', 'b0000002-0000-0000-0000-000000000003',
     100.00, 'USD', NULL, NULL, NULL, NULL,
     'TRANSFER', 'REVERSED', 'TRF-SV-20250117-001', 'Erroneous transfer — reversed by admin',
     'e0000005-0000-0000-0000-000000000012', 'auth0|customer-rafael',
     NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days'),

    -- 14. DEPOSIT $500 USD — PENDING (no journal entry yet)
    ('c0000003-0000-0000-0000-000000000014', NULL, 'b0000002-0000-0000-0000-000000000002',
     500.00, 'USD', NULL, NULL, NULL, NULL,
     'DEPOSIT', 'PENDING', 'DEP-SV-20250120-001', 'Wire transfer — awaiting confirmation',
     NULL, 'auth0|operator001',
     NOW() - INTERVAL '1 day', NULL),

    -- 15. WITHDRAWAL $690 USD — Rafael SAVINGS (COMPLETED)
    ('c0000003-0000-0000-0000-000000000015', 'b0000002-0000-0000-0000-000000000001', NULL,
     690.00, 'USD', NULL, NULL, NULL, NULL,
     'WITHDRAWAL', 'COMPLETED', 'WDR-SV-20250118-001', 'Bill payment',
     'e0000005-0000-0000-0000-000000000013', 'auth0|customer-rafael',
     NOW() - INTERVAL '9 days', NOW() - INTERVAL '9 days');
