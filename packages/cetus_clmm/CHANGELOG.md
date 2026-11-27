# Changelog

## 2026-11-27 — Mainnet V16

### Version and compatibility
- Increase the CLMM business version from 15 to 16. Activate the stored GlobalConfig version only after package and integration linkage verification.
- Automatically initialize Bitmap for pools created through the upgraded factory when the stored version is at least 16. Existing pools remain Legacy until explicitly migrated; migration is optional and their degeneration risk persists until completion.
- Preserve existing pool and tick storage layouts. Upgrade the existing MoveSTL lineage before deploying CLMM with the new dependency.

### Bitmap maintenance
- Add authorized migration, cancellation before activation, and resumable repair operations, with progress events and fixed tick-spacing mappings.
- Freeze ordinary pool operations during maintenance and reflect the freeze in all six is_allow predicates.
- Add conservative atomic object-budget checks. Spacing 1/2 repair requires batching; batch limits are 1..128, and atomic max_ticks cannot exceed 768.
- Validate tick identity, bottom-chain neighbors, sparse words, and index consistency.

### Fee handling and integrations
- Reject flash swaps and flash loans while an add-liquidity receipt remains unpaid.
- Allocate zero-active-liquidity flash-loan fees to the protocol, with partner referral accounting applied afterward.
- Document caller-enforced amount bounds and exact-output rounding considerations for router operations.

### Verification and release evidence
- Add bitmap boundary, lifecycle, permission, accounting, and business-operation regression tests.
- Archive historical Testnet and mainnet-snapshot validation reports, including the 1,108-tick batched migration scenario.
- Mainnet package v16 is published; see [release provenance](RELEASE_PROVENANCE.md) for its package ID, upgrade transaction and verification. Publication is separate from runtime activation and per-pool migration.
- See the [upstream release readiness snapshot](https://github.com/CetusProtocol/cetus-clmm-sui/blob/122bca5ccd5e2ad56fea77793eb1116954d43845/cetus_clmm/Audit/bitmap-v16-release-readiness.md) for the historical pre-release review and deployment requirements.


## (2024-10-28)
- Online Version: 8

### `config` Module Updates
- Add `is_pool_manager` public method

### `factory` Module Updates
### New Share Objects & Structs
- Share Objects:
  - `DenyCoinList`
  - `PermissionPairManager`
- Structs:
  - `PoolKey`
  - `PoolCreationCap`

### New Events
- DenyCoinList Events:
  - `AddAllowedListEvent`
  - `RemoveAllowedListEvent`
  - `AddDeniedListEvent`
  - `RemoveDeniedListEvent`
- Permission Pair Events:
  - `InitPermissionPairManagerEvent`
  - `RegisterPermissionPairEvent`
  - `UnregisterPermissionPairEvent`
  - `AddAllowedPairConfigEvent`
  - `RemoveAllowedPairConfigEvent`
- PoolCreationCap Events:
  - `MintPoolCreationCap`
  - `MintPoolCreationCapByAdmin`

### New Methods
#### Public Methods
- Init Entry Function:
  - `init_manager_and_whitelist`
- DenyCoinList Management:
  - `in_allowed_list`
  - `in_denied_list`
  - `is_allowed_coin`
  - `add_allowed_list`
  - `remove_allowed_list`
  - `add_denied_list`
  - `remove_denied_list`
- Pool Creation:
  - `permission_pair_cap`
  - `is_permission_pair`
  - `add_allowed_pair_config`
  - `remove_allowed_pair_config`
  - `mint_pool_creation_cap`
  - `mint_pool_creation_cap_by_admin`
  - `register_permission_pair`
  - `unregister_permission_pair`

#### Private Methods
- `add_denied_coin`
- `unregister_permission_pair_internal`
- `register_permission_pair_internal`
- `create_pool_v2_internal`

#### New public(friend) Methods
- `create_pool_v2_`

### Method Changes
- Modified `create_pool` to require permission
- Deprecated `create_pool_with_liquidity`

## New Module
### `pool_creator` Module
- Add `create_pool_v2_by_creation_cap` method
- Add `create_pool_v2` method

## Breaking Changes & Migration Guide
### Deprecated Methods
The `create_pool_with_liquidity` method has been deprecated. Instead, users should:
- For registered pools: Use `create_pool_v2_by_creation_cap` method
- For non-registered pools: Use `create_pool_v2` method

### New Requirements
- Mandatory full-range liquidity provision for new pool creation
- Token issuers can register pool creation permissions by specified with quote coin and tick_spacing
- All pool creation functionality has been migrated to the new `pool_creator` module
- Users should update their integration to use the new v2 methods

## 2024-11-20
- Online Version: 9

### Added
* Add amount check to `create_pool_v2`
* Performed code optimizations
* Added new event `CollectRewardV2Event` to pool module
* No longer enforce the full-range liquidity constraint in the pool creation process.
* Deprecated `create_pool_v2_by_creation_cap` method and implemented new method `create_pool_v2_with_creation_cap`. The `create_pool_v2` method is no longer intended for manager use.


## 2025-02-07
- Online Version: 10
### Added
- Support flash loan

- Reward num per pool up to 5

### Changed

- Ignore remaining rewarder check when update_emission if new emission speed slower than old

```
    public(friend) fun update_emission<CoinType>(
        vault: &RewarderGlobalVault,
        manager: &mut RewarderManager,
        liquidity: u128,
        emissions_per_second: u128,
        timestamp: u64,
    ) {
        ...
        let old_emission = rewarder.emissions_per_second;
        if (emissions_per_second > 0 && emissions_per_second > old_emission) {
          ...
        }
        rewarder.emissions_per_second = emissions_per_second;
    }
```
### Optimized
- Optimized gas by adding a check to return early if current_sqrt_price == target_sqrt_price.

```rust
    if (liquidity == 0 || current_sqrt_price == target_sqrt_price) {
        return (
            amount_in,
            amount_out,
            next_sqrt_price,
            fee_amount,
        )
    };
    if (a2b) {
        assert!(current_sqrt_price > target_sqrt_price, EINVALID_SQRT_PRICE_INPUT)
    } else {
        assert!(current_sqrt_price < target_sqrt_price, EINVALID_SQRT_PRICE_INPUT)
    };
```

### Fixed
### Security


## 2025-03-20
- Online Version: 11

Update `inter-mate` library version
### Added
### Changed

### Fixed
### Security


## 2025-06-02
- Online Version: 12
### Added
- Add `ProtocolFeeCollectCap`
- Add `collect_protocol_fee_v2` method
- Add pool restore related methods
- Add Fine-Grained Pool Controls, add `PoolStatus` struct
### Changed
- Update `clmm_math.get_liquidity_by_amount` method

### Fixed
### Security

## 2025-09-12
- Online Version: 13
### Added
- Add `AddLiquidityV2Event`, `RemoveLiquidityV2Event`
- Fix asymptotic audit
- Add `remove_liquidity_with_slippage`

## 2025-10-15
- Online Version: 14
# Added
- Add partner.`claim_ref_fee_coin`
- Add pool_creator.`create_pool_v2_with_creation_cap`
- Add pool_creator.`create_pool_v3`
- Add factory.`create_pool_v3_`
### Changed
- Fix `AddLiquidityV2Event`

## 2026-09-10
- Online Version: 15

### Security
- Split global emergency pause and unpause permissions. Legacy ACL bit 5 is retained for unpause, while the new ACL bit 6 grants pause-only access.
- Add regression tests proving pause-only accounts cannot unpause and unpause-only accounts cannot pause.
