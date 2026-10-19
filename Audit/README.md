# CLMM positive and negative test evidence

This directory covers only `packages/cetus_clmm`. Production v15 sources and deployment inputs are unchanged by this synchronization.

- [Phase 1 acceptance and deferred scope](phase1-acceptance.md)
- [Repayment and fee conservation](clmm-repayment-invariants.md)
- [Reviewed checks](positive-negative-reviewed.json) and [generated status](positive-negative-status.json)
- [Full-suite historical evidence](evidence/phase1/clmm): 549 passing tests; 3,535/3,755 lines (94.14%) and 1,560/1,742 branches (89.55%).
- [Capability compiler evidence](evidence/capability-compile-checks): five CLMM capability types; forwarding succeeds and external construction fails. This does not prove transaction-input ownership.
- [Synchronization provenance](sync-provenance.json): original commit, file hashes and path mapping. Historical evidence retains original paths; it is not presented as execution of this public checkout.

The public baseline contained 343 tests. Synchronization brings it to 549 (+206), including the final 112-test Phase 1 increment and preceding authorization/repayment additions. The ledger maps 71 of 332 lexical sites; the other 261 remain unreviewed, which does not mean they have no tests. The original every-authorization-check/every-invariant requirement remains incomplete.

## Public-checkout validation

[Fresh public-layout evidence](evidence/public-sync/clmm) confirms 549/549 passing tests, 94.14% line coverage and 89.55% branch coverage. [Fresh compiler controls](evidence/public-sync/capability-compile) validate all five CLMM capability types against the recorded public-repository commit. Four ledger validation tests pass.

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
