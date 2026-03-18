-- liquibase formatted sql
-- changeset data-model:1

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