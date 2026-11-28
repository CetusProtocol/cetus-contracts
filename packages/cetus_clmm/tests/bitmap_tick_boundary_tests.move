#[test_only]
module cetus_clmm::bitmap_tick_boundary_tests;
use cetus_clmm::tick;
use integer_mate::{i32, i128};
use move_stl::option_u64::{some, none};

// Retain test managers in a local wrapper so all object resources are consumed.
public struct TickHolder has key { id: UID, manager: tick::TickManager }
fun dispose(manager: tick::TickManager, ctx: &mut TxContext) {
    transfer::share_object(TickHolder { id: object::new(ctx), manager });
}
fun value(idx: u32): tick::Tick {
    tick::new_tick_for_test(i32::from(idx), i128::from(0), 1, 0, 0, 0, vector[])
}

#[test]
#[expected_failure(abort_code = 11, location = move_stl::skip_list)]
fun changed_spacing_rejects_mapping() {
    let mut ctx = tx_context::dummy(); let mut m = tick::new(10, 12, &mut ctx);
    tick::bitmap_begin(&mut m);
    tick::bitmap_set_spacing_for_test(&mut m, 20);
    tick::bitmap_check_mapping(&m);
    dispose(m, &mut ctx);
}

#[test]
#[expected_failure(abort_code = 2, location = cetus_clmm::tick)]
fun migration_rejects_tick_key_mismatch() {
    let mut ctx = tx_context::dummy(); let mut m = tick::new(10, 12, &mut ctx);
    tick::bitmap_insert_tick_at_score_for_test(&mut m, 443636, value(10));
    tick::bitmap_begin(&mut m);
    tick::bitmap_build_batch(&mut m, 1, false);
    dispose(m, &mut ctx);
}

#[test]
#[expected_failure(abort_code = 2, location = cetus_clmm::tick)]
fun repair_rejects_tick_key_mismatch() {
    let mut ctx = tx_context::dummy(); let mut m = tick::new(1000, 12, &mut ctx);
    tick::bitmap_begin(&mut m); tick::bitmap_finalize(&mut m);
    tick::bitmap_insert_tick_at_score_for_test(&mut m, 443636, value(1000));
    tick::bitmap_repair_begin(&mut m); tick::bitmap_repair_clear_batch(&mut m, 128);
    tick::bitmap_repair_clear_finish(&mut m);
    tick::bitmap_build_batch(&mut m, 1, true);
    dispose(m, &mut ctx);
}

#[test]
#[expected_failure(abort_code = 2, location = cetus_clmm::tick)]
fun crossing_rejects_current_tick_key_mismatch() {
    let mut ctx = tx_context::dummy(); let mut m = tick::new(10, 12, &mut ctx);
    tick::bitmap_begin(&mut m); tick::bitmap_finalize(&mut m);
    tick::bitmap_insert_tick_at_score_for_test(&mut m, 443636, value(10));
    tick::borrow_tick_for_swap(&m, 443636, true);
    dispose(m, &mut ctx);
}

#[test]
#[expected_failure(abort_code = 2, location = cetus_clmm::tick)]
fun crossing_rejects_next_tick_key_mismatch() {
    let mut ctx = tx_context::dummy(); let mut m = tick::new(10, 12, &mut ctx);
    tick::bitmap_begin(&mut m); tick::bitmap_finalize(&mut m);
    tick::add_ticks_for_test(&mut m, vector[value(0)]);
    tick::bitmap_insert_tick_at_score_for_test(&mut m, 443646, value(20));
    tick::borrow_tick_for_swap(&m, 443636, false);
    dispose(m, &mut ctx);
}

#[test]
#[expected_failure(abort_code = 11, location = move_stl::skip_list)]
fun migration_rejects_unaligned_tick() {
    let mut ctx = tx_context::dummy(); let mut m = tick::new(10, 12, &mut ctx);
    tick::add_ticks_for_test(&mut m, vector[value(1)]);
    tick::bitmap_begin(&mut m); tick::bitmap_build_batch(&mut m, 1, false);
    dispose(m, &mut ctx);
}

fun aligned_endpoints(spacing: u32) {
    let mut ctx = tx_context::dummy(); let mut m = tick::new(spacing, 12, &mut ctx);
    let aligned = 443636 / spacing * spacing;
    let lo = i32::neg_from(aligned); let hi = i32::from(aligned);
    tick::add_ticks_for_test(&mut m, vector[
        tick::new_tick_for_test(lo, i128::from(0), 1, 0, 0, 0, vector[]), value(aligned)
    ]);
    tick::bitmap_begin(&mut m); tick::bitmap_build_batch(&mut m, 128, false);
    tick::bitmap_finalize(&mut m); tick::bitmap_check_mapping(&m);
    let low = 443636 - (aligned as u64); let high = 443636 + (aligned as u64);
    assert!(tick::first_score_for_swap(&m, i32::neg_from(443637), false) == some(low), 0);
    assert!(tick::first_score_for_swap(&m, lo, true) == some(low), 1);
    assert!(tick::first_score_for_swap(&m, lo, false) == some(high), 2);
    assert!(tick::first_score_for_swap(&m, hi, true) == some(high), 3);
    assert!(tick::first_score_for_swap(&m, hi, false) == none(), 4);
    let (_, next) = tick::borrow_tick_for_swap(&m, low, false); assert!(next == some(high), 5);
    let (_, prev) = tick::borrow_tick_for_swap(&m, high, true); assert!(prev == some(low), 6);
    let (_, prev) = tick::borrow_tick_for_swap(&m, low, true); assert!(prev == none(), 7);
    let (_, next) = tick::borrow_tick_for_swap(&m, high, false); assert!(next == none(), 8);
    dispose(m, &mut ctx);
}
#[test] fun endpoints_spacing_1() { aligned_endpoints(1); }
#[test] fun endpoints_spacing_10() { aligned_endpoints(10); }
#[test] fun endpoints_spacing_60() { aligned_endpoints(60); }
#[test] fun endpoints_spacing_1000() { aligned_endpoints(1000); }
