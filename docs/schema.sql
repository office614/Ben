-- ============================================================
--  EMC Contract & Dispute Protection — core data model
--  Target: PostgreSQL 14+
--
--  Design principle: the app is adaptable along THREE axes, all
--  driven by data (not code):
--     tenant       -> branding, users, billing        (who)
--     trade        -> templates, checklists shown       (what)
--     jurisdiction -> which laws / deadlines / forms     (where)
--
--  Adding a trade or a state = INSERT a row, never a deploy.
--  Legislation content in `law_rules` MUST be lawyer-reviewed.
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- gen_random_uuid()

-- ---------- reference data (shared across all tenants) ----------

CREATE TABLE trades (
    id          TEXT PRIMARY KEY,            -- 'civil', 'carpentry', ...
    name        TEXT NOT NULL,
    sort_order  INT  NOT NULL DEFAULT 0,
    active      BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE jurisdictions (
    id          TEXT PRIMARY KEY,            -- 'nsw', 'qld', ...
    name        TEXT NOT NULL,
    country     TEXT NOT NULL DEFAULT 'AU',
    sop_act     TEXT NOT NULL,               -- Security of Payment act name
    active      BOOLEAN NOT NULL DEFAULT TRUE
);

-- Per (trade x jurisdiction) legal ruleset that drives deadlines,
-- notices and generated documents. Versioned + review-gated.
CREATE TABLE law_rules (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trade_id              TEXT REFERENCES trades(id),          -- NULL = applies to all trades
    jurisdiction_id       TEXT NOT NULL REFERENCES jurisdictions(id),
    version               INT  NOT NULL DEFAULT 1,
    effective_from        DATE NOT NULL,
    effective_to          DATE,                                -- NULL = current
    -- statutory timeframes (days) — indicative fields, extend as needed
    payment_claim_due_days      INT,
    payment_schedule_reply_days INT,
    adjudication_apply_days     INT,
    payload               JSONB NOT NULL DEFAULT '{}',         -- full ruleset detail
    reviewed_by           TEXT,                                -- legal sign-off
    reviewed_at           TIMESTAMPTZ,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX law_rules_lookup ON law_rules (jurisdiction_id, trade_id, effective_from);

-- Reusable contract clauses, tagged by trade/jurisdiction applicability.
CREATE TABLE clauses (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code            TEXT NOT NULL,           -- 'retention', 'variation', 'payment-terms'
    title           TEXT NOT NULL,
    body            TEXT NOT NULL,
    trade_id        TEXT REFERENCES trades(id),         -- NULL = any trade
    jurisdiction_id TEXT REFERENCES jurisdictions(id),  -- NULL = any jurisdiction
    risk_note       TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE contract_templates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            TEXT NOT NULL,
    trade_id        TEXT REFERENCES trades(id),
    jurisdiction_id TEXT REFERENCES jurisdictions(id),
    description     TEXT,
    active          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE template_clauses (          -- ordered clause set for a template
    template_id  UUID REFERENCES contract_templates(id) ON DELETE CASCADE,
    clause_id    UUID REFERENCES clauses(id),
    position     INT  NOT NULL,
    PRIMARY KEY (template_id, clause_id)
);

-- ---------- tenants (each paying customer / business) ----------

CREATE TABLE tenants (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_name       TEXT NOT NULL,
    abn                 TEXT,                                   -- Australian Business Number
    primary_trade_id    TEXT REFERENCES trades(id),
    default_jurisdiction_id TEXT REFERENCES jurisdictions(id),
    -- white-label branding (the "adaptable logo" layer)
    brand_wordmark      TEXT,                                   -- e.g. 'EMC'
    brand_subtitle      TEXT,                                   -- e.g. 'EARTH MOVING CREATIONS'
    brand_accent        TEXT DEFAULT '#ff1a44',
    brand_logo_url      TEXT,                                   -- uploaded logo (overrides wordmark)
    subscription_status TEXT NOT NULL DEFAULT 'trial',          -- trial|active|past_due|cancelled
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- A tenant may operate across several trades (primary set on tenants).
CREATE TABLE tenant_trades (
    tenant_id  UUID REFERENCES tenants(id) ON DELETE CASCADE,
    trade_id   TEXT REFERENCES trades(id),
    PRIMARY KEY (tenant_id, trade_id)
);

CREATE TABLE users (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id    UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    email        TEXT NOT NULL UNIQUE,
    full_name    TEXT,
    role         TEXT NOT NULL DEFAULT 'member',                -- owner|admin|member
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX users_tenant ON users (tenant_id);

-- ---------- tenant working data ----------

CREATE TABLE projects (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id          UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name               TEXT NOT NULL,
    trade_id           TEXT REFERENCES trades(id),
    jurisdiction_id    TEXT REFERENCES jurisdictions(id),       -- where the work is performed
    head_contractor    TEXT,                                    -- the builder/developer
    contract_value     NUMERIC(14,2),
    start_date         DATE,
    status             TEXT NOT NULL DEFAULT 'active',          -- active|completed|archived
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX projects_tenant ON projects (tenant_id);

CREATE TABLE payment_claims (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id       UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    reference        TEXT,
    amount           NUMERIC(14,2) NOT NULL,
    claimed_on       DATE NOT NULL,
    -- computed from law_rules at creation time, then reminded on:
    schedule_due_by  DATE,
    adjudicate_by    DATE,
    status           TEXT NOT NULL DEFAULT 'served',            -- draft|served|scheduled|paid|disputed
    document_id      UUID,                                       -- generated PDF
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX payment_claims_project ON payment_claims (project_id);

CREATE TABLE disputes (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id        UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    project_id       UUID REFERENCES projects(id) ON DELETE SET NULL,
    category         TEXT NOT NULL,             -- non_payment|variation|backcharge|defect|termination
    jurisdiction_id  TEXT REFERENCES jurisdictions(id),
    amount_in_disp   NUMERIC(14,2),
    opened_on        DATE NOT NULL DEFAULT CURRENT_DATE,
    next_action_by   DATE,                      -- statutory deadline driver
    status           TEXT NOT NULL DEFAULT 'open', -- open|negotiating|adjudication|resolved|withdrawn
    summary          TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX disputes_tenant ON disputes (tenant_id);

-- Generated + uploaded files (claims, notices, evidence, correspondence).
CREATE TABLE documents (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id    UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    project_id   UUID REFERENCES projects(id) ON DELETE SET NULL,
    dispute_id   UUID REFERENCES disputes(id) ON DELETE SET NULL,
    kind         TEXT NOT NULL,                 -- payment_claim|payment_schedule|notice|evidence|contract
    title        TEXT,
    storage_url  TEXT NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Immutable trail (deadlines are legally significant — log everything).
CREATE TABLE audit_events (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id    UUID REFERENCES tenants(id) ON DELETE CASCADE,
    user_id      UUID REFERENCES users(id) ON DELETE SET NULL,
    entity       TEXT NOT NULL,                 -- 'payment_claim', 'dispute', ...
    entity_id    UUID,
    action       TEXT NOT NULL,                 -- 'created', 'served', 'status_changed'
    detail       JSONB NOT NULL DEFAULT '{}',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
--  Seed: Australian jurisdictions (indicative — verify with a lawyer)
-- ============================================================
INSERT INTO jurisdictions (id, name, sop_act) VALUES
 ('nsw','New South Wales',              'Building & Construction Industry Security of Payment Act 1999 (NSW)'),
 ('vic','Victoria',                     'Building & Construction Industry Security of Payment Act 2002 (Vic)'),
 ('qld','Queensland',                   'Building Industry Fairness (Security of Payment) Act 2017 (Qld)'),
 ('wa', 'Western Australia',            'Building & Construction Industry (Security of Payment) Act 2021 (WA)'),
 ('sa', 'South Australia',              'Building & Construction Industry Security of Payment Act 2009 (SA)'),
 ('tas','Tasmania',                     'Building & Construction Industry Security of Payment Act 2009 (Tas)'),
 ('act','Australian Capital Territory', 'Building & Construction Industry (Security of Payment) Act 2009 (ACT)'),
 ('nt', 'Northern Territory',           'Construction Contracts (Security of Payments) Act 2004 (NT)')
ON CONFLICT (id) DO NOTHING;

INSERT INTO trades (id, name, sort_order) VALUES
 ('carpentry','Carpentry',1),('civil','Civil',2),('masonry','Masonry & Bricklaying',3),
 ('concreting','Concreting',4),('earthmoving','Earthmoving & Excavation',5),('electrical','Electrical',6),
 ('plumbing','Plumbing',7),('roofing','Roofing',8),('steelfixing','Steel Fixing',9),
 ('plastering','Plastering',10),('tiling','Tiling',11),('painting','Painting & Decorating',12),
 ('landscaping','Landscaping',13),('demolition','Demolition',14),('glazing','Glazing',15),
 ('hvac','HVAC & Mechanical',16)
ON CONFLICT (id) DO NOTHING;
