# CLMM positive and negative test evidence

This directory covers only `packages/cetus_clmm`. Production v15 sources and deployment inputs are unchanged by this synchronization.

- [Recovery, upgrade and signed ownership supplement](phase2-recovery-ownership.md): 28 additional tests, signed capability/position controls and a funded v14→v15 upgrade rehearsal completed 2026-10-28.
- [Phase 1 acceptance and deferred scope](phase1-acceptance.md)
- [Repayment and fee conservation](clmm-repayment-invariants.md)
- [Reviewed checks](positive-negative-reviewed.json) and [generated status](positive-negative-status.json)
- [Synchronization provenance](sync-provenance.json): original commit, file hashes and path mapping. The retained mutation log preserves its original execution paths.

The public baseline contained 343 tests. Phase 1 synchronization brought it to 549 (+206), including the final 112-test Phase 1 increment and preceding authorization/repayment additions. The ledger maps 71 of 332 lexical sites; the other 261 remain unreviewed, which does not mean they have no tests. The original every-authorization-check/every-invariant requirement remains incomplete.

## Public-checkout validation

[Phase 1 public-layout evidence](evidence/public-sync/clmm) confirms 549/549 passing tests, 94.14% line coverage and 89.55% branch coverage. [Fresh compiler controls](evidence/public-sync/capability-compile) validate all five CLMM capability types against the recorded public-repository commit. Four ledger validation tests pass.

## Reproduce

Use Sui `1.79.1-808640d9b49a` and MVR `0.1.0`. From the repository root:

```sh
python3 Audit/tools/check_inventory.py
python3 Audit/tools/positive_negative_report.py
python3 -m unittest discover -s Audit/tools -p 'test_*.py'
sui move test --path packages/cetus_clmm --build-env mainnet --trace --coverage --gas-limit 10000000000
sui move coverage lcov --path packages/cetus_clmm --build-env mainnet
python3 Audit/tools/coverage_report.py packages/cetus_clmm packages/cetus_clmm/lcov.info evidence/clmm
python3 Audit/tools/capability_compile_checks.py --commit HEAD --output evidence/capability-compile
```

Committed reports are public snapshots. CI artifacts provide commit-specific reruns and may expire. None of these materials is an independent external audit or proof that dependencies are audited.

See [evidence retention](evidence-retention.md) for the current/archive boundary.

The Phase 2 test inventory totals 577 tests. Its public CI rerun validates the unchanged public production package; the 549-test coverage percentages above remain explicitly Phase 1 measurements. Imported local receipts retain original provenance. See [Phase 2 provenance](phase2-sync-provenance.json) for public adapters and reproducible historical inputs.
