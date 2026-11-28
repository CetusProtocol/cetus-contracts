#[test_only]
#[allow(deprecated_usage)]
module cetus_clmm::bitmap_allow_tests;
use cetus_clmm::{config, pool, tick_math};
use cetus_clmm::pool_tests::{CoinA, CoinB};
use integer_mate::i32;
use sui::{clock};
use std::string;
fun check(p: &pool::Pool<CoinA, CoinB>, allowed: bool) {
 assert!(pool::is_allow_swap(p) == allowed);
 assert!(pool::is_allow_add_liquidity(p) == allowed);
 assert!(pool::is_allow_remove_liquidity(p) == allowed);
 assert!(pool::is_allow_flash_loan(p) == allowed);
 assert!(pool::is_allow_collect_fee(p) == allowed);
 assert!(pool::is_allow_collect_reward(p) == allowed);
}
#[test]
fun lifecycle_and_status_flags() {
 let mut ctx = tx_context::dummy(); let clk = clock::create_for_testing(&mut ctx);
 let (cap, mut cfg) = config::new_global_config_for_test(&mut ctx, 2000);
 config::update_package_version(&cap, &mut cfg, 16);
 config::add_role(&cap, &mut cfg, ctx.sender(), config::bitmap_migration_role());
 let mut p = pool::new_for_test<CoinA, CoinB>(1000, tick_math::get_sqrt_price_at_tick(i32::zero()), 500, string::utf8(b""), 0, &clk, &mut ctx);
 check(&p, true);
 pool::bitmap_begin(&cfg, &mut p, &ctx); check(&p, false);
 pool::bitmap_cancel_begin(&cfg, &mut p, &ctx); check(&p, false);
 pool::bitmap_cancel_batch(&cfg, &mut p, 128, &ctx);
 pool::bitmap_cancel_finish(&cfg, &mut p, &ctx); check(&p, true);
 pool::bitmap_begin(&cfg, &mut p, &ctx);
 pool::bitmap_finalize(&cfg, &mut p, &ctx); check(&p, true);
 pool::bitmap_repair_begin(&cfg, &mut p, &ctx); check(&p, false);
 pool::bitmap_repair_clear_batch(&cfg, &mut p, 128, &ctx);
 pool::bitmap_repair_clear_finish(&cfg, &mut p, &ctx); check(&p, false);
 pool::bitmap_repair_finalize(&cfg, &mut p, &ctx); check(&p, true);
 pool::set_pool_status(&cfg, &mut p, true, true, true, true, true, true, &mut ctx); check(&p, false);
 pool::set_pool_status(&cfg, &mut p, false, false, false, false, false, false, &mut ctx); check(&p, true);
 transfer::public_share_object(p); transfer::public_share_object(cfg); transfer::public_transfer(cap, ctx.sender()); clk.destroy_for_testing();
}
