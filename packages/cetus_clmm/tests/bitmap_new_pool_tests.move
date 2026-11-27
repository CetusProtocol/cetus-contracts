#[test_only]
module cetus_clmm::bitmap_new_pool_tests;
use cetus_clmm::{config, pool, tick_math};
use cetus_clmm::pool_tests::{CoinA, CoinB};
use integer_mate::i32;
use std::string;
use sui::{clock, transfer};

#[test]
fun version_gate_and_existing_pool_compatibility() {
 let mut ctx = tx_context::dummy(); let clk = clock::create_for_testing(&mut ctx);
 let (cap, mut cfg) = config::new_global_config_for_test(&mut ctx, 2000);
 config::update_package_version(&cap, &mut cfg, 15);
 let old = pool::new_with_bitmap<CoinA, CoinB>(&cfg, 1, tick_math::get_sqrt_price_at_tick(i32::zero()), 500, string::utf8(b""), 0, &clk, &mut ctx);
 let (mode, _, _, _, _, _) = pool::bitmap_status(&old); assert!(mode == 0);
 config::update_package_version(&cap, &mut cfg, 16);
 let (mode, _, _, _, _, _) = pool::bitmap_status(&old); assert!(mode == 0);
 let spacings = vector[1u32, 10, 200, 1000];
 let mut i = 0;
 while (i < spacings.length()) {
  let p = pool::new_with_bitmap<CoinA, CoinB>(&cfg, spacings[i], tick_math::get_sqrt_price_at_tick(i32::zero()), 500, string::utf8(b""), i, &clk, &mut ctx);
  let (mode, snapshot, indexed, cursor, _, _) = pool::bitmap_status(&p);
  assert!(mode == 3 && snapshot == 0 && indexed == 0 && move_stl::option_u64::is_none(&cursor));
  transfer::public_share_object(p); i = i + 1;
 };
 transfer::public_share_object(old); transfer::public_share_object(cfg);
 transfer::public_transfer(cap, ctx.sender()); clk.destroy_for_testing();
}
