#[test_only]
module cetus_clmm::bitmap_tests;

use cetus_clmm::tick;
use integer_mate::{i32, i128};
use move_stl::option_u64;
use sui::transfer;

public struct Holder has key { id: UID, ticks: tick::TickManager }

fun exercise_mapping(spacing: u32) {
    let ctx = &mut tx_context::dummy();
    let mut legacy = tick::new(spacing, 12, ctx);
    let mut indexed = tick::new(spacing, 12, ctx);
    let mut i = 0;
    while (i < 9) {
        let idx = i32::sub(i32::from(i * spacing), i32::from(4 * spacing));
        let value = tick::new_tick_for_test(idx, i128::from(0), 1, 0, 0, 0, vector[]);
        tick::add_ticks_for_test(&mut legacy, vector[value]);
        tick::add_ticks_for_test(&mut indexed, vector[value]);
        i = i + 1;
    };
    tick::bitmap_begin(&mut indexed);
    tick::bitmap_build_batch(&mut indexed, 128, false);
    tick::bitmap_finalize(&mut indexed);
    i = 0;
    while (i < 27) {
        let q = i32::sub(i32::from((i / 3) * spacing + (i % 3)), i32::from(4 * spacing + 1));
        assert!(tick::first_score_for_swap(&legacy, q, true) == tick::first_score_for_swap(&indexed, q, true), 0);
        assert!(tick::first_score_for_swap(&legacy, q, false) == tick::first_score_for_swap(&indexed, q, false), 1);
        i = i + 1;
    };
    let mut score = tick::first_score_for_swap(&indexed, i32::neg_from(443637), false);
    let mut count = 0;
    while (option_u64::is_some(&score)) {
        let (_, next) = tick::borrow_tick_for_swap(&indexed, option_u64::borrow(&score), false);
        score = next; count = count + 1;
    };
    assert!(count == 9, 2);
    // The test-only managers contain object UIDs; transfer the enclosing test lists.
    transfer::share_object(Holder { id: object::new(ctx), ticks: legacy });
    transfer::share_object(Holder { id: object::new(ctx), ticks: indexed });
}

#[test] fun bitmap_spacing_1() { exercise_mapping(1); }
#[test] fun bitmap_spacing_2() { exercise_mapping(2); }
#[test] fun bitmap_spacing_10() { exercise_mapping(10); }
#[test] fun bitmap_spacing_60() { exercise_mapping(60); }
#[test] fun bitmap_spacing_200() { exercise_mapping(200); }

fun economic_difference(a2b: bool, exact_in: bool, repair: bool) {
    use cetus_clmm::{config, pool, pool_tests, tick_math};
    use cetus_clmm::pool_tests::{CoinA, CoinB};
    use sui::clock;
    use std::{bcs, string};
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let (cap, mut cfg) = config::new_global_config_for_test(&mut ctx, 2000);
    config::add_role(&cap, &mut cfg, ctx.sender(), config::bitmap_migration_role());
    config::update_package_version(&cap, &mut cfg, config::package_version());
    let price = tick_math::get_sqrt_price_at_tick(i32::zero());
    let mut a = pool::new_for_test<CoinA, CoinB>(10, price, 500, string::utf8(b""), 0, &clk, &mut ctx);
    let mut b = pool::new_for_test<CoinA, CoinB>(10, price, 500, string::utf8(b""), 0, &clk, &mut ctx);
    pool_tests::add_liquidity_for_swap(&cfg, &mut a, i32::neg_from(1000), i32::from(1000), 100000000, &clk, &mut ctx);
    pool_tests::add_liquidity_for_swap(&cfg, &mut b, i32::neg_from(1000), i32::from(1000), 100000000, &clk, &mut ctx);
    let ticks_before = bcs::to_bytes(&pool::fetch_ticks(&b, vector[], 100));
    pool::bitmap_migrate_atomic(&cfg, &mut b, 128, &ctx);
    assert!(ticks_before == bcs::to_bytes(&pool::fetch_ticks(&b, vector[], 100)), 10);
    // Post-activation nodes mix with the pre-existing multi-level nodes. Shared
    // boundary at zero has net=0 and gross>0 and must still be crossed.
    pool_tests::add_liquidity_for_swap(&cfg, &mut a, i32::neg_from(100), i32::zero(), 10000000, &clk, &mut ctx);
    pool_tests::add_liquidity_for_swap(&cfg, &mut b, i32::neg_from(100), i32::zero(), 10000000, &clk, &mut ctx);
    pool_tests::add_liquidity_for_swap(&cfg, &mut a, i32::zero(), i32::from(100), 10000000, &clk, &mut ctx);
    pool_tests::add_liquidity_for_swap(&cfg, &mut b, i32::zero(), i32::from(100), 10000000, &clk, &mut ctx);
    if (repair) { pool::bitmap_repair_atomic(&cfg, &mut b, 128, &ctx); };
    // Normal users need no migration ACL after activation.
    config::remove_role(&cap, &mut cfg, ctx.sender(), config::bitmap_migration_role());
    let limit = tick_math::get_sqrt_price_at_tick(if (a2b) i32::neg_from(900) else i32::from(900));
    let (out_a, in_a) = pool_tests::swap(&mut a, &cfg, a2b, exact_in, 2000000, limit, &clk, &mut ctx);
    let (out_b, in_b) = pool_tests::swap(&mut b, &cfg, a2b, exact_in, 2000000, limit, &clk, &mut ctx);
    assert!(out_a == out_b && in_a == in_b, 11);
    assert!(pool::current_sqrt_price(&a) == pool::current_sqrt_price(&b), 12);
    assert!(pool::current_tick_index(&a) == pool::current_tick_index(&b), 13);
    assert!(pool::liquidity(&a) == pool::liquidity(&b), 14);
    let (pa, pb) = pool::protocol_fee(&a); let (qa, qb) = pool::protocol_fee(&b);
    assert!(pa == qa && pb == qb, 15);
    let (fa, fb) = pool::fees_growth_global(&a); let (ga, gb) = pool::fees_growth_global(&b);
    assert!(fa == ga && fb == gb, 16);
    assert!(bcs::to_bytes(&pool::fetch_ticks(&a, vector[], 100)) == bcs::to_bytes(&pool::fetch_ticks(&b, vector[], 100)), 17);
    let (aa, ab) = pool::balances(&a); let (ba, bb) = pool::balances(&b);
    assert!(aa.value() == ba.value() && ab.value() == bb.value(), 18);
    transfer::public_share_object(a); transfer::public_share_object(b);
    transfer::public_share_object(cfg); transfer::public_transfer(cap, ctx.sender());
    clk.destroy_for_testing();
}

#[test] fun bitmap_swap_a2b_exact_in() { economic_difference(true, true, false); }
#[test] fun bitmap_swap_a2b_exact_out() { economic_difference(true, false, false); }
#[test] fun bitmap_swap_b2a_exact_in() { economic_difference(false, true, false); }
#[test] fun bitmap_swap_b2a_exact_out() { economic_difference(false, false, false); }

#[test] fun repaired_swap_a2b_exact_in() { economic_difference(true, true, true); }

#[test] fun repaired_swap_a2b_exact_out() { economic_difference(true, false, true); }

#[test] fun repaired_swap_b2a_exact_in() { economic_difference(false, true, true); }

#[test] fun repaired_swap_b2a_exact_out() { economic_difference(false, false, true); }

#[test] fun bitmap_spacing_1000() { exercise_mapping(1000); }
