#[test_only]
module cetus_clmm::bitmap_atomic_budget_tests;
use cetus_clmm::{pool, config, tick_math};
use cetus_clmm::pool_tests::{CoinA, CoinB};
use sui::{clock, transfer};
use std::string;
use integer_mate::i32;
#[test]
fun bounds_include_sparse_words_and_state() {
 assert!(pool::bitmap_atomic_object_bound(0, 887272, 1, 0, true) == 3482);
 assert!(pool::bitmap_atomic_object_bound(0, 887272, 2, 0, true) == 1742);
 assert!(pool::bitmap_atomic_object_bound(0, 887272, 4, 0, true) == 873);
 assert!(pool::bitmap_atomic_object_bound(6, 887266, 10, 549, true) == 900);
 assert!(pool::bitmap_atomic_object_bound(6, 887266, 10, 550, true) == 901);
 assert!(pool::bitmap_atomic_object_bound(0, 887272, 1, 442, false) == 900);
 assert!(pool::bitmap_atomic_object_bound(0, 887272, 1, 443, false) == 902);
 assert!(pool::bitmap_atomic_object_bound(0, 887272, 1, 0, false) == 1);
}
fun rejected_repair(spacing: u32) {
 let mut ctx = tx_context::dummy(); let clk = clock::create_for_testing(&mut ctx);
 let (cap, mut cfg) = config::new_global_config_for_test(&mut ctx, 2000);
 config::update_package_version(&cap, &mut cfg, 16);
 config::add_role(&cap, &mut cfg, ctx.sender(), config::bitmap_migration_role());
 let mut p = pool::new_with_bitmap<CoinA, CoinB>(&cfg, spacing, tick_math::get_sqrt_price_at_tick(i32::zero()), 500, string::utf8(b""), 0, &clk, &mut ctx);
 pool::bitmap_repair_atomic(&cfg, &mut p, 1, &ctx);
 transfer::public_share_object(p); transfer::public_share_object(cfg); transfer::public_transfer(cap, ctx.sender()); clk.destroy_for_testing();
}
#[test]
#[expected_failure(abort_code = 60, location = cetus_clmm::pool)]
fun empty_spacing_one_rejected() { rejected_repair(1); }
#[test]
#[expected_failure(abort_code = 60, location = cetus_clmm::pool)]
fun empty_spacing_two_rejected() { rejected_repair(2); }
