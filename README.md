# EMC Contract Intake & Risk Review

A browser-based contract risk desk for **Earth Moving Creations (EMC)** — civil / earthmoving, **NSW · ACT · VIC** — that checks every incoming contract, subcontract or purchase order against EMC's standard Terms & Conditions (the fixed benchmark) and runs the full 4-step review in one pass.

## Site layout

| File | What it is |
|------|-----------|
| **`index.html`** | Landing page — brand hero, the 4 steps, jurisdictions, and iPhone install instructions. Links to the app. |
| **`app.html`** | The review tool itself (paste/drop a contract → 4-step review). |
| `manifest.webmanifest`, `sw.js`, `icons/` | PWA: makes the site installable on an iPhone home screen as a standalone app that works offline. |
| `app.yaml` | Google App Engine config for hosting the whole site over HTTPS. |
| `vendor/` | Vendored [pdf.js](https://mozilla.github.io/pdf.js/) for local PDF text extraction. |
| `assets/` | Brand hero image + video. |

Open `app.html` in any browser (double-click, or host it) — no build step; everything runs client-side.

## Two ways to review

- **AI review (recommended)** — reads the *whole* contract with Claude and reasons over it clause-by-clause. Paste your [Anthropic API key](https://console.anthropic.com/settings/keys) (stored in your browser only), pick a model (Opus 5 / Sonnet 5 / Haiku 4.5), and press **Run AI review** (~10–30¢ per review). Works when `app.html` is opened locally **or served from a real host** (App Engine / GitHub Pages / any HTTPS site). It does **not** work in the published claude.ai artifact, whose sandbox blocks external API calls.
- **Offline scan** — an instant, fully-local heuristic pass (~21 rules). Free, private, nothing leaves the browser. Always available, and the only mode in the hosted artifact.

## Run a review

1. Enter the counterparty (name, ABN/ACN), jurisdiction (NSW / ACT / VIC) and contract type.
2. Add the contract — **drop a PDF (or `.txt`)**, pick a file, or paste text. PDF text is extracted locally (scanned/image-only PDFs won't extract — paste those).
3. Press **Run AI review** or **Offline scan**. Use **Load clean example** (mirrors EMC's terms → **Low** risk) or **Load risky example** (pay-when-paid, time-bars, latent conditions, etc. → **High** risk) to see both ends. The same two contracts are in **`samples/`** (`clean-subcontract.txt`, `risky-subcontract.txt`) if you'd rather drop the file in.

## Install on iPhone

Open the site in **Safari** → tap **Share** → **Add to Home Screen** → **Add**. It launches full-screen like a native app, keeps the EMC icon, and the offline scan works with no connection.

## Host it (shared, with AI review working)

Because a real HTTPS origin can call the Anthropic API directly from the browser, hosting makes the AI review work for everyone with a key:

- **Google App Engine** (this repo is App-Engine-ready): `gcloud app deploy` — serves `index.html` + `app.html` over HTTPS.
- **GitHub Pages**: in the repo, **Settings → Pages**, set the source branch and root, and open the published URL.
- Any static host (Netlify, Cloudflare Pages, S3+CloudFront, etc.) — just upload the folder.

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
