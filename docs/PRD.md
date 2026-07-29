# EMC — Trade Contract & Dispute Protection

**Product spec / build blueprint · v0.1 · Australia (all states)**

> ⚠️ **Not legal advice.** This product automates documents and deadlines. All
> legislation content must be prepared and reviewed by a qualified Australian
> construction lawyer before release, and the app must present clear disclaimers.

---

## 1. Vision

A white-label SaaS that helps subcontractors and trade businesses **protect their
contracts and get paid** — stopping them being "stung" by head builders and
developers through non-payment, dodgy variations, back-charges and unfair terms —
with a built-in **disputes** workflow.

Each customer sees **their own brand**, picks **their trade** and **state**, and
from that point the entire app — contract templates, payment-claim deadlines,
dispute tools and the laws it cites — is scoped to that trade and jurisdiction.

EMC (Earth Moving Creations) is the flagship brand and the reference template all
other tenants are cloned from.

## 2. Who it's for

| User | Need |
|------|------|
| Sole trader / subbie | Simple contracts, get paid on time, know their rights |
| Trade business (owner/admin) | Manage many jobs, staff, standardised paperwork |
| (Future) Legal/advisor partner | Maintain jurisdiction content, oversee disputes |

## 3. The core idea — adaptability on three axes

Everything is **config/data-driven**, never hard-coded, so scaling to a new trade
or state is a data change, not a code change.

| Axis | Drives | Source |
|------|--------|--------|
| **Tenant** | Logo, colours, business name, users, billing | `tenants` |
| **Trade** | Which templates, checklists, dispute types appear | `trades` |
| **Jurisdiction** | Which laws, statutory deadlines and forms apply | `jurisdictions`, `law_rules` |

The landing page's **trade + state pickers** set a `context = {trade, jurisdiction}`
that scopes every screen inside the app (`WHERE trade = ? AND jurisdiction = ?`).

See [`schema.sql`](./schema.sql) for the concrete data model.

## 4. Feature set

### 4.1 White-label landing gate ✅ (prototype built — `/index.html`)
- Branded animated logo as the entry point (EMC excavator animation by default).
- Brand is a config object (`BRAND`) — wordmark, subtitle, accent colour, optional
  uploaded logo. In production these come from `tenants`.
- **Trade** and **State/Territory** dropdowns; "Enter" carries the selection into
  the app (`?trade=&state=` / session context).
- Accessible (keyboard, `prefers-reduced-motion`), responsive.

### 4.2 Contract protection
- Trade + jurisdiction contract templates assembled from a **clause library**.
- Plain-language risk flags on dangerous clauses (unfair time-bars, pay-when-paid).
- Generate a signable contract / quote with correct payment terms.

### 4.3 Payment claims (the anti-"sting" engine)
- Create a payment claim against a project.
- **Deadline engine**: from the serve date, compute statutory dates
  (payment schedule reply window, adjudication window) from `law_rules`.
- Automated reminders before each deadline lapses.
- One-click generation of claims, payment schedules and notices as PDFs.

### 4.4 Disputes
- Intake wizard → category (non-payment, variation, back-charge, defect, termination).
- Deadline-aware timeline per jurisdiction.
- Document generation (adjudication application, notices) + evidence/correspondence log.
- Status tracking through to resolution.

### 4.5 Projects & records
- Job register (head contractor, value, dates), document vault, immutable audit trail.

## 5. Architecture

```
[ Branded landing (this repo) ]  →  context {trade, state}
              │
              ▼
[ App shell: tenant branding + auth ]
              │
   ┌──────────┼───────────────┬───────────────┐
   ▼          ▼               ▼               ▼
Contracts  Payment claims   Disputes        Projects
   └──────────┴──────── read config ────────┘
                 trades · jurisdictions · law_rules · clauses (CMS)
```

**Suggested stack**
- Frontend: **Next.js / React** (drop the landing animation straight in)
- Backend + DB: **Node or Rails + PostgreSQL** (relational fits trade×jurisdiction)
- Legal content: **headless CMS** (Sanity/Strapi) so lawyers, not devs, keep
  `law_rules`/`clauses` current and versioned
- Auth + multi-tenancy: row-level tenant isolation
- Billing: **Stripe** (per-seat or per-business)
- Docs: server-side **PDF generation**
- Storage: object store for documents/evidence

## 6. Roadmap

1. **MVP** — one trade + one state (e.g. Civil · NSW): branded landing ✅, contract
   template, payment-claim generator + deadline reminders.
2. **Multi-trade / multi-state** — move templates & `law_rules` into the CMS; wire
   the pickers (config already modelled for all AU states).
3. **White-label** — tenant branding, logo upload, per-tenant landing.
4. **Scale** — billing, roles/permissions, analytics, disputes depth, more content.

## 7. Compliance & risk (non-negotiable before selling)

- **Framing**: document automation + reminders, *not* legal advice. Prominent
  disclaimers; "prepared by you, review with your lawyer".
- **Content governance**: every `law_rules` entry lawyer-reviewed, versioned,
  dated (`reviewed_by`, `effective_from/to`). WA is transitioning between acts —
  verify current commencement.
- **Data**: contracts are sensitive — encryption at rest/in transit, access
  controls, Australian data residency, Privacy Act compliance.
- **Insurance**: professional indemnity before go-to-market.

## 8. Out of scope (for now)
- Acting as a legal representative or lodging with adjudication bodies on the user's behalf.
- Non-construction industries; non-Australian jurisdictions.
- Accounting/invoicing beyond payment claims (integrate, don't rebuild).
