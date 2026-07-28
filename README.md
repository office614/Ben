# EMC Contract Intake & Risk Review

An interactive, single-file browser app for **Earth Moving Creations (EMC)** — civil / earthmoving, ACT & NSW — that checks every incoming contract, subcontract or purchase order against EMC's standard Terms & Conditions (the fixed benchmark) and runs the full 4-step review in one pass.

## Use it

Open **`index.html`** in any browser (double-click, or host it anywhere). No install, no server, no build step. Everything runs locally in the browser — nothing is uploaded or sent anywhere.

1. Enter the counterparty (name, ABN/ACN), jurisdiction (NSW/ACT) and contract type.
2. Paste the contract text (or upload a `.txt`/`.md` file). For PDF/Word, copy the text and paste it in.
3. Press **Run full review**.

Use **Load worked example** to see it in action against a sample subcontract.

## What it does — the 4 steps

1. **Clause-by-clause risk detection.** Scans the contract against EMC's 15 standard terms and flags every clause that is *weaker than*, *conflicts with*, or is *missing* relative to EMC's position — each mapped to the specific EMC clause number with exactly what to **strike or add**.
2. **Counterparty look-up.** Deep-links (pre-filled with the entity/ABN) into the ABN Lookup register, ASIC registers, ASIC published insolvency notices, caselaw and adverse-news searches, plus a structured template to record entity status, incorporation date, registered address and any adverse findings. *Public-record and news checking only — not a commercial credit report.*
3. **Risk profile.** A structured profile on the standing template with an overall **low / medium / high** rating derived from the flags, plus suggested extra fields to track next time.
4. **Draft response.** A direct, commercial email to the counterparty raising the flagged issues, citing the applicable **Security of Payment Act** provisions (NSW or ACT) and **Australian Consumer Law** sections. Copy, print/PDF, or export the whole review as text.

## Benchmark

EMC's full 15-clause Terms & Conditions are embedded in the app (expandable at the bottom) and are the fixed benchmark every contract is measured against.

## Notes

- Clause detection is **heuristic** — it flags candidates for review and is **not legal advice**; it does not replace a solicitor. Absence of a red flag is not confirmation a clause is compliant.
- The counterparty steps require you to open the linked registers and record what you find.
