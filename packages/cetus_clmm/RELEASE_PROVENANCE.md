# CLMM v16 release provenance

- Upstream: CetusProtocol/cetus-clmm-sui, commit `122bca5ccd5e2ad56fea77793eb1116954d43845`, path `cetus_clmm`.
- Mainnet package: `0x276cc3060ce52f746c711627dcc72fb859d75f0f31f6a0ed4cfe0ff32c7fdacd` (package v16).
- Upgrade transaction: `rcb6qN9evdcWiJ1KjfTLbeYkmDLfPwewS13zJ462E3K`.
- Snapshot date: 2026-11-27.
- Sui: `1.81.1-e04cf9aa915c`.

Publication metadata and vendored MoveSTL were refreshed to match deployed linkage (MoveSTL source: CetusProtocol/cetus-for-audit at bf90ea71dce3786dfb3f32aace1f0b25b79ac347). Production Move sources match upstream. Existing public recovery regression tests are retained. Source verification succeeded against mainnet; the public suite passed 819/819 tests. This does not establish runtime activation, per-pool bitmap migration or new external audit coverage.

The historical v15 scope, Phase 1/2 receipts and coverage remain available under [Audit](../../Audit/README.md), with their original version boundaries. Reproduce current validation using:

```sh
sui client verify-source . --build-env mainnet --toolchain "$(command -v sui)"
sui move test --build-env mainnet --gas-limit 10000000000
```

MoveSTL production implementation comes from `CetusProtocol/cetus-for-audit` commit `bf90ea71dce3786dfb3f32aace1f0b25b79ac347`, path `move-stl`. Two `#[test_only]` corruption helpers from the CLMM vendored snapshot are retained for regression tests; they do not enter production bytecode.
