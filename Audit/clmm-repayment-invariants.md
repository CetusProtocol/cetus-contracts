# CLMM repayment and fee conservation

Requirement remains incomplete. This increment covers actual swap/loan receipts,
not every authorization check or business invariant in CLMM.

## Exercised paths

64 new cases in `packages/cetus_clmm/tests/pool_tests.move` exercise regular and partner
flash swaps and flash loans, in both asset directions. All receipts come from
production entry calls on funded pools. Successful repayment checks:

- Pool reserves + actual outgoing assets + partner credit equal initial reserves + repayment, separately for A and B.
- Partner fees are nonzero and credited to the actual partner container.
- Real position fee collection pays the expected asset, reduces reserves by the payout, and returns zero on a second collection.

Negative cases pin both abort code and origin: one-unit underpayment/overpayment,
wrong pool, nonzero unused token, package pause/deprecation after receipt creation,
wrong partner, and passing a partner receipt with nonzero referral to plain repayment.
Twenty concrete repayment check sites are linked to positive/negative witnesses in
`positive-negative-reviewed.json`; source/test hashes prevent stale attestations.

## Validation

The current full suite passes **549/549**. [Latest coverage and inputs](evidence/public-sync/clmm) record 94.14% line and 89.55% branch coverage. Superseded 437-test snapshots were removed.
An isolated mutation drops partner fee credit in repayment; the positive partner-swap
case fails when reading the missing actual partner balance ([log](evidence/mutations/partner-credit-mutation.log)). The mutation was confined to a temporary copy.

Coverage is Sui's executable mapping, not proof of every invariant or 100% semantic coverage.

## Remaining work

Phase 1 adds permission/operation, reward settlement and position lifecycle cases; see
[its acceptance scope](phase1-acceptance.md). Exhaustive rounding/liquidity extremes,
recovery and integration combinations remain deferred. The lexical ledger is a review backlog, not a count
of missing tests. Transaction-input ownership needs separate evidence.

Scope: Move/Sui source; access control, pause/deprecation, pending receipts, asset
container constraints and accounting. No production contract changes or chain transactions.
Existing audit-skill rules cover these patterns; no additional rule candidate.
