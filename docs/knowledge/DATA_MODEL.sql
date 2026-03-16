-- =============================================================================
-- KuboBank — Initial Data Model
-- Compatible with: PostgreSQL 15+
-- Managed by: Liquibase (this file is the canonical schema reference)
-- Architecture: Clean Architecture + DDD + CQRS
-- Version: 2.0.0
-- Seed data: see SEED_DATA.sql
-- =============================================================================
-- Bounded Contexts covered:
--   shared      → currencies, jurisdictions, jurisdiction_currencies
--   identity    → customers
--   account     → accounts, account_balances
--   ledger      → chart_of_accounts, journal_entries, journal_entry_lines
--   transaction → transactions (references journal_entry_id)
--   global      → event_publication (Spring Modulith Outbox)
-- Read side:
--   account_balance_view, transaction_history_view
-- =============================================================================
-- IMPORTANT — Creation order respects FK dependencies:
--   currencies → jurisdictions → jurisdiction_currencies
--   → customers → accounts → account_balances
--   → chart_of_accounts → journal_entries → journal_entry_lines
--   → transactions → event_publication
-- =============================================================================


-- =============================================================================
-- EXTENSIONS
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- =============================================================================
-- SHARED — Currencies
-- =============================================================================

CREATE TABLE currencies (
    code            VARCHAR(10)     NOT NULL,
    type            VARCHAR(20)     NOT NULL,
    decimals        SMALLINT        NOT NULL,
    symbol          VARCHAR(5)      NOT NULL,
    active          BOOLEAN         NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_currencies          PRIMARY KEY (code),
    CONSTRAINT ck_currencies_type     CHECK (type IN ('FIAT_LOCAL', 'FIAT_FOREIGN', 'CRYPTO')),
    CONSTRAINT ck_currencies_decimals CHECK (decimals >= 0 AND decimals <= 18)
);

COMMENT ON TABLE  currencies          IS 'Catalogue of all monetary assets (fiat + crypto). Deactivate instead of delete.';
COMMENT ON COLUMN currencies.type     IS 'FIAT_LOCAL: national currency. FIAT_FOREIGN: foreign legal tender. CRYPTO: crypto asset.';
COMMENT ON COLUMN currencies.decimals IS '2 for fiat, 8 for BTC.';
COMMENT ON COLUMN currencies.active   IS 'FALSE on regulatory reversal. Affected accounts move to REVIEW.';


-- =============================================================================
-- SHARED — Jurisdictions
-- =============================================================================

CREATE TABLE jurisdictions (
    country_code    CHAR(2)         NOT NULL,
    name            VARCHAR(100)    NOT NULL,

    CONSTRAINT pk_jurisdictions PRIMARY KEY (country_code)
);

COMMENT ON TABLE  jurisdictions              IS 'Countries where Kubo Bank operates.';
COMMENT ON COLUMN jurisdictions.country_code IS 'ISO 3166-1 alpha-2.';


-- =============================================================================
-- SHARED — Jurisdiction Currencies
-- =============================================================================

CREATE TABLE jurisdiction_currencies (
    country_code    CHAR(2)         NOT NULL,
    currency_code   VARCHAR(10)     NOT NULL,

    CONSTRAINT pk_jurisdiction_currencies PRIMARY KEY (country_code, currency_code),
    CONSTRAINT fk_jc_jurisdiction         FOREIGN KEY (country_code)  REFERENCES jurisdictions (country_code),
    CONSTRAINT fk_jc_currency             FOREIGN KEY (currency_code) REFERENCES currencies (code)
);

COMMENT ON TABLE jurisdiction_currencies IS 'Allowed currencies per jurisdiction. Drives multi-currency account rules.';


-- =============================================================================
-- IDENTITY — Customers
-- =============================================================================

CREATE TABLE customers (
    customer_id         UUID            NOT NULL DEFAULT gen_random_uuid(),
    full_name           VARCHAR(200)    NOT NULL,
    email               VARCHAR(254)    NOT NULL,
    phone_country_code  VARCHAR(5)      NOT NULL,
    phone_number        VARCHAR(20)     NOT NULL,
    status              VARCHAR(20)     NOT NULL DEFAULT 'PENDING',
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_customers        PRIMARY KEY (customer_id),
    CONSTRAINT uq_customers_email  UNIQUE (email),
    CONSTRAINT ck_customers_status CHECK (status IN ('PENDING', 'ACTIVE', 'SUSPENDED'))
);

COMMENT ON TABLE  customers        IS 'Banking customer profile. Authentication delegated to Auth0.';
COMMENT ON COLUMN customers.status IS 'PENDING: not yet verified. ACTIVE: operational. SUSPENDED: access blocked.';


-- =============================================================================
-- ACCOUNT — Accounts
-- =============================================================================

CREATE TABLE accounts (
    account_id      UUID            NOT NULL DEFAULT gen_random_uuid(),
    customer_id     UUID            NOT NULL,
    account_number  VARCHAR(30)     NOT NULL,
    type            VARCHAR(20)     NOT NULL,
    country_code    CHAR(2)         NOT NULL,
    status          VARCHAR(20)     NOT NULL DEFAULT 'ACTIVE',
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_accounts              PRIMARY KEY (account_id),
    CONSTRAINT uq_accounts_number       UNIQUE (account_number),
    CONSTRAINT fk_accounts_customer     FOREIGN KEY (customer_id)  REFERENCES customers (customer_id),
    CONSTRAINT fk_accounts_jurisdiction FOREIGN KEY (country_code) REFERENCES jurisdictions (country_code),
    CONSTRAINT ck_accounts_type         CHECK (type IN ('SAVINGS', 'CHECKING')),
    CONSTRAINT ck_accounts_status       CHECK (status IN ('ACTIVE', 'FROZEN', 'CLOSED', 'REVIEW'))
);

COMMENT ON TABLE  accounts             IS 'Multi-currency bank account. Balances in account_balances.';
COMMENT ON COLUMN accounts.country_code IS 'Jurisdiction — determines allowed currencies.';
COMMENT ON COLUMN accounts.status      IS 'REVIEW: currency deactivated in jurisdiction. Customer must convert balance manually.';

CREATE INDEX idx_accounts_customer_id ON accounts (customer_id);
CREATE INDEX idx_accounts_status      ON accounts (status);


-- =============================================================================
-- ACCOUNT — Account Balances
-- =============================================================================

CREATE TABLE account_balances (
    account_id      UUID            NOT NULL,
    currency_code   VARCHAR(10)     NOT NULL,
    amount          NUMERIC(30, 8)  NOT NULL DEFAULT 0,

    CONSTRAINT pk_account_balances   PRIMARY KEY (account_id, currency_code),
    CONSTRAINT fk_ab_account         FOREIGN KEY (account_id)    REFERENCES accounts (account_id),
    CONSTRAINT fk_ab_currency        FOREIGN KEY (currency_code) REFERENCES currencies (code),
    CONSTRAINT ck_ab_amount_positive CHECK (amount >= 0)
);

COMMENT ON TABLE  account_balances        IS 'One row per account/currency pair. Locked with SELECT FOR UPDATE on write.';
COMMENT ON COLUMN account_balances.amount IS 'NUMERIC(30,8) covers BTC (8 dec) and fiat (2 dec). Never negative.';


-- =============================================================================
-- LEDGER — Chart of Accounts (Plan de Cuentas)
-- One account per currency where applicable.
-- =============================================================================

CREATE TABLE chart_of_accounts (
    code            VARCHAR(20)     NOT NULL,   -- e.g. '2100-USD', '1100-BTC'
    name            VARCHAR(200)    NOT NULL,
    category        VARCHAR(20)     NOT NULL,   -- ASSET | LIABILITY | EQUITY | INCOME | EXPENSE
    currency_code   VARCHAR(10)     NOT NULL,
    active          BOOLEAN         NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_chart_of_accounts          PRIMARY KEY (code),
    CONSTRAINT fk_coa_currency               FOREIGN KEY (currency_code) REFERENCES currencies (code),
    CONSTRAINT ck_coa_category               CHECK (category IN ('ASSET', 'LIABILITY', 'EQUITY', 'INCOME', 'EXPENSE'))
);

COMMENT ON TABLE  chart_of_accounts           IS 'Ledger chart of accounts. One account per currency where applicable.';
COMMENT ON COLUMN chart_of_accounts.code      IS 'Format: {account_number}-{currency_code}. e.g. 2100-USD, 1100-BTC.';
COMMENT ON COLUMN chart_of_accounts.category  IS 'ASSET: what the bank owns. LIABILITY: what the bank owes. EQUITY: net worth. INCOME/EXPENSE: P&L.';


-- =============================================================================
-- LEDGER — Journal Entries (Asientos Contables — Cabecera)
-- AUTOMATIC: generated by the system on TransactionCompleted.
-- MANUAL: created by ROLE_ADMIN for accounting adjustments.
-- =============================================================================

CREATE TABLE journal_entries (
    journal_entry_id    UUID            NOT NULL DEFAULT gen_random_uuid(),
    transaction_id      UUID            NULL,       -- NULL for manual entries
    entry_type          VARCHAR(20)     NOT NULL,   -- AUTOMATIC | MANUAL
    description         VARCHAR(500)    NOT NULL,
    created_by          VARCHAR(128)    NOT NULL,   -- Auth0 sub or 'system'
    occurred_at         TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_journal_entries            PRIMARY KEY (journal_entry_id),
    CONSTRAINT ck_journal_entries_entry_type CHECK (entry_type IN ('AUTOMATIC', 'MANUAL'))
);

COMMENT ON TABLE  journal_entries                IS 'Accounting journal entry header. Each completed transaction generates one automatically.';
COMMENT ON COLUMN journal_entries.transaction_id IS 'NULL for manual adjustment entries created by ADMIN.';
COMMENT ON COLUMN journal_entries.entry_type     IS 'AUTOMATIC: system-generated on TransactionCompleted. MANUAL: ADMIN adjustment.';
COMMENT ON COLUMN journal_entries.created_by     IS 'Auth0 sub for manual entries. ''system'' for automatic entries.';

CREATE INDEX idx_journal_entries_transaction_id ON journal_entries (transaction_id);
CREATE INDEX idx_journal_entries_occurred_at    ON journal_entries (occurred_at DESC);


-- =============================================================================
-- LEDGER — Journal Entry Lines (Líneas de Partida Doble)
-- Each JournalEntry must have at least 2 lines.
-- Sum of DEBIT amounts must equal sum of CREDIT amounts per entry (enforced at app layer).
-- =============================================================================

CREATE TABLE journal_entry_lines (
    line_id             UUID            NOT NULL DEFAULT gen_random_uuid(),
    journal_entry_id    UUID            NOT NULL,
    account_code        VARCHAR(20)     NOT NULL,   -- FK to chart_of_accounts
    side                VARCHAR(10)     NOT NULL,   -- DEBIT | CREDIT
    amount              NUMERIC(30, 8)  NOT NULL,
    currency_code       VARCHAR(10)     NOT NULL,
    bank_account_id     UUID            NULL,       -- FK to accounts (for customer deposit lines)

    CONSTRAINT pk_journal_entry_lines          PRIMARY KEY (line_id),
    CONSTRAINT fk_jel_journal_entry            FOREIGN KEY (journal_entry_id) REFERENCES journal_entries (journal_entry_id),
    CONSTRAINT fk_jel_account_code             FOREIGN KEY (account_code)     REFERENCES chart_of_accounts (code),
    CONSTRAINT fk_jel_currency                 FOREIGN KEY (currency_code)    REFERENCES currencies (code),
    CONSTRAINT fk_jel_bank_account             FOREIGN KEY (bank_account_id)  REFERENCES accounts (account_id),
    CONSTRAINT ck_jel_side                     CHECK (side IN ('DEBIT', 'CREDIT')),
    CONSTRAINT ck_jel_amount_positive          CHECK (amount > 0)
);

COMMENT ON TABLE  journal_entry_lines                 IS 'Double-entry bookkeeping lines. DEBIT sum must equal CREDIT sum per journal_entry (enforced at domain layer).';
COMMENT ON COLUMN journal_entry_lines.side            IS 'DEBIT: increases ASSET/EXPENSE, decreases LIABILITY/EQUITY/INCOME. CREDIT: inverse.';
COMMENT ON COLUMN journal_entry_lines.bank_account_id IS 'References the customer bank account for liability lines (Depósitos de Clientes). NULL for internal accounts.';
COMMENT ON COLUMN journal_entry_lines.account_code    IS 'e.g. 1100-USD (Caja USD), 2100-USD (Depósitos Clientes USD).';

CREATE INDEX idx_jel_journal_entry_id ON journal_entry_lines (journal_entry_id);
CREATE INDEX idx_jel_account_code     ON journal_entry_lines (account_code);
CREATE INDEX idx_jel_bank_account_id  ON journal_entry_lines (bank_account_id);


-- =============================================================================
-- TRANSACTION — Transactions
-- References journal_entry_id — linked atomically on TransactionCompleted.
-- =============================================================================

CREATE TABLE transactions (
    transaction_id              UUID            NOT NULL DEFAULT gen_random_uuid(),

    -- Accounts involved
    origin_account_id           UUID            NULL,
    destination_account_id      UUID            NULL,

    -- Origin Money
    amount                      NUMERIC(30, 8)  NOT NULL,
    amount_currency_code        VARCHAR(10)     NOT NULL,

    -- Converted Money (cross-currency only)
    converted_amount            NUMERIC(30, 8)  NULL,
    converted_currency_code     VARCHAR(10)     NULL,

    -- FX snapshot (cross-currency only)
    fx_rate                     NUMERIC(30, 10) NULL,
    fx_fetched_at               TIMESTAMPTZ     NULL,

    -- Classification
    type                        VARCHAR(20)     NOT NULL,
    status                      VARCHAR(20)     NOT NULL DEFAULT 'PENDING',

    -- Idempotency
    reference                   VARCHAR(100)    NOT NULL,

    -- Ledger link — set when status → COMPLETED
    journal_entry_id            UUID            NULL,

    -- Metadata
    description                 VARCHAR(500)    NULL,
    created_by                  VARCHAR(128)    NOT NULL,

    -- Timestamps
    occurred_at                 TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    processed_at                TIMESTAMPTZ     NULL,

    CONSTRAINT pk_transactions
        PRIMARY KEY (transaction_id),
    CONSTRAINT uq_transactions_reference
        UNIQUE (reference),
    CONSTRAINT fk_tx_origin_account
        FOREIGN KEY (origin_account_id)         REFERENCES accounts (account_id),
    CONSTRAINT fk_tx_destination_account
        FOREIGN KEY (destination_account_id)    REFERENCES accounts (account_id),
    CONSTRAINT fk_tx_amount_currency
        FOREIGN KEY (amount_currency_code)      REFERENCES currencies (code),
    CONSTRAINT fk_tx_converted_currency
        FOREIGN KEY (converted_currency_code)   REFERENCES currencies (code),
    CONSTRAINT fk_tx_journal_entry
        FOREIGN KEY (journal_entry_id)          REFERENCES journal_entries (journal_entry_id),
    CONSTRAINT ck_transactions_type
        CHECK (type IN ('DEPOSIT', 'WITHDRAWAL', 'TRANSFER')),
    CONSTRAINT ck_transactions_status
        CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED', 'REVERSED')),
    CONSTRAINT ck_transactions_amount_positive
        CHECK (amount > 0),
    CONSTRAINT ck_transactions_cross_currency
        CHECK (
            (converted_amount IS NULL AND converted_currency_code IS NULL AND fx_rate IS NULL AND fx_fetched_at IS NULL)
            OR
            (converted_amount IS NOT NULL AND converted_currency_code IS NOT NULL AND fx_rate IS NOT NULL AND fx_fetched_at IS NOT NULL)
        ),
    CONSTRAINT ck_transactions_deposit
        CHECK (type != 'DEPOSIT'    OR (destination_account_id IS NOT NULL AND origin_account_id IS NULL)),
    CONSTRAINT ck_transactions_withdrawal
        CHECK (type != 'WITHDRAWAL' OR (origin_account_id IS NOT NULL AND destination_account_id IS NULL)),
    CONSTRAINT ck_transactions_transfer
        CHECK (type != 'TRANSFER'   OR (origin_account_id IS NOT NULL AND destination_account_id IS NOT NULL)),
    -- COMPLETED transactions must have a journal entry
    CONSTRAINT ck_transactions_completed_has_journal
        CHECK (status != 'COMPLETED' OR journal_entry_id IS NOT NULL)
);

COMMENT ON TABLE  transactions                        IS 'All monetary operations. COMPLETED transactions always have a journal_entry_id.';
COMMENT ON COLUMN transactions.journal_entry_id       IS 'Set atomically when status → COMPLETED. NULL while PENDING. Enforced by ck_transactions_completed_has_journal.';
COMMENT ON COLUMN transactions.reference              IS 'Client idempotency key. Duplicates rejected.';
COMMENT ON COLUMN transactions.created_by             IS 'Auth0 sub. NOT NULL — every transaction has an identified author.';

CREATE INDEX idx_transactions_origin_account      ON transactions (origin_account_id);
CREATE INDEX idx_transactions_destination_account ON transactions (destination_account_id);
CREATE INDEX idx_transactions_status              ON transactions (status);
CREATE INDEX idx_transactions_type                ON transactions (type);
CREATE INDEX idx_transactions_created_by          ON transactions (created_by);
CREATE INDEX idx_transactions_occurred_at         ON transactions (occurred_at DESC);
CREATE INDEX idx_transactions_journal_entry_id    ON transactions (journal_entry_id);


-- =============================================================================
-- GLOBAL — Outbox Events (Spring Modulith Event Publication Registry)
-- =============================================================================

CREATE TABLE event_publication (
    id                  UUID            NOT NULL DEFAULT gen_random_uuid(),
    listener_id         VARCHAR(512)    NOT NULL,
    event_type          VARCHAR(512)    NOT NULL,
    serialized_event    TEXT            NOT NULL,
    publication_date    TIMESTAMPTZ     NOT NULL,
    completion_date     TIMESTAMPTZ     NULL,

    CONSTRAINT pk_event_publication PRIMARY KEY (id)
);

COMMENT ON TABLE event_publication IS 'Spring Modulith Outbox. Atomic event delivery. Do not modify manually.';

CREATE INDEX idx_event_publication_completion ON event_publication (completion_date)
    WHERE completion_date IS NULL;


-- =============================================================================
-- READ SIDE — account_balance_view
-- =============================================================================

CREATE VIEW account_balance_view AS
SELECT
    ab.account_id,
    ab.currency_code,
    ab.amount,
    c.type          AS currency_type,
    c.decimals      AS currency_decimals,
    c.symbol        AS currency_symbol,
    c.active        AS currency_active,
    a.customer_id,
    a.account_number,
    a.country_code,
    a.status        AS account_status
FROM account_balances ab
JOIN accounts         a ON a.account_id = ab.account_id
JOIN currencies       c ON c.code       = ab.currency_code;

COMMENT ON VIEW account_balance_view IS 'Read-side projection for GET /accounts/{id}/balances.';


-- =============================================================================
-- READ SIDE — transaction_history_view
-- =============================================================================

CREATE VIEW transaction_history_view AS
SELECT
    t.transaction_id,
    t.origin_account_id,
    t.destination_account_id,
    t.amount,
    t.amount_currency_code,
    c_amt.type      AS amount_currency_type,
    c_amt.decimals  AS amount_currency_decimals,
    c_amt.symbol    AS amount_currency_symbol,
    t.converted_amount,
    t.converted_currency_code,
    c_conv.type     AS converted_currency_type,
    c_conv.decimals AS converted_currency_decimals,
    c_conv.symbol   AS converted_currency_symbol,
    t.fx_rate,
    t.fx_fetched_at,
    t.type,
    t.status,
    t.reference,
    t.journal_entry_id,
    t.description,
    t.created_by,
    t.occurred_at,
    t.processed_at
FROM transactions    t
JOIN currencies      c_amt  ON c_amt.code  = t.amount_currency_code
LEFT JOIN currencies c_conv ON c_conv.code = t.converted_currency_code;

COMMENT ON VIEW transaction_history_view IS 'Read-side projection for GET /transactions. Includes journal_entry_id.';
