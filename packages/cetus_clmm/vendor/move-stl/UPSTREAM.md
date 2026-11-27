The baseline comes from [CetusProtocol/move-stl at `0681fec`](https://github.com/CetusProtocol/move-stl/tree/0681fec63a310ae753d03a06f7c05d3e2925bb09), the `mainnet-v1.3.0` release pinned by DLMM. The bitmap implementation comes from `cetus-clmm-sui` commit `9e891f2` (PR #71).

The upgrade adds format-1 bitmap storage and migration, cancellation, and repair in `skip_list.move`, with word arithmetic in `bitmap_math.move`. Both skip-list constructors now reject zero maximum levels. The layout of every existing struct and the signature of every existing public function match the Mainnet v5 package.

The existing Mainnet lineage was upgraded to V6 on November 27, 2026. Downstream packages must resolve V6 and enforce their version gates before enabling bitmap mode on shared state. [Publication records](Published.toml) · [Release review](release/bitmap-upgrade/REVIEW.md)
