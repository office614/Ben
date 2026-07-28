# EMC Contract Intake & Risk Review

An interactive, single-file browser app for **Earth Moving Creations (EMC)** — civil / earthmoving, **NSW · ACT · VIC** — that checks every incoming contract, subcontract or purchase order against EMC's standard Terms & Conditions (the fixed benchmark) and runs the full 4-step review in one pass.

Two ways to review a contract:

- **AI review (recommended)** — reads the *whole* contract with Claude and reasons over it clause-by-clause. Paste your [Anthropic API key](https://console.anthropic.com/settings/keys) (stored in your browser only), pick a model (Opus 5 / Sonnet 5 / Haiku 4.5), and press **Run AI review**. The contract text + EMC's T&Cs go to the Anthropic API under your key (~10–30¢ per review). Works when you open `index.html` locally or host it yourself — **not** in the published web artifact, whose sandbox blocks external API calls.
- **Offline scan** — an instant, fully-local heuristic pass (~21 rules). Free, private, nothing leaves the browser. This is the only mode in the hosted artifact.

## Use it

Open **`index.html`** in any browser (double-click, or host it anywhere). No install, no server, no build step. Everything runs locally in the browser — nothing is uploaded or sent anywhere.

1. Enter the counterparty (name, ABN/ACN), jurisdiction (NSW / ACT / VIC) and contract type.
2. Add the contract — **drop a PDF (or `.txt`) onto the contract box**, choose one with the file picker, or paste the text directly. PDF text is extracted locally in the browser (image-only/scanned PDFs won't extract — paste those).
3. Press **Run full review**.

> PDF extraction uses a vendored copy of [pdf.js](https://mozilla.github.io/pdf.js/) in `vendor/` — keep that folder alongside `index.html`. Everything still runs offline; nothing is fetched at runtime.

Use **Load worked example** to see it in action against a sample subcontract.

## What it does — the 4 steps

1. **Clause-by-clause risk detection.** Scans the contract against EMC's 15 standard terms and flags every clause that is *weaker than*, *conflicts with*, or is *missing* relative to EMC's position — each mapped to the specific EMC clause number with exactly what to **strike or add**.
2. **Counterparty look-up.** Deep-links (pre-filled with the entity/ABN) into the ABN Lookup register, ASIC registers, ASIC published insolvency notices, caselaw and adverse-news searches, plus a structured template to record entity status, incorporation date, registered address and any adverse findings. *Public-record and news checking only — not a commercial credit report.*
3. **Risk profile.** A structured profile on the standing template with an overall **low / medium / high** rating derived from the flags, plus suggested extra fields to track next time.
4. **Draft response.** A direct, commercial email to the counterparty raising the flagged issues, citing the applicable **Security of Payment Act** provisions (NSW *BCISPA 1999* / ACT *BCI(SoP)A 2009* / VIC *BCISPA 2002*) and **Australian Consumer Law** sections. **Open in Gmail** (opens a pre-filled Gmail compose window — enter a counterparty email in the intake and the recipient is filled too), copy, print/PDF, or export the whole review as text.

The detection engine covers pay-when-paid, over-length payment terms, verbal variations, ambiguity in the principal's favour, set-off, removal of suspension rights, contracting-out of SoP, LDs / "time of the essence", uncapped indemnity, open-ended scope, ouster of adjudication, and earthmoving-specific risks: **latent / differing site conditions**, **time-bars / conditions precedent** on claims and EOTs, **termination for convenience**, novation/assignment, long defects-liability periods, insurance/PI requirements, and personal/director guarantees.

## Benchmark

EMC's full 15-clause Terms & Conditions are embedded in the app (expandable at the bottom) and are the fixed benchmark every contract is measured against.

## Notes

- Clause detection is **heuristic** — it flags candidates for review and is **not legal advice**; it does not replace a solicitor. Absence of a red flag is not confirmation a clause is compliant.
- The counterparty steps require you to open the linked registers and record what you find.
