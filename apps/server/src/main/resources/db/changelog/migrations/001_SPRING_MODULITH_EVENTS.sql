-- liquibase formatted sql
-- changeset spring-modulith:1

/*CREATE TABLE IF NOT EXISTS event_publication (
    id UUID NOT NULL,
    completion_date TIMESTAMP WITH TIME ZONE,
    event_type VARCHAR(512) NOT NULL,
    listener_id VARCHAR(512) NOT NULL,
    publication_date TIMESTAMP WITH TIME ZONE NOT NULL,
    serialized_event VARCHAR(4000) NOT NULL,
    PRIMARY KEY (id)
);*/

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