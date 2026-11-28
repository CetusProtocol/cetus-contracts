#[test_only]
module cetus_clmm::bitmap_read_regression_tests;
use cetus_clmm::tick;
use integer_mate::{i32, i128};
use move_stl::{skip_list, option_u64};
public struct Holder has key { id: UID, m: tick::TickManager }
fun dispose(m: tick::TickManager, ctx: &mut TxContext) { sui::transfer::share_object(Holder { id: object::new(ctx), m }); }
fun value(i: u32): tick::Tick { tick::new_tick_for_test(i32::from(i), i128::from(0), 1, 0, 0, 0, vector[]) }
fun manager(ctx: &mut TxContext): tick::TickManager {
 let mut m = tick::new(1000, 12, ctx);
 tick::add_ticks_for_test(&mut m, vector[value(0), value(1000)]); m
}
fun activate(m: &mut tick::TickManager) { tick::bitmap_begin(m); tick::bitmap_build_batch(m, 128, false); tick::bitmap_finalize(m); }
#[test]
fun all_modes_readable() {
 let mut ctx = tx_context::dummy(); let mut m = manager(&mut ctx);
 assert!(tick::fetch_ticks(&m, vector[], 20).length() == 2);
 tick::bitmap_begin(&mut m);
 assert!(tick::fetch_ticks(&m, vector[1000], 20).length() == 1);
 tick::bitmap_cancel_begin(&mut m);
 assert!(tick::fetch_ticks(&m, vector[], 20).length() == 2);
 tick::bitmap_cancel_batch(&mut m, 128); tick::bitmap_cancel_finish(&mut m);
 activate(&mut m);
 assert!(tick::fetch_ticks(&m, vector[], 20).length() == 2);
 tick::bitmap_repair_begin(&mut m);
 assert!(tick::fetch_ticks(&m, vector[], 20).length() == 2);
 tick::bitmap_repair_clear_batch(&mut m, 128); tick::bitmap_repair_clear_finish(&mut m);
 assert!(tick::fetch_ticks(&m, vector[], 20).length() == 2);
 dispose(m, &mut ctx);
}



#[test]
#[expected_failure(abort_code = 10, location = move_stl::skip_list)]
fun rejects_mode() {
 let mut ctx = tx_context::dummy(); let mut m = manager(&mut ctx); activate(&mut m);
 skip_list::bitmap_set_mode_for_test(m.mut_tick_manager(), 255);
 assert!(tick::fetch_ticks(&m, vector[], 0).is_empty());
 tick::fetch_ticks(&m, vector[], 2); dispose(m, &mut ctx);
}

#[test]
#[expected_failure(abort_code = 12, location = move_stl::skip_list)]
fun rejects_reciprocal() {
 let mut ctx = tx_context::dummy(); let mut m = manager(&mut ctx); activate(&mut m);
 skip_list::node_set_prev_for_test(m.mut_tick_manager(), 444636, option_u64::none());
 assert!(tick::fetch_ticks(&m, vector[], 1).length() == 1);
 tick::fetch_ticks(&m, vector[], 2); dispose(m, &mut ctx);
}


#[test]
#[expected_failure(abort_code = 2, location = cetus_clmm::tick)]
fun neighbor_identity_False_False() {
 let mut ctx = tx_context::dummy(); let mut m = manager(&mut ctx);
 
 *skip_list::borrow_mut(m.mut_tick_manager(), 444636) = value(2000);
 tick::borrow_tick_for_swap(&m, 443636, false);
 dispose(m, &mut ctx);
}

#[test]
#[expected_failure(abort_code = 2, location = cetus_clmm::tick)]
fun neighbor_identity_False_True() {
 let mut ctx = tx_context::dummy(); let mut m = manager(&mut ctx);
 
 *skip_list::borrow_mut(m.mut_tick_manager(), 443636) = value(2000);
 tick::borrow_tick_for_swap(&m, 444636, true);
 dispose(m, &mut ctx);
}

#[test]
#[expected_failure(abort_code = 2, location = cetus_clmm::tick)]
fun neighbor_identity_True_False() {
 let mut ctx = tx_context::dummy(); let mut m = manager(&mut ctx);
 activate(&mut m);
 *skip_list::borrow_mut(m.mut_tick_manager(), 444636) = value(2000);
 tick::borrow_tick_for_swap(&m, 443636, false);
 dispose(m, &mut ctx);
}

#[test]
#[expected_failure(abort_code = 2, location = cetus_clmm::tick)]
fun neighbor_identity_True_True() {
 let mut ctx = tx_context::dummy(); let mut m = manager(&mut ctx);
 activate(&mut m);
 *skip_list::borrow_mut(m.mut_tick_manager(), 443636) = value(2000);
 tick::borrow_tick_for_swap(&m, 444636, true);
 dispose(m, &mut ctx);
}
