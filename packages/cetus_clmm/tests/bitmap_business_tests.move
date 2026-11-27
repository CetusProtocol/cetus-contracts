#[test_only]
module cetus_clmm::bitmap_business_tests;
use cetus_clmm::{config, pool, pool_tests, tick_math};
use cetus_clmm::bitmap_lifecycle_tests::{fixture, dispose};
use cetus_clmm::pool_tests::{CoinA, CoinB};
use integer_mate::i32;
use move_stl::option_u64;
use sui::{clock, transfer};
use std::{string, bcs};

fun enter(cfg: &config::GlobalConfig, p: &mut pool::Pool<CoinA, CoinB>, mode: u8, ctx: &TxContext) {
    if (mode == 0) { return };
    pool::bitmap_begin(cfg, p, ctx);
    if (mode == 1) { return };
    if (mode == 2) { pool::bitmap_cancel_begin(cfg, p, ctx); return };
    pool::bitmap_migrate_batch(cfg, p, 128, ctx);
    pool::bitmap_finalize(cfg, p, ctx);
    if (mode == 3) { return };
    pool::bitmap_repair_begin(cfg, p, ctx);
    if (mode == 4) { return };
    pool::bitmap_repair_clear_batch(cfg, p, 128, ctx);
    pool::bitmap_repair_clear_finish(cfg, p, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_1_add_liquidity() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 1, &ctx);
    let receipt = pool::add_liquidity(&cfg, &mut p, &mut pos, 1, &clk);
    let (a, b) = pool::add_liquidity_pay_amount(&receipt);
    pool::repay_add_liquidity(&cfg, &mut p, sui::balance::create_for_testing<CoinA>(a), sui::balance::create_for_testing<CoinB>(b), receipt);

    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_1_add_liquidity_fix_coin() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 1, &ctx);
    let receipt = pool::add_liquidity_fix_coin(&cfg, &mut p, &mut pos, 1, true, &clk);
    let (a, b) = pool::add_liquidity_pay_amount(&receipt);
    pool::repay_add_liquidity(&cfg, &mut p, sui::balance::create_for_testing<CoinA>(a), sui::balance::create_for_testing<CoinB>(b), receipt);

    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_1_remove_liquidity() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 1, &ctx);
    let (a,b) = pool::remove_liquidity(&cfg, &mut p, &mut pos, 1, &clk); a.destroy_for_testing(); b.destroy_for_testing();
    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_1_remove_with_slippage() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 1, &ctx);
    let (a,b) = pool::remove_liquidity_with_slippage(&cfg, &mut p, &mut pos, 1, 0, 0, &clk); a.destroy_for_testing(); b.destroy_for_testing();
    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_1_collect_fee() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 1, &ctx);
    let (a,b) = pool::collect_fee(&cfg, &mut p, &pos, true); a.destroy_for_testing(); b.destroy_for_testing();
    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_1_set_pool_status() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 1, &ctx);
    pool::set_pool_status(&cfg, &mut p, true, true, true, true, true, true, &mut ctx);
    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_1_swap() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 1, &ctx);
    pool_tests::swap(&mut p, &cfg, true, true, 1, tick_math::get_sqrt_price_at_tick(i32::neg_from(1000)), &clk, &mut ctx);
    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_1_close_position() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 1, &ctx);
    pool::close_position(&cfg, &mut p, pos);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_2_add_liquidity() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 2, &ctx);
    let receipt = pool::add_liquidity(&cfg, &mut p, &mut pos, 1, &clk);
    let (a, b) = pool::add_liquidity_pay_amount(&receipt);
    pool::repay_add_liquidity(&cfg, &mut p, sui::balance::create_for_testing<CoinA>(a), sui::balance::create_for_testing<CoinB>(b), receipt);

    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_2_add_liquidity_fix_coin() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 2, &ctx);
    let receipt = pool::add_liquidity_fix_coin(&cfg, &mut p, &mut pos, 1, true, &clk);
    let (a, b) = pool::add_liquidity_pay_amount(&receipt);
    pool::repay_add_liquidity(&cfg, &mut p, sui::balance::create_for_testing<CoinA>(a), sui::balance::create_for_testing<CoinB>(b), receipt);

    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_2_remove_liquidity() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 2, &ctx);
    let (a,b) = pool::remove_liquidity(&cfg, &mut p, &mut pos, 1, &clk); a.destroy_for_testing(); b.destroy_for_testing();
    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_2_remove_with_slippage() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 2, &ctx);
    let (a,b) = pool::remove_liquidity_with_slippage(&cfg, &mut p, &mut pos, 1, 0, 0, &clk); a.destroy_for_testing(); b.destroy_for_testing();
    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_2_collect_fee() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 2, &ctx);
    let (a,b) = pool::collect_fee(&cfg, &mut p, &pos, true); a.destroy_for_testing(); b.destroy_for_testing();
    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_2_set_pool_status() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 2, &ctx);
    pool::set_pool_status(&cfg, &mut p, true, true, true, true, true, true, &mut ctx);
    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_2_swap() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 2, &ctx);
    pool_tests::swap(&mut p, &cfg, true, true, 1, tick_math::get_sqrt_price_at_tick(i32::neg_from(1000)), &clk, &mut ctx);
    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_2_close_position() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 2, &ctx);
    pool::close_position(&cfg, &mut p, pos);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_4_add_liquidity() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 4, &ctx);
    let receipt = pool::add_liquidity(&cfg, &mut p, &mut pos, 1, &clk);
    let (a, b) = pool::add_liquidity_pay_amount(&receipt);
    pool::repay_add_liquidity(&cfg, &mut p, sui::balance::create_for_testing<CoinA>(a), sui::balance::create_for_testing<CoinB>(b), receipt);

    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_4_add_liquidity_fix_coin() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 4, &ctx);
    let receipt = pool::add_liquidity_fix_coin(&cfg, &mut p, &mut pos, 1, true, &clk);
    let (a, b) = pool::add_liquidity_pay_amount(&receipt);
    pool::repay_add_liquidity(&cfg, &mut p, sui::balance::create_for_testing<CoinA>(a), sui::balance::create_for_testing<CoinB>(b), receipt);

    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_4_remove_liquidity() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 4, &ctx);
    let (a,b) = pool::remove_liquidity(&cfg, &mut p, &mut pos, 1, &clk); a.destroy_for_testing(); b.destroy_for_testing();
    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_4_remove_with_slippage() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 4, &ctx);
    let (a,b) = pool::remove_liquidity_with_slippage(&cfg, &mut p, &mut pos, 1, 0, 0, &clk); a.destroy_for_testing(); b.destroy_for_testing();
    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_4_collect_fee() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 4, &ctx);
    let (a,b) = pool::collect_fee(&cfg, &mut p, &pos, true); a.destroy_for_testing(); b.destroy_for_testing();
    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_4_set_pool_status() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 4, &ctx);
    pool::set_pool_status(&cfg, &mut p, true, true, true, true, true, true, &mut ctx);
    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_4_swap() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 4, &ctx);
    pool_tests::swap(&mut p, &cfg, true, true, 1, tick_math::get_sqrt_price_at_tick(i32::neg_from(1000)), &clk, &mut ctx);
    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_4_close_position() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 4, &ctx);
    pool::close_position(&cfg, &mut p, pos);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_5_add_liquidity() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 5, &ctx);
    let receipt = pool::add_liquidity(&cfg, &mut p, &mut pos, 1, &clk);
    let (a, b) = pool::add_liquidity_pay_amount(&receipt);
    pool::repay_add_liquidity(&cfg, &mut p, sui::balance::create_for_testing<CoinA>(a), sui::balance::create_for_testing<CoinB>(b), receipt);

    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_5_add_liquidity_fix_coin() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 5, &ctx);
    let receipt = pool::add_liquidity_fix_coin(&cfg, &mut p, &mut pos, 1, true, &clk);
    let (a, b) = pool::add_liquidity_pay_amount(&receipt);
    pool::repay_add_liquidity(&cfg, &mut p, sui::balance::create_for_testing<CoinA>(a), sui::balance::create_for_testing<CoinB>(b), receipt);

    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_5_remove_liquidity() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 5, &ctx);
    let (a,b) = pool::remove_liquidity(&cfg, &mut p, &mut pos, 1, &clk); a.destroy_for_testing(); b.destroy_for_testing();
    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_5_remove_with_slippage() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 5, &ctx);
    let (a,b) = pool::remove_liquidity_with_slippage(&cfg, &mut p, &mut pos, 1, 0, 0, &clk); a.destroy_for_testing(); b.destroy_for_testing();
    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_5_collect_fee() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 5, &ctx);
    let (a,b) = pool::collect_fee(&cfg, &mut p, &pos, true); a.destroy_for_testing(); b.destroy_for_testing();
    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_5_set_pool_status() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 5, &ctx);
    pool::set_pool_status(&cfg, &mut p, true, true, true, true, true, true, &mut ctx);
    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_5_swap() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 5, &ctx);
    pool_tests::swap(&mut p, &cfg, true, true, 1, tick_math::get_sqrt_price_at_tick(i32::neg_from(1000)), &clk, &mut ctx);
    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 13, location = move_stl::skip_list)]
fun frozen_5_close_position() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 5, &ctx);
    pool::close_position(&cfg, &mut p, pos);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 35, location = cetus_clmm::pool)]
fun begin_pending_liquidity() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 0, &ctx);
    let receipt = pool::add_liquidity(&cfg, &mut p, &mut pos, 10000, &clk);
    pool::bitmap_begin(&cfg, &mut p, &ctx);
    let (a, b) = pool::add_liquidity_pay_amount(&receipt);
    pool::repay_add_liquidity(&cfg, &mut p, sui::balance::create_for_testing<CoinA>(a), sui::balance::create_for_testing<CoinB>(b), receipt);
    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 35, location = cetus_clmm::pool)]
fun migrate_atomic_pending_liquidity() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 0, &ctx);
    let receipt = pool::add_liquidity(&cfg, &mut p, &mut pos, 10000, &clk);
    pool::bitmap_migrate_atomic(&cfg, &mut p, 128, &ctx);
    let (a, b) = pool::add_liquidity_pay_amount(&receipt);
    pool::repay_add_liquidity(&cfg, &mut p, sui::balance::create_for_testing<CoinA>(a), sui::balance::create_for_testing<CoinB>(b), receipt);
    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 35, location = cetus_clmm::pool)]
fun repair_begin_pending_liquidity() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 3, &ctx);
    let receipt = pool::add_liquidity(&cfg, &mut p, &mut pos, 10000, &clk);
    pool::bitmap_repair_begin(&cfg, &mut p, &ctx);
    let (a, b) = pool::add_liquidity_pay_amount(&receipt);
    pool::repay_add_liquidity(&cfg, &mut p, sui::balance::create_for_testing<CoinA>(a), sui::balance::create_for_testing<CoinB>(b), receipt);
    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 35, location = cetus_clmm::pool)]
fun repair_atomic_pending_liquidity() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    enter(&cfg, &mut p, 3, &ctx);
    let receipt = pool::add_liquidity(&cfg, &mut p, &mut pos, 10000, &clk);
    pool::bitmap_repair_atomic(&cfg, &mut p, 128, &ctx);
    let (a, b) = pool::add_liquidity_pay_amount(&receipt);
    pool::repay_add_liquidity(&cfg, &mut p, sui::balance::create_for_testing<CoinA>(a), sui::balance::create_for_testing<CoinB>(b), receipt);
    transfer::public_transfer(pos, ctx.sender());
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
fun remove_last_ticks_and_reinsert_after_repair() {
    let (cap, mut cfg, mut p, clk, mut ctx) = fixture();
    let mut pos = pool::open_position(&cfg, &mut p, i32::as_u32(i32::neg_from(1000)), 1000, &mut ctx);
    pool_tests::add_liquidity(&cfg, &mut p, &mut pos, 10000, &clk);
    pool::bitmap_migrate_atomic(&cfg, &mut p, 2, &ctx);
    pool::bitmap_repair_atomic(&cfg, &mut p, 2, &ctx);
    config::remove_role(&cap, &mut cfg, ctx.sender(), config::bitmap_migration_role());
    let (a,b) = pool::remove_liquidity(&cfg, &mut p, &mut pos, 10000, &clk);
    a.destroy_for_testing(); b.destroy_for_testing();
    assert!(pool::fetch_ticks(&p, vector[], 100).is_empty(), 0);
    let (m, _, indexed, _, _, _) = pool::bitmap_status(&p);
    assert!(m == 3 && indexed == 0, 1);
    pool_tests::add_liquidity(&cfg, &mut p, &mut pos, 10000, &clk);
    assert!(pool::fetch_ticks(&p, vector[], 100).length() == 2, 2);
    let (_, _, indexed, _, _, _) = pool::bitmap_status(&p);
    assert!(indexed == 2, 3);
    let (a,b) = pool::remove_liquidity(&cfg, &mut p, &mut pos, 10000, &clk);
    a.destroy_for_testing(); b.destroy_for_testing();
    let (a,b) = pool::collect_fee(&cfg, &mut p, &pos, true);
    a.destroy_for_testing(); b.destroy_for_testing();
    pool::close_position(&cfg, &mut p, pos);

    dispose(cap, cfg, p, clk, ctx);
}
