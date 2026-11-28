#[test_only]
#[allow(deprecated_usage)]
module cetus_clmm::bitmap_lifecycle_tests;
use cetus_clmm::{config, pool, pool_tests, tick_math};
use cetus_clmm::pool_tests::{CoinA, CoinB};
use integer_mate::i32;
use move_stl::option_u64;
use sui::{clock};
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
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun begin_rejects_mode_1() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 1, &ctx);
    pool::bitmap_begin(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun begin_rejects_mode_2() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 2, &ctx);
    pool::bitmap_begin(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun begin_rejects_mode_3() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 3, &ctx);
    pool::bitmap_begin(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun begin_rejects_mode_4() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 4, &ctx);
    pool::bitmap_begin(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun begin_rejects_mode_5() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 5, &ctx);
    pool::bitmap_begin(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 2, location = cetus_clmm::tick)]
fun migrate_batch_rejects_mode_2() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 2, &ctx);
    pool::bitmap_migrate_batch(&cfg, &mut p, 1, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 2, location = cetus_clmm::tick)]
fun migrate_batch_rejects_mode_3() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 3, &ctx);
    pool::bitmap_migrate_batch(&cfg, &mut p, 1, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 2, location = cetus_clmm::tick)]
fun migrate_batch_rejects_mode_4() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 4, &ctx);
    pool::bitmap_migrate_batch(&cfg, &mut p, 1, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 2, location = cetus_clmm::tick)]
fun migrate_batch_rejects_mode_5() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 5, &ctx);
    pool::bitmap_migrate_batch(&cfg, &mut p, 1, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun finalize_rejects_mode_2() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 2, &ctx);
    pool::bitmap_finalize(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun finalize_rejects_mode_3() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 3, &ctx);
    pool::bitmap_finalize(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun finalize_rejects_mode_4() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 4, &ctx);
    pool::bitmap_finalize(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun finalize_rejects_mode_5() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 5, &ctx);
    pool::bitmap_finalize(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun cancel_begin_rejects_mode_2() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 2, &ctx);
    pool::bitmap_cancel_begin(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun cancel_begin_rejects_mode_3() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 3, &ctx);
    pool::bitmap_cancel_begin(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun cancel_begin_rejects_mode_4() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 4, &ctx);
    pool::bitmap_cancel_begin(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun cancel_begin_rejects_mode_5() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 5, &ctx);
    pool::bitmap_cancel_begin(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun cancel_batch_rejects_mode_1() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 1, &ctx);
    pool::bitmap_cancel_batch(&cfg, &mut p, 1, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun cancel_batch_rejects_mode_3() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 3, &ctx);
    pool::bitmap_cancel_batch(&cfg, &mut p, 1, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun cancel_batch_rejects_mode_4() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 4, &ctx);
    pool::bitmap_cancel_batch(&cfg, &mut p, 1, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun cancel_batch_rejects_mode_5() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 5, &ctx);
    pool::bitmap_cancel_batch(&cfg, &mut p, 1, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun cancel_finish_rejects_mode_1() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 1, &ctx);
    pool::bitmap_cancel_finish(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun cancel_finish_rejects_mode_3() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 3, &ctx);
    pool::bitmap_cancel_finish(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun cancel_finish_rejects_mode_4() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 4, &ctx);
    pool::bitmap_cancel_finish(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun cancel_finish_rejects_mode_5() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 5, &ctx);
    pool::bitmap_cancel_finish(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun repair_begin_rejects_mode_1() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 1, &ctx);
    pool::bitmap_repair_begin(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun repair_begin_rejects_mode_2() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 2, &ctx);
    pool::bitmap_repair_begin(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun repair_begin_rejects_mode_4() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 4, &ctx);
    pool::bitmap_repair_begin(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun repair_begin_rejects_mode_5() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 5, &ctx);
    pool::bitmap_repair_begin(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun repair_clear_batch_rejects_mode_1() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 1, &ctx);
    pool::bitmap_repair_clear_batch(&cfg, &mut p, 1, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun repair_clear_batch_rejects_mode_2() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 2, &ctx);
    pool::bitmap_repair_clear_batch(&cfg, &mut p, 1, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun repair_clear_batch_rejects_mode_3() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 3, &ctx);
    pool::bitmap_repair_clear_batch(&cfg, &mut p, 1, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun repair_clear_batch_rejects_mode_5() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 5, &ctx);
    pool::bitmap_repair_clear_batch(&cfg, &mut p, 1, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun repair_clear_finish_rejects_mode_1() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 1, &ctx);
    pool::bitmap_repair_clear_finish(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun repair_clear_finish_rejects_mode_2() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 2, &ctx);
    pool::bitmap_repair_clear_finish(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun repair_clear_finish_rejects_mode_3() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 3, &ctx);
    pool::bitmap_repair_clear_finish(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun repair_clear_finish_rejects_mode_5() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 5, &ctx);
    pool::bitmap_repair_clear_finish(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 2, location = cetus_clmm::tick)]
fun repair_build_batch_rejects_mode_1() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 1, &ctx);
    pool::bitmap_repair_build_batch(&cfg, &mut p, 1, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 2, location = cetus_clmm::tick)]
fun repair_build_batch_rejects_mode_2() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 2, &ctx);
    pool::bitmap_repair_build_batch(&cfg, &mut p, 1, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 2, location = cetus_clmm::tick)]
fun repair_build_batch_rejects_mode_3() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 3, &ctx);
    pool::bitmap_repair_build_batch(&cfg, &mut p, 1, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 2, location = cetus_clmm::tick)]
fun repair_build_batch_rejects_mode_4() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 4, &ctx);
    pool::bitmap_repair_build_batch(&cfg, &mut p, 1, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun repair_finalize_rejects_mode_1() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 1, &ctx);
    pool::bitmap_repair_finalize(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun repair_finalize_rejects_mode_2() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 2, &ctx);
    pool::bitmap_repair_finalize(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun repair_finalize_rejects_mode_3() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 3, &ctx);
    pool::bitmap_repair_finalize(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun repair_finalize_rejects_mode_4() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 4, &ctx);
    pool::bitmap_repair_finalize(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun repair_restart_rejects_mode_1() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 1, &ctx);
    pool::bitmap_repair_restart(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun repair_restart_rejects_mode_2() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 2, &ctx);
    pool::bitmap_repair_restart(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun repair_restart_rejects_mode_3() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 3, &ctx);
    pool::bitmap_repair_restart(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun repair_restart_rejects_mode_4() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 4, &ctx);
    pool::bitmap_repair_restart(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 14, location = move_stl::skip_list)]
fun migrate_batch_limit_0() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 1, &ctx);
    pool::bitmap_migrate_batch(&cfg, &mut p, 0, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 14, location = move_stl::skip_list)]
fun migrate_batch_limit_129() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 1, &ctx);
    pool::bitmap_migrate_batch(&cfg, &mut p, 129, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 14, location = move_stl::skip_list)]
fun cancel_batch_limit_0() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 2, &ctx);
    pool::bitmap_cancel_batch(&cfg, &mut p, 0, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 14, location = move_stl::skip_list)]
fun cancel_batch_limit_129() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 2, &ctx);
    pool::bitmap_cancel_batch(&cfg, &mut p, 129, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 14, location = move_stl::skip_list)]
fun repair_clear_batch_limit_0() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 4, &ctx);
    pool::bitmap_repair_clear_batch(&cfg, &mut p, 0, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 14, location = move_stl::skip_list)]
fun repair_clear_batch_limit_129() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 4, &ctx);
    pool::bitmap_repair_clear_batch(&cfg, &mut p, 129, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 14, location = move_stl::skip_list)]
fun repair_build_batch_limit_0() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 5, &ctx);
    pool::bitmap_repair_build_batch(&cfg, &mut p, 0, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 14, location = move_stl::skip_list)]
fun repair_build_batch_limit_129() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 5, &ctx);
    pool::bitmap_repair_build_batch(&cfg, &mut p, 129, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 60, location = cetus_clmm::pool)]
fun migrate_atomic_limit_0() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 0, &ctx);
    pool::bitmap_migrate_atomic(&cfg, &mut p, 0, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 60, location = cetus_clmm::pool)]
fun migrate_atomic_limit_769() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 0, &ctx);
    pool::bitmap_migrate_atomic(&cfg, &mut p, 769, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 60, location = cetus_clmm::pool)]
fun repair_atomic_limit_0() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 3, &ctx);
    pool::bitmap_repair_atomic(&cfg, &mut p, 0, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 60, location = cetus_clmm::pool)]
fun repair_atomic_limit_769() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 3, &ctx);
    pool::bitmap_repair_atomic(&cfg, &mut p, 769, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 60, location = cetus_clmm::pool)]
fun migrate_atomic_insufficient_budget() {
    let (cap, cfg, mut p, clk, mut ctx) = fixture();
    pool_tests::add_liquidity_for_swap(&cfg, &mut p, i32::neg_from(1000), i32::from(1000), 100000000, &clk, &mut ctx);
    enter(&cfg, &mut p, 0, &ctx);
    pool::bitmap_migrate_atomic(&cfg, &mut p, 1, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 60, location = cetus_clmm::pool)]
fun repair_atomic_insufficient_budget() {
    let (cap, cfg, mut p, clk, mut ctx) = fixture();
    pool_tests::add_liquidity_for_swap(&cfg, &mut p, i32::neg_from(1000), i32::from(1000), 100000000, &clk, &mut ctx);
    enter(&cfg, &mut p, 3, &ctx);
    pool::bitmap_repair_atomic(&cfg, &mut p, 1, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 12, location = move_stl::skip_list)]
fun finalize_incomplete() {
    let (cap, cfg, mut p, clk, mut ctx) = fixture();
    pool_tests::add_liquidity_for_swap(&cfg, &mut p, i32::neg_from(1000), i32::from(1000), 100000000, &clk, &mut ctx);
    enter(&cfg, &mut p, 1, &ctx);
    pool::bitmap_finalize(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 12, location = move_stl::skip_list)]
fun repair_finalize_incomplete() {
    let (cap, cfg, mut p, clk, mut ctx) = fixture();
    pool_tests::add_liquidity_for_swap(&cfg, &mut p, i32::neg_from(1000), i32::from(1000), 100000000, &clk, &mut ctx);
    enter(&cfg, &mut p, 5, &ctx);
    pool::bitmap_repair_finalize(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun cancel_finish_incomplete() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 2, &ctx);
    pool::bitmap_cancel_finish(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun repair_clear_finish_incomplete() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    enter(&cfg, &mut p, 4, &ctx);
    pool::bitmap_repair_clear_finish(&cfg, &mut p, &ctx);
    dispose(cap, cfg, p, clk, ctx);
}

#[test]
fun nonempty_cancel_migrate_repair_restart_preserves_economics() {
    let (cap, cfg, mut p, clk, mut ctx) = fixture();
    pool_tests::add_liquidity_for_swap(&cfg, &mut p, i32::neg_from(1000), i32::from(1000), 100000000, &clk, &mut ctx);
    let ticks = bcs::to_bytes(&pool::fetch_ticks(&p, vector[], 100));
    let original = bcs::to_bytes(&p);
    pool::bitmap_begin(&cfg, &mut p, &ctx);
    let (m, size, built, cursor, _, _) = pool::bitmap_status(&p);
    assert!(m == 1 && size == 2 && built == 0 && option_u64::is_some(&cursor), 0);
    pool::bitmap_migrate_batch(&cfg, &mut p, 1, &ctx);
    let (_, _, built, cursor, _, _) = pool::bitmap_status(&p);
    assert!(built == 1 && option_u64::is_some(&cursor), 1);
    pool::bitmap_cancel_begin(&cfg, &mut p, &ctx);
    // spacing 1000: 887 positions -> 4 leaf words + 1 summary word.
    let mut i = 0u64;
    while (i < 5) { pool::bitmap_cancel_batch(&cfg, &mut p, 1, &ctx); i = i + 1; };
    pool::bitmap_cancel_finish(&cfg, &mut p, &ctx);
    assert!(bcs::to_bytes(&p) == original, 2);
    assert!(bcs::to_bytes(&pool::fetch_ticks(&p, vector[], 100)) == ticks, 3);
    pool::bitmap_begin(&cfg, &mut p, &ctx);
    pool::bitmap_migrate_batch(&cfg, &mut p, 1, &ctx);
    pool::bitmap_migrate_batch(&cfg, &mut p, 1, &ctx);
    pool::bitmap_finalize(&cfg, &mut p, &ctx);
    let active = bcs::to_bytes(&p);
    pool::bitmap_repair_begin(&cfg, &mut p, &ctx);
    pool::bitmap_repair_clear_batch(&cfg, &mut p, 128, &ctx);
    pool::bitmap_repair_clear_finish(&cfg, &mut p, &ctx);
    pool::bitmap_repair_build_batch(&cfg, &mut p, 1, &ctx);
    pool::bitmap_repair_restart(&cfg, &mut p, &ctx);
    pool::bitmap_repair_clear_batch(&cfg, &mut p, 128, &ctx);
    pool::bitmap_repair_clear_finish(&cfg, &mut p, &ctx);
    pool::bitmap_repair_build_batch(&cfg, &mut p, 128, &ctx);
    pool::bitmap_repair_finalize(&cfg, &mut p, &ctx);
    assert!(bcs::to_bytes(&p) == active, 4);
    assert!(bcs::to_bytes(&pool::fetch_ticks(&p, vector[], 100)) == ticks, 5);
    assert!(sui::event::events_by_type<pool::BitmapMigrationEvent>().length() == 22, 6);

    dispose(cap, cfg, p, clk, ctx);
}

#[test]
fun atomic_nonempty_budget_2() {
    let (cap, cfg, mut p, clk, mut ctx) = fixture();
    pool_tests::add_liquidity_for_swap(&cfg, &mut p, i32::neg_from(1000), i32::from(1000), 100000000, &clk, &mut ctx);
    let ticks = bcs::to_bytes(&pool::fetch_ticks(&p, vector[], 100));
    pool::bitmap_migrate_atomic(&cfg, &mut p, 2, &ctx);
    pool::bitmap_repair_atomic(&cfg, &mut p, 2, &ctx);
    let (m, size, built, cursor, _, _) = pool::bitmap_status(&p);
    assert!(m == 3 && size == 2 && built == 2 && option_u64::is_none(&cursor), 0);
    assert!(bcs::to_bytes(&pool::fetch_ticks(&p, vector[], 100)) == ticks, 1);

    dispose(cap, cfg, p, clk, ctx);
}

#[test]
fun atomic_nonempty_budget_128() {
    let (cap, cfg, mut p, clk, mut ctx) = fixture();
    pool_tests::add_liquidity_for_swap(&cfg, &mut p, i32::neg_from(1000), i32::from(1000), 100000000, &clk, &mut ctx);
    let ticks = bcs::to_bytes(&pool::fetch_ticks(&p, vector[], 100));
    pool::bitmap_migrate_atomic(&cfg, &mut p, 128, &ctx);
    pool::bitmap_repair_atomic(&cfg, &mut p, 128, &ctx);
    let (m, size, built, cursor, _, _) = pool::bitmap_status(&p);
    assert!(m == 3 && size == 2 && built == 2 && option_u64::is_none(&cursor), 0);
    assert!(bcs::to_bytes(&pool::fetch_ticks(&p, vector[], 100)) == ticks, 1);

    dispose(cap, cfg, p, clk, ctx);
}

#[test]
fun atomic_nonempty_budget_768() {
    let (cap, cfg, mut p, clk, mut ctx) = fixture();
    pool_tests::add_liquidity_for_swap(&cfg, &mut p, i32::neg_from(1000), i32::from(1000), 100000000, &clk, &mut ctx);
    let ticks = bcs::to_bytes(&pool::fetch_ticks(&p, vector[], 100));
    pool::bitmap_migrate_atomic(&cfg, &mut p, 768, &ctx);
    pool::bitmap_repair_atomic(&cfg, &mut p, 768, &ctx);
    let (m, size, built, cursor, _, _) = pool::bitmap_status(&p);
    assert!(m == 3 && size == 2 && built == 2 && option_u64::is_none(&cursor), 0);
    assert!(bcs::to_bytes(&pool::fetch_ticks(&p, vector[], 100)) == ticks, 1);

    dispose(cap, cfg, p, clk, ctx);
}

#[test]
fun atomic_empty_event_sequence() {
    let (cap, cfg, mut p, clk, ctx) = fixture();
    pool::bitmap_migrate_atomic(&cfg, &mut p, 1, &ctx);
    let events = sui::event::events_by_type<pool::BitmapMigrationEvent>();
    assert!(events.length() == 2, 0);
    assert!(pool::bitmap_event_operation(events[0]) == b"begin", 1);
    assert!(pool::bitmap_event_operation(events[1]) == b"finalize", 2);
    let (mode, size, indexed, cursor, _, _) = pool::bitmap_status(&p);
    assert!(mode == 3 && size == 0 && indexed == 0 && option_u64::is_none(&cursor), 3);

    // Empty pools skip the build batch in the atomic repair as well.
    pool::bitmap_repair_atomic(&cfg, &mut p, 1, &ctx);
    let events = sui::event::events_by_type<pool::BitmapMigrationEvent>();
    assert!(events.length() == 6, 4);
    assert!(pool::bitmap_event_operation(events[2]) == b"repair_begin", 5);
    assert!(pool::bitmap_event_operation(events[3]) == b"repair_clear_batch", 6);
    assert!(pool::bitmap_event_operation(events[4]) == b"repair_clear_finish", 7);
    assert!(pool::bitmap_event_operation(events[5]) == b"repair_finalize", 8);

    dispose(cap, cfg, p, clk, ctx);
}

#[test]
fun migration_and_repair_resume_across_transactions() {
    use sui::test_scenario as scenario;
    let mut sc = scenario::begin(@0x123);
    let ctx = sc.ctx();
    let clk = clock::create_for_testing(ctx);
    let (cap, mut cfg) = config::new_global_config_for_test(ctx, 2000);
    config::add_role(&cap, &mut cfg, ctx.sender(), config::bitmap_migration_role());
    config::update_package_version(&cap, &mut cfg, config::package_version());
    let mut p = pool::new_for_test<CoinA, CoinB>(1000, tick_math::get_sqrt_price_at_tick(i32::zero()), 500, string::utf8(b""), 0, &clk, ctx);
    pool_tests::add_liquidity_for_swap(&cfg, &mut p, i32::neg_from(1000), i32::from(1000), 100000000, &clk, ctx);
    let ticks = bcs::to_bytes(&pool::fetch_ticks(&p, vector[], 100));
    transfer::public_share_object(p); transfer::public_share_object(cfg);
    transfer::public_transfer(cap, ctx.sender()); clk.destroy_for_testing();
    let expected_modes = vector[1, 1, 1, 3, 4, 4, 5, 5, 5, 3];
    let expected_counts = vector[0, 1, 2, 2, 2, 2, 0, 1, 2, 2];
    let mut step = 0;
    while (step < 10) {
        sc.next_tx(@0x123);
        let cfg = sc.take_shared<config::GlobalConfig>();
        let mut p = sc.take_shared<pool::Pool<CoinA, CoinB>>();
        if (step == 0) { pool::bitmap_begin(&cfg, &mut p, sc.ctx()); }
        else if (step <= 2) { pool::bitmap_migrate_batch(&cfg, &mut p, 1, sc.ctx()); }
        else if (step == 3) { pool::bitmap_finalize(&cfg, &mut p, sc.ctx()); }
        else if (step == 4) { pool::bitmap_repair_begin(&cfg, &mut p, sc.ctx()); }
        else if (step == 5) { pool::bitmap_repair_clear_batch(&cfg, &mut p, 128, sc.ctx()); }
        else if (step == 6) { pool::bitmap_repair_clear_finish(&cfg, &mut p, sc.ctx()); }
        else if (step <= 8) { pool::bitmap_repair_build_batch(&cfg, &mut p, 1, sc.ctx()); }
        else { pool::bitmap_repair_finalize(&cfg, &mut p, sc.ctx()); };
        let (mode, size, count, cursor, _, _) = pool::bitmap_status(&p);
        assert!(mode == expected_modes[step] && size == 2 && count == expected_counts[step], 0);
        if (step == 1 || step == 7) { assert!(option_u64::is_some(&cursor), 1); };
        if (step == 3 || step == 9) {
            assert!(bcs::to_bytes(&pool::fetch_ticks(&p, vector[], 100)) == ticks, 2);
        };
        scenario::return_shared(p); scenario::return_shared(cfg);
        step = step + 1;
    };
    sc.end();
}

public fun fixture(): (config::AdminCap, config::GlobalConfig, pool::Pool<CoinA, CoinB>, clock::Clock, TxContext) {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let (cap, mut cfg) = config::new_global_config_for_test(&mut ctx, 2000);
    config::add_role(&cap, &mut cfg, ctx.sender(), config::bitmap_migration_role());
    config::update_package_version(&cap, &mut cfg, config::package_version());
    let p = pool::new_for_test<CoinA, CoinB>(1000, tick_math::get_sqrt_price_at_tick(i32::zero()), 500, string::utf8(b""), 0, &clk, &mut ctx);
    (cap, cfg, p, clk, ctx)
}

public fun dispose(cap: config::AdminCap, cfg: config::GlobalConfig, p: pool::Pool<CoinA, CoinB>, clk: clock::Clock, ctx: TxContext) {
    transfer::public_share_object(p); transfer::public_share_object(cfg);
    transfer::public_transfer(cap, ctx.sender()); clk.destroy_for_testing();
}
