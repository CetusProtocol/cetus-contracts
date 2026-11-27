# Changelog

## Nov 27, 2026 +UTC (V6)

MoveSTL was upgraded from V5 to V6 on Sui Mainnet. [Upgrade transaction](https://suiscan.xyz/mainnet/tx/H1dRraMNowXZRQmSBSZRUKZkWDgm5pdSk8af3W5MBF9t) · [Package address](Published.toml)

### Added

- Add an opt-in sparse bitmap index for the u64 skip list. The index uses dynamic fields under the existing list UID.
- Add batched migration, pre-activation cancellation, and active-index repair with resumable progress.
- Add bitmap arithmetic, migration, integrity, and boundary tests. Archive the release review and Testnet evidence. [Review](https://github.com/CetusProtocol/cetus-for-audit/blob/bf90ea71dce3786dfb3f32aace1f0b25b79ac347/move-stl/release/bitmap-upgrade/REVIEW.md) · [Testnet results](https://github.com/CetusProtocol/cetus-for-audit/blob/bf90ea71dce3786dfb3f32aace1f0b25b79ac347/move-stl/release/bitmap-upgrade/TESTNET.md)

### Changed

- Route successor and predecessor searches through the index after activation and validate candidates against the bottom links.
- Update the bottom links and index in the same transaction on bitmap inserts and removals. Existing lists enter the upgrade in Legacy mode until explicitly migrated.
- Freeze guarded operations during migration, cancellation, and repair. After activation, repair rebuilds the index from the bottom links.

### Fixed

- Reject a zero maximum level when constructing a u64 or u128 skip list, which prevents creating lists that can store unreachable nodes.
