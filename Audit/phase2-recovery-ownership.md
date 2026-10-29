# Recovery, migration and transaction ownership: local evidence

As of 2026-10-29 (local evidence completed 2026-10-28). This supplements Mysten's deferred recovery/migration and transaction-ownership requests. The feasible local scope below has executable evidence; **exhaustive historical incident replay and Met status are not claimed.** This public supplement contains CLMM evidence only.

## Recovery entry scope

| Path | Evidence added | Remaining limitation |
| --- | --- | --- |
| Eight deprecated pool entries: apply_liquidity_cut, governance_fund_injection, governance_fund_withdrawal, emergency_remove_malicious_position, emergency_restore_pool_state, pause, unpause, update_pool | Each directly invoked in normal and recovery fixtures; exact abort code and module checked (16 tests). | Rejection in v15 is not a replay or validation of historical recovery on old packages. |
| init_position_snapshot | Zero/full cut parameters succeed without changing funded pool balances or position liquidity; invalid version, missing manager, unpaused pool, >PPM and duplicate snapshot reject (7 tests). | Recovery sentinel is injected by an existing test-only helper. The ordinary v15 version setter cannot reach this sentinel; these tests model inherited historical state, not current operational reachability. |
| Global emergency unpause | Pause then recover and execute a funded exit; lower/future versions, unpaused state and replay reject (5 tests). | Does not replace historical upgrade/state migration rehearsal. |

28 new targeted Move tests pass. [Exact entry witnesses](phase2-recovery-witnesses.json) bind source and test hashes. [Logs and inputs](evidence/phase2/clmm-recovery) record the full package run (577/577 passed). The original overall completion flag remains false. The independent [public CI snapshot](evidence/phase2/public-clmm-ci) records 577/577 passing, 94.62% line (3553/3755) and 89.78% branch (1564/1742) on public commit `ee61410924a0257bf7ee987c8c166c829964f1f7`; these are mapped executable coverage metrics, not exhaustive invariant coverage.

## Signed transaction ownership

For production `config::AdminCap` and `config::set_roles`, [local-network evidence](evidence/phase2/clmm-ownership) records four controls:

1. The current holder signs a successful administrative state change.
2. Another funded account signs using its own explicit gas object and the foreign capability: the RPC transaction-input validator rejects the owner/signer mismatch; protected objects remain unchanged.
3. After a successful on-chain capability transfer, the former holder's signed call is rejected and protected objects remain unchanged.
4. The new holder signs the same administrative operation successfully.

Production modules were copied unchanged and published on a disposable local Sui network via `test-publish`; package addresses were relocated. Publication receipts and source hashes are retained. Tests execute signed calls; they do not use `dev-inspect`, `--dry-run`, `--skip-signing` or `test_scenario` impersonation. This first probe establishes AdminCap / set_roles only. The additional signed probes below cover other active protocol capabilities. Shared/frozen/wrapped custody, multisig policy and mainnet state are outside these local probes.

### Additional funded capability witnesses

- [PoolCreationCap](evidence/phase2/clmm-creation-ownership): holder registration, foreign-holder rejection, transfer, former-holder rejection, new-holder unregister/register. The transferred cap also creates an actual funded PROBE/SUI pool.
- [ProtocolFeeCollectCap and PartnerCap](evidence/phase2/clmm-funded-ownership): a production swap generates fees; current holders receive nonzero fees, foreign holders are rejected, capabilities are transferred, former holders are rejected, and new holders receive nonzero fees from a second swap. A repeated protocol fee claim aborts with pool code 33 without changing pool contents.
- `config::ProtocolFeeClaimCap` appears only as a struct declaration in current production sources: no constructor or consuming entry exists. Do not manufacture a successful current-version ownership test for this legacy type. Historical objects/old-package consumers require a separately selected historical fixture.

Reproduction after the AdminCap probe: initialize the factory once with `factory::init_manager_and_whitelist` as a pool manager, publish the isolated [PROBE coin fixture](fixtures/ownership_coin), run `tools/creation_cap_ownership_check.py`, then `tools/clmm_funded_ownership_check.py`. Each tool exposes explicit local config/evidence/output arguments via `--help`. Use a fresh fixture coin and output directory. The coin fixture is test infrastructure; it changes no protocol source or deployment input. The funded script was rerun successfully against a fresh coin publication before these receipts were recorded.

## Reproduce ownership controls

Use a fresh disposable directory and Sui 1.79.1 for the recorded local-network run. Genesis provides multiple independently funded accounts. Keep local keys outside the repository.

```sh
mkdir -p /tmp/cetus-owned-probe
sui genesis --working-dir /tmp/cetus-owned-probe --committee-size 1 --with-faucet
sui start --network.config /tmp/cetus-owned-probe --fullnode-rpc-port 19300
# In a second terminal, using that isolated client config:
sui client --client.config /tmp/cetus-owned-probe/client.yaml new-env --alias phase2 --rpc http://127.0.0.1:19300
# Copy the package sources/ and Move.toml, Move.lock, Published.toml to /tmp/package-copy.
# From a temporary working directory (ephemeral Pub.* metadata stays there):
sui client --client.config /tmp/cetus-owned-probe/client.yaml --client.env phase2 --json test-publish /tmp/package-copy --build-env mainnet --with-unpublished-dependencies --gas-budget 1000000000 > /tmp/publication.json
python3 Audit/tools/transaction_ownership_check.py --client-config /tmp/cetus-owned-probe/client.yaml --env phase2 --publication /tmp/publication.json --kind clmm --output /tmp/ownership-evidence
```

The probe requires a fresh publication, transfers its AdminCap to another genesis account, and permits only a loopback RPC endpoint. Local object IDs and transaction digests cannot be queried on mainnet.

## Historical source upgrade rehearsal — completed 2026-10-28

[Recorded evidence](evidence/phase2/clmm-upgrade) replays v14 source (`9d555db3bcc63c959f4d8506da606f217da024fd`) → current v15 source on a disposable local Sui network. [The runner](tools/clmm_upgrade_rehearsal.py) was executed from a fresh historical publication after preparing the fixture with [the extractor](tools/prepare_upgrade_fixture.py). It retains native Sui compatibility checking and publishes non-framework dependencies as separate packages.

The signed sequence establishes:

1. A real funded pool and position exist on the old package and swaps accrue fees.
2. The old protocol is paused before package upgrade; stored pool/position contents and ownership survive the upgrade. New-package claims remain blocked while paused.
3. An invalid future recovery version rejects. Recovery to v15 succeeds; calls through the old v14 package reject at its version gate.
4. The retained position claims nonzero accrued fees with matching pool balance deltas. Repeated fee collection without new settlement produces zero.
5. A foreign position holder is rejected by transaction-input validation. After a real position transfer, the former holder rejects and the new holder can claim and exit the retained principal. Exit amounts match pool balance decreases.
6. A later pause can be recovered through the new package. The old recovery function cannot restore v14 below the recorded pre-pause version floor, and replaying unpause rejects.

### Reproduction and limits

Use a fresh temporary package directory, the recorded Sui 1.79.1 toolchain, an isolated local client configuration and a fresh output directory. Keep keys outside the repository. Every tool provides its argument list with `--help`.

1. Run `python3 Audit/tools/prepare_upgrade_fixture.py --output /tmp/clmm-historical`.
2. Publish that package with `sui client ... test-publish /tmp/clmm-historical --pubfile-path /tmp/clmm-rehearsal-Pub.toml --build-env mainnet --publish-unpublished-deps --gas-budget 1000000000 --json`. Preserve the publication JSON. **Use `--publish-unpublished-deps`, not `--with-unpublished-dependencies`**: the latter bundles dependency modules into the root package and does not represent the separately published dependency upgrade topology.
3. Run the AdminCap ownership probe on the historical publication and copy its publication JSON into that probe's evidence directory. Publish the isolated PROBE coin fixture if needed.
4. Run the creation-cap probe with `--initialize-factory`, then the funded CLMM ownership probe against that historical publication.
5. Run `python3 Audit/tools/clmm_upgrade_rehearsal.py` with the old publication, AdminCap/funded evidence directories, coin publication, local client config, temporary package path and the same ephemeral pubfile. It copies the repository's current sources into that temporary package, executes the actual upgrade, verifies the transaction controls and records hashed results.

The public extractor reconstructs the recorded historical source bytes from public commit `b7c3a5ad` plus the small, hashed patch in `fixtures/clmm_v14`, and verifies every historical source hash. No access to the private commit is required. Package metadata is normalized to the current locked manifests for reproducibility; the old/current source hashes and metadata hashes are recorded. This is a source-based upgrade rehearsal on synthetic funded state, **not proof of historical mainnet bytecode or an incident snapshot**. Earlier standalone ownership probes used bundled local dependencies; this upgrade rehearsal uses separate dependency publications. Neither setup submits mainnet transactions or changes production sources/deployment inputs.

## Completion boundaries and dates

| Item | Status / date |
| --- | --- |
| Current recovery tests and active capability ownership paths described above | Implemented and locally verified, 2026-10-28 |
| v14→v15 funded source upgrade, old-gate retirement, position ownership and claims/exit | Reproduced, 2026-10-28 |
| Public full-suite CI | [Passed 2026-10-29](https://github.com/CetusProtocol/cetus-contracts/actions/runs/40812251907); durable snapshot linked above. See PR #12 for final-head checks. |
| Exact incident reconstruction or older historical deployment replay | Requires an agreed old/new deployed package lineage, actual dependency/compiler inputs, pre-recovery object/checkpoint data and expected recovery allocations. Not replaced by a test-only recovery sentinel or the synthetic upgrade fixture. |

The earlier 2026-10-30 / 2026-11-04 dates were internal planning targets. The recorded local deliverables above completed on 2026-10-28. No external completion date is promised for missing historical datasets; agree that scope and date with Mysten if exact incident replay is required. Shared/frozen/wrapped custody, multisig policy, every cross-pool permutation and exhaustive reward schedules are not established by these address-owned object probes. This is not a claim that every invariant in the full protocol has paired witnesses.

## Rules and limits

Chain: Move/Sui; source-based regression work on published protocols. Rules applied: authorization versus pause/version, capability/object ownership lifecycle, accounting/migration, locked dependencies and recovery/deprecation reachability. This is not a comprehensive new security audit. Production sources and deployment inputs are unchanged; no mainnet transaction is submitted. Candidate findings are not inferred from expected transaction rejection. Skill update dedup: existing rules cover these cases; no new rule candidate.

Toolchain note: the imported private regression used Sui 1.81.1 with its recorded framework lock. The unchanged public package retains its own Sui 1.79.1 inputs and is independently tested by public CI. The signed local-network evidence uses Sui 1.79.1 and relocated modules. Raw evidence is preserved byte-for-byte, including original paths and script hashes; public adapter hashes and mappings are in `phase2-sync-provenance.json`.
