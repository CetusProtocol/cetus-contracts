# CLMM Phase 1: bounded positive/negative acceptance

This phase implements the practical, high-priority test work that does not change
production Move sources. It is distinct from completion of the original requirement
for **every** authorization check and invariant. The overall completion flag remains false.

## Scope implemented

| Area | Concrete acceptance | New tests |
| --- | --- | ---: |
| Configuration | Protocol fee rate; add/update/delete fee tiers. Valid authorized update, revoked role, wrong role, pause, deprecated version; assert resulting state. | 20 |
| Administration | Pool fee/status, reward initialization/emission, funded protocol fee withdrawal, partner rate/time. Same role/version controls; fee withdrawal checks actual pool debit and payout. | 35 |
| User lifecycle | Add liquidity (both forms), full removal, funded fee/reward collection, empty close, swap, loan, open. Active/paused/deprecated/operation-disabled; wrong pool where relevant. Deposits/withdrawals conserve assets; repeated fee/reward collection is zero; nonempty close aborts. | 43 |
| Pending liquidity receipts | Exact A/B payment, one-unit under/overpayment independently per token, foreign pool, pause/deprecation after receipt creation. | 8 |
| Partner claims | Actual claim returns exactly the funded balance and empties the container; foreign capability, pause/deprecation, absent asset and repeated claim reject. Credit is a fixture here; production swap-to-partner credit is covered separately. | 6 |

Total: **112 additional tests** beyond the preceding 437-test baseline. Prior real
swap/loan repayment, referral conservation, outstanding receipt and pause/recovery
role evidence remains in scope. The five CLMM capability types already have compiler
construction/forwarding evidence; that does not attest transaction-input ownership.

New cases are in `packages/cetus_clmm/tests/phase1_*_tests.move`. All negatives pin abort origin
and code. Successful fixture construction precedes authorization/state mutation.
`positive-negative-reviewed.json` binds the reviewed source checks to named witnesses
and source/test hashes. The phase matrix includes properties beyond lexical assertions
(such as rejecting a nonempty close through an explicit abort).

## Verification and evidence

Full-suite logs, resolved build inputs, source/test hashes and native line/branch
reports are retained under [evidence/phase1](evidence/phase1). Hosted verification is
recorded in the original full-suite logs. See [synchronization provenance](sync-provenance.json) for original commit and path mapping. The public CI reruns this checkout.
Line/branch percentages measure Sui-mapped executable code; they do not establish
complete semantic coverage or justify silently removing remaining checks.

## Deliberate phase boundary

- Production behavior changes, new deployment/upgrade and multisig execution: excluded by the agreed phase boundary. No such changes are included.
- Historical attack recovery, migration replay, emergency reconstruction and all cross-module/cross-pool integration permutations: complex operational/integration work retained for a separate phase.
- Exhaustive tick/rounding/economic model proofs and every combination of pool creation parameters: existing tests continue running; additional exhaustive validation is lower priority than this phase's money/permission paths.
- Every remaining lexical check and every delegated helper: still shown as unreviewed unless explicitly mapped; shared guards are not counted as all entries covered.
- Transaction-input ownership/minting-policy proof: compiler visibility checks are retained, but live Sui input-resolution validation is deferred.
- New external audit coverage and public publication: separate requirements. The committed CLMM evidence is now included in this public repository; that does not supply new external audit reports.

These exclusions are not findings of safety and do not downgrade a newly discovered
critical issue. No production fix was required by this phase's passing regression
cases. This is Move/Sui regression evidence using access-control, pause/deprecation,
receipt, asset-container and accounting rules; it is not an external audit. Existing
audit-skill rules already cover these patterns; no new rule candidate.
