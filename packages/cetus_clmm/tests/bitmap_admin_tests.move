#[test_only]
module cetus_clmm::bitmap_admin_tests;
use cetus_clmm::{config, pool, tick_math};
use cetus_clmm::pool_tests::{CoinA, CoinB};
use integer_mate::i32;
use sui::{clock, transfer};
use std::string;

// Each operation's permission and version checks run before any state mutation.
fun exercise(op: u8, denial: u8) {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let (cap, mut config) = config::new_global_config_for_test(&mut ctx, 2000);
    let mut pool = pool::new_for_test<CoinA, CoinB>(10, tick_math::get_sqrt_price_at_tick(i32::zero()), 500, string::utf8(b""), 0, &clk, &mut ctx);
    if (denial != 2) { config::update_package_version(&cap, &mut config, config::package_version()); };
    if (denial != 0 && denial != 3) { config::add_role(&cap, &mut config, ctx.sender(), config::bitmap_migration_role()); };
    if (denial == 3) { config::add_role(&cap, &mut config, @0x123, config::bitmap_migration_role()); };
    if (denial == 4) { config::update_package_version(&cap, &mut config, config::package_version() + 1); };
    if (denial == 1) { config::remove_role(&cap, &mut config, ctx.sender(), config::bitmap_migration_role()); };
    if (op == 0) { pool::bitmap_begin(&config, &mut pool, &ctx); }
    else if (op == 1) { pool::bitmap_migrate_batch(&config, &mut pool, 128, &ctx); }
    else if (op == 2) { pool::bitmap_finalize(&config, &mut pool, &ctx); }
    else if (op == 3) { pool::bitmap_cancel_begin(&config, &mut pool, &ctx); }
    else if (op == 4) { pool::bitmap_cancel_batch(&config, &mut pool, 128, &ctx); }
    else if (op == 5) { pool::bitmap_cancel_finish(&config, &mut pool, &ctx); }
    else if (op == 6) { pool::bitmap_repair_begin(&config, &mut pool, &ctx); }
    else if (op == 7) { pool::bitmap_repair_clear_batch(&config, &mut pool, 128, &ctx); }
    else if (op == 8) { pool::bitmap_repair_clear_finish(&config, &mut pool, &ctx); }
    else if (op == 9) { pool::bitmap_repair_build_batch(&config, &mut pool, 128, &ctx); }
    else if (op == 10) { pool::bitmap_repair_finalize(&config, &mut pool, &ctx); }
    else if (op == 11) { pool::bitmap_repair_restart(&config, &mut pool, &ctx); }
    else if (op == 12) { pool::bitmap_migrate_atomic(&config, &mut pool, 128, &ctx); }
    else if (op == 13) { pool::bitmap_repair_atomic(&config, &mut pool, 128, &ctx); }
    ;
    transfer::public_share_object(pool); transfer::public_share_object(config);
    transfer::public_transfer(cap, ctx.sender()); clk.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_begin_wrong_role() { exercise(0, 0); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_begin_revoked() { exercise(0, 1); }

#[test]
#[expected_failure(abort_code = 19, location = cetus_clmm::config)]
fun bitmap_begin_low_version_gate() { exercise(0, 2); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_migrate_batch_wrong_role() { exercise(1, 0); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_migrate_batch_revoked() { exercise(1, 1); }

#[test]
#[expected_failure(abort_code = 19, location = cetus_clmm::config)]
fun bitmap_migrate_batch_low_version_gate() { exercise(1, 2); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_finalize_wrong_role() { exercise(2, 0); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_finalize_revoked() { exercise(2, 1); }

#[test]
#[expected_failure(abort_code = 19, location = cetus_clmm::config)]
fun bitmap_finalize_low_version_gate() { exercise(2, 2); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_cancel_begin_wrong_role() { exercise(3, 0); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_cancel_begin_revoked() { exercise(3, 1); }

#[test]
#[expected_failure(abort_code = 19, location = cetus_clmm::config)]
fun bitmap_cancel_begin_low_version_gate() { exercise(3, 2); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_cancel_batch_wrong_role() { exercise(4, 0); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_cancel_batch_revoked() { exercise(4, 1); }

#[test]
#[expected_failure(abort_code = 19, location = cetus_clmm::config)]
fun bitmap_cancel_batch_low_version_gate() { exercise(4, 2); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_cancel_finish_wrong_role() { exercise(5, 0); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_cancel_finish_revoked() { exercise(5, 1); }

#[test]
#[expected_failure(abort_code = 19, location = cetus_clmm::config)]
fun bitmap_cancel_finish_low_version_gate() { exercise(5, 2); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_repair_begin_wrong_role() { exercise(6, 0); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_repair_begin_revoked() { exercise(6, 1); }

#[test]
#[expected_failure(abort_code = 19, location = cetus_clmm::config)]
fun bitmap_repair_begin_low_version_gate() { exercise(6, 2); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_repair_clear_batch_wrong_role() { exercise(7, 0); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_repair_clear_batch_revoked() { exercise(7, 1); }

#[test]
#[expected_failure(abort_code = 19, location = cetus_clmm::config)]
fun bitmap_repair_clear_batch_low_version_gate() { exercise(7, 2); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_repair_clear_finish_wrong_role() { exercise(8, 0); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_repair_clear_finish_revoked() { exercise(8, 1); }

#[test]
#[expected_failure(abort_code = 19, location = cetus_clmm::config)]
fun bitmap_repair_clear_finish_low_version_gate() { exercise(8, 2); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_repair_build_batch_wrong_role() { exercise(9, 0); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_repair_build_batch_revoked() { exercise(9, 1); }

#[test]
#[expected_failure(abort_code = 19, location = cetus_clmm::config)]
fun bitmap_repair_build_batch_low_version_gate() { exercise(9, 2); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_repair_finalize_wrong_role() { exercise(10, 0); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_repair_finalize_revoked() { exercise(10, 1); }

#[test]
#[expected_failure(abort_code = 19, location = cetus_clmm::config)]
fun bitmap_repair_finalize_low_version_gate() { exercise(10, 2); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_repair_restart_wrong_role() { exercise(11, 0); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_repair_restart_revoked() { exercise(11, 1); }

#[test]
#[expected_failure(abort_code = 19, location = cetus_clmm::config)]
fun bitmap_repair_restart_low_version_gate() { exercise(11, 2); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_migrate_atomic_wrong_role() { exercise(12, 0); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_migrate_atomic_revoked() { exercise(12, 1); }

#[test]
#[expected_failure(abort_code = 19, location = cetus_clmm::config)]
fun bitmap_migrate_atomic_low_version_gate() { exercise(12, 2); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_repair_atomic_wrong_role() { exercise(13, 0); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun bitmap_repair_atomic_revoked() { exercise(13, 1); }

#[test]
#[expected_failure(abort_code = 19, location = cetus_clmm::config)]
fun bitmap_repair_atomic_low_version_gate() { exercise(13, 2); }

#[test]
fun bitmap_empty_pool_repair_preserves_pause_and_version_floor() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let (cap, mut config) = config::new_global_config_for_test(&mut ctx, 2000);
    let mut pool = pool::new_for_test<CoinA, CoinB>(10, tick_math::get_sqrt_price_at_tick(i32::zero()), 500, string::utf8(b""), 0, &clk, &mut ctx);
    config::add_role(&cap, &mut config, ctx.sender(), config::bitmap_migration_role());
    config::update_package_version(&cap, &mut config, config::package_version());
    pool::set_pool_status(&config, &mut pool, true, true, true, true, true, true, &mut ctx);
    pool::bitmap_migrate_atomic(&config, &mut pool, 128, &ctx);
    let (mode, _, _, _, _, _) = pool::bitmap_status(&pool);
    assert!(mode == 3 && pool::is_pause(&pool), 0);
    pool::bitmap_repair_atomic(&config, &mut pool, 128, &ctx);
    let (mode, _, _, _, _, _) = pool::bitmap_status(&pool);
    assert!(mode == 3 && pool::is_pause(&pool), 1);
    config::add_role(&cap, &mut config, ctx.sender(), 5);
    config::add_role(&cap, &mut config, ctx.sender(), 6);
    config::emergency_pause(&mut config, &ctx);
    config::emergency_unpause(&mut config, 16, &ctx);
    transfer::public_share_object(pool); transfer::public_share_object(config);
    transfer::public_transfer(cap, ctx.sender()); clk.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code=13,location=move_stl::skip_list)]
fun bitmap_business_freeze_1_open_position() {
 let mut ctx=tx_context::dummy(); let clk=clock::create_for_testing(&mut ctx);
 let (cap,mut config)=config::new_global_config_for_test(&mut ctx,2000);
 let mut pool=pool::new_for_test<CoinA,CoinB>(1000,tick_math::get_sqrt_price_at_tick(i32::zero()),500,string::utf8(b""),0,&clk,&mut ctx);
 config::add_role(&cap,&mut config,ctx.sender(),config::bitmap_migration_role());
 config::update_package_version(&cap,&mut config,config::package_version());
 pool::bitmap_begin(&config,&mut pool,&ctx);
 let _p=pool::open_position(&config,&mut pool,0,10,&mut ctx); transfer::public_transfer(_p,ctx.sender());
 transfer::public_share_object(pool); transfer::public_share_object(config); transfer::public_transfer(cap,ctx.sender()); clk.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code=13,location=move_stl::skip_list)]
fun bitmap_business_freeze_1_update_fee_rate() {
 let mut ctx=tx_context::dummy(); let clk=clock::create_for_testing(&mut ctx);
 let (cap,mut config)=config::new_global_config_for_test(&mut ctx,2000);
 let mut pool=pool::new_for_test<CoinA,CoinB>(1000,tick_math::get_sqrt_price_at_tick(i32::zero()),500,string::utf8(b""),0,&clk,&mut ctx);
 config::add_role(&cap,&mut config,ctx.sender(),config::bitmap_migration_role());
 config::update_package_version(&cap,&mut config,config::package_version());
 pool::bitmap_begin(&config,&mut pool,&ctx);
 pool::update_fee_rate(&config,&mut pool,1000,&ctx);
 transfer::public_share_object(pool); transfer::public_share_object(config); transfer::public_transfer(cap,ctx.sender()); clk.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code=13,location=move_stl::skip_list)]
fun bitmap_business_freeze_1_flash_loan() {
 let mut ctx=tx_context::dummy(); let clk=clock::create_for_testing(&mut ctx);
 let (cap,mut config)=config::new_global_config_for_test(&mut ctx,2000);
 let mut pool=pool::new_for_test<CoinA,CoinB>(1000,tick_math::get_sqrt_price_at_tick(i32::zero()),500,string::utf8(b""),0,&clk,&mut ctx);
 config::add_role(&cap,&mut config,ctx.sender(),config::bitmap_migration_role());
 config::update_package_version(&cap,&mut config,config::package_version());
 pool::bitmap_begin(&config,&mut pool,&ctx);
 let (a,b,r)=pool::flash_loan(&config,&mut pool,true,1); a.destroy_for_testing(); b.destroy_for_testing(); pool::repay_flash_loan(&config,&mut pool,sui::balance::zero(),sui::balance::zero(),r);
 transfer::public_share_object(pool); transfer::public_share_object(config); transfer::public_transfer(cap,ctx.sender()); clk.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code=13,location=move_stl::skip_list)]
fun bitmap_business_freeze_1_collect_protocol_fee() {
 let mut ctx=tx_context::dummy(); let clk=clock::create_for_testing(&mut ctx);
 let (cap,mut config)=config::new_global_config_for_test(&mut ctx,2000);
 let mut pool=pool::new_for_test<CoinA,CoinB>(1000,tick_math::get_sqrt_price_at_tick(i32::zero()),500,string::utf8(b""),0,&clk,&mut ctx);
 config::add_role(&cap,&mut config,ctx.sender(),config::bitmap_migration_role());
 config::update_package_version(&cap,&mut config,config::package_version());
 pool::bitmap_begin(&config,&mut pool,&ctx);
 let (a,b)=pool::collect_protocol_fee(&config,&mut pool,&ctx); a.destroy_for_testing(); b.destroy_for_testing();
 transfer::public_share_object(pool); transfer::public_share_object(config); transfer::public_transfer(cap,ctx.sender()); clk.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code=13,location=move_stl::skip_list)]
fun bitmap_business_freeze_2_open_position() {
 let mut ctx=tx_context::dummy(); let clk=clock::create_for_testing(&mut ctx);
 let (cap,mut config)=config::new_global_config_for_test(&mut ctx,2000);
 let mut pool=pool::new_for_test<CoinA,CoinB>(1000,tick_math::get_sqrt_price_at_tick(i32::zero()),500,string::utf8(b""),0,&clk,&mut ctx);
 config::add_role(&cap,&mut config,ctx.sender(),config::bitmap_migration_role());
 config::update_package_version(&cap,&mut config,config::package_version());
 pool::bitmap_begin(&config,&mut pool,&ctx); pool::bitmap_cancel_begin(&config,&mut pool,&ctx);
 let _p=pool::open_position(&config,&mut pool,0,10,&mut ctx); transfer::public_transfer(_p,ctx.sender());
 transfer::public_share_object(pool); transfer::public_share_object(config); transfer::public_transfer(cap,ctx.sender()); clk.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code=13,location=move_stl::skip_list)]
fun bitmap_business_freeze_2_update_fee_rate() {
 let mut ctx=tx_context::dummy(); let clk=clock::create_for_testing(&mut ctx);
 let (cap,mut config)=config::new_global_config_for_test(&mut ctx,2000);
 let mut pool=pool::new_for_test<CoinA,CoinB>(1000,tick_math::get_sqrt_price_at_tick(i32::zero()),500,string::utf8(b""),0,&clk,&mut ctx);
 config::add_role(&cap,&mut config,ctx.sender(),config::bitmap_migration_role());
 config::update_package_version(&cap,&mut config,config::package_version());
 pool::bitmap_begin(&config,&mut pool,&ctx); pool::bitmap_cancel_begin(&config,&mut pool,&ctx);
 pool::update_fee_rate(&config,&mut pool,1000,&ctx);
 transfer::public_share_object(pool); transfer::public_share_object(config); transfer::public_transfer(cap,ctx.sender()); clk.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code=13,location=move_stl::skip_list)]
fun bitmap_business_freeze_2_flash_loan() {
 let mut ctx=tx_context::dummy(); let clk=clock::create_for_testing(&mut ctx);
 let (cap,mut config)=config::new_global_config_for_test(&mut ctx,2000);
 let mut pool=pool::new_for_test<CoinA,CoinB>(1000,tick_math::get_sqrt_price_at_tick(i32::zero()),500,string::utf8(b""),0,&clk,&mut ctx);
 config::add_role(&cap,&mut config,ctx.sender(),config::bitmap_migration_role());
 config::update_package_version(&cap,&mut config,config::package_version());
 pool::bitmap_begin(&config,&mut pool,&ctx); pool::bitmap_cancel_begin(&config,&mut pool,&ctx);
 let (a,b,r)=pool::flash_loan(&config,&mut pool,true,1); a.destroy_for_testing(); b.destroy_for_testing(); pool::repay_flash_loan(&config,&mut pool,sui::balance::zero(),sui::balance::zero(),r);
 transfer::public_share_object(pool); transfer::public_share_object(config); transfer::public_transfer(cap,ctx.sender()); clk.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code=13,location=move_stl::skip_list)]
fun bitmap_business_freeze_2_collect_protocol_fee() {
 let mut ctx=tx_context::dummy(); let clk=clock::create_for_testing(&mut ctx);
 let (cap,mut config)=config::new_global_config_for_test(&mut ctx,2000);
 let mut pool=pool::new_for_test<CoinA,CoinB>(1000,tick_math::get_sqrt_price_at_tick(i32::zero()),500,string::utf8(b""),0,&clk,&mut ctx);
 config::add_role(&cap,&mut config,ctx.sender(),config::bitmap_migration_role());
 config::update_package_version(&cap,&mut config,config::package_version());
 pool::bitmap_begin(&config,&mut pool,&ctx); pool::bitmap_cancel_begin(&config,&mut pool,&ctx);
 let (a,b)=pool::collect_protocol_fee(&config,&mut pool,&ctx); a.destroy_for_testing(); b.destroy_for_testing();
 transfer::public_share_object(pool); transfer::public_share_object(config); transfer::public_transfer(cap,ctx.sender()); clk.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code=13,location=move_stl::skip_list)]
fun bitmap_business_freeze_4_open_position() {
 let mut ctx=tx_context::dummy(); let clk=clock::create_for_testing(&mut ctx);
 let (cap,mut config)=config::new_global_config_for_test(&mut ctx,2000);
 let mut pool=pool::new_for_test<CoinA,CoinB>(1000,tick_math::get_sqrt_price_at_tick(i32::zero()),500,string::utf8(b""),0,&clk,&mut ctx);
 config::add_role(&cap,&mut config,ctx.sender(),config::bitmap_migration_role());
 config::update_package_version(&cap,&mut config,config::package_version());
 pool::bitmap_migrate_atomic(&config,&mut pool,128,&ctx); pool::bitmap_repair_begin(&config,&mut pool,&ctx);
 let _p=pool::open_position(&config,&mut pool,0,10,&mut ctx); transfer::public_transfer(_p,ctx.sender());
 transfer::public_share_object(pool); transfer::public_share_object(config); transfer::public_transfer(cap,ctx.sender()); clk.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code=13,location=move_stl::skip_list)]
fun bitmap_business_freeze_4_update_fee_rate() {
 let mut ctx=tx_context::dummy(); let clk=clock::create_for_testing(&mut ctx);
 let (cap,mut config)=config::new_global_config_for_test(&mut ctx,2000);
 let mut pool=pool::new_for_test<CoinA,CoinB>(1000,tick_math::get_sqrt_price_at_tick(i32::zero()),500,string::utf8(b""),0,&clk,&mut ctx);
 config::add_role(&cap,&mut config,ctx.sender(),config::bitmap_migration_role());
 config::update_package_version(&cap,&mut config,config::package_version());
 pool::bitmap_migrate_atomic(&config,&mut pool,128,&ctx); pool::bitmap_repair_begin(&config,&mut pool,&ctx);
 pool::update_fee_rate(&config,&mut pool,1000,&ctx);
 transfer::public_share_object(pool); transfer::public_share_object(config); transfer::public_transfer(cap,ctx.sender()); clk.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code=13,location=move_stl::skip_list)]
fun bitmap_business_freeze_4_flash_loan() {
 let mut ctx=tx_context::dummy(); let clk=clock::create_for_testing(&mut ctx);
 let (cap,mut config)=config::new_global_config_for_test(&mut ctx,2000);
 let mut pool=pool::new_for_test<CoinA,CoinB>(1000,tick_math::get_sqrt_price_at_tick(i32::zero()),500,string::utf8(b""),0,&clk,&mut ctx);
 config::add_role(&cap,&mut config,ctx.sender(),config::bitmap_migration_role());
 config::update_package_version(&cap,&mut config,config::package_version());
 pool::bitmap_migrate_atomic(&config,&mut pool,128,&ctx); pool::bitmap_repair_begin(&config,&mut pool,&ctx);
 let (a,b,r)=pool::flash_loan(&config,&mut pool,true,1); a.destroy_for_testing(); b.destroy_for_testing(); pool::repay_flash_loan(&config,&mut pool,sui::balance::zero(),sui::balance::zero(),r);
 transfer::public_share_object(pool); transfer::public_share_object(config); transfer::public_transfer(cap,ctx.sender()); clk.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code=13,location=move_stl::skip_list)]
fun bitmap_business_freeze_4_collect_protocol_fee() {
 let mut ctx=tx_context::dummy(); let clk=clock::create_for_testing(&mut ctx);
 let (cap,mut config)=config::new_global_config_for_test(&mut ctx,2000);
 let mut pool=pool::new_for_test<CoinA,CoinB>(1000,tick_math::get_sqrt_price_at_tick(i32::zero()),500,string::utf8(b""),0,&clk,&mut ctx);
 config::add_role(&cap,&mut config,ctx.sender(),config::bitmap_migration_role());
 config::update_package_version(&cap,&mut config,config::package_version());
 pool::bitmap_migrate_atomic(&config,&mut pool,128,&ctx); pool::bitmap_repair_begin(&config,&mut pool,&ctx);
 let (a,b)=pool::collect_protocol_fee(&config,&mut pool,&ctx); a.destroy_for_testing(); b.destroy_for_testing();
 transfer::public_share_object(pool); transfer::public_share_object(config); transfer::public_transfer(cap,ctx.sender()); clk.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code=13,location=move_stl::skip_list)]
fun bitmap_business_freeze_5_open_position() {
 let mut ctx=tx_context::dummy(); let clk=clock::create_for_testing(&mut ctx);
 let (cap,mut config)=config::new_global_config_for_test(&mut ctx,2000);
 let mut pool=pool::new_for_test<CoinA,CoinB>(1000,tick_math::get_sqrt_price_at_tick(i32::zero()),500,string::utf8(b""),0,&clk,&mut ctx);
 config::add_role(&cap,&mut config,ctx.sender(),config::bitmap_migration_role());
 config::update_package_version(&cap,&mut config,config::package_version());
 pool::bitmap_migrate_atomic(&config,&mut pool,128,&ctx); pool::bitmap_repair_begin(&config,&mut pool,&ctx); pool::bitmap_repair_clear_batch(&config,&mut pool,128,&ctx); pool::bitmap_repair_clear_finish(&config,&mut pool,&ctx);
 let _p=pool::open_position(&config,&mut pool,0,10,&mut ctx); transfer::public_transfer(_p,ctx.sender());
 transfer::public_share_object(pool); transfer::public_share_object(config); transfer::public_transfer(cap,ctx.sender()); clk.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code=13,location=move_stl::skip_list)]
fun bitmap_business_freeze_5_update_fee_rate() {
 let mut ctx=tx_context::dummy(); let clk=clock::create_for_testing(&mut ctx);
 let (cap,mut config)=config::new_global_config_for_test(&mut ctx,2000);
 let mut pool=pool::new_for_test<CoinA,CoinB>(1000,tick_math::get_sqrt_price_at_tick(i32::zero()),500,string::utf8(b""),0,&clk,&mut ctx);
 config::add_role(&cap,&mut config,ctx.sender(),config::bitmap_migration_role());
 config::update_package_version(&cap,&mut config,config::package_version());
 pool::bitmap_migrate_atomic(&config,&mut pool,128,&ctx); pool::bitmap_repair_begin(&config,&mut pool,&ctx); pool::bitmap_repair_clear_batch(&config,&mut pool,128,&ctx); pool::bitmap_repair_clear_finish(&config,&mut pool,&ctx);
 pool::update_fee_rate(&config,&mut pool,1000,&ctx);
 transfer::public_share_object(pool); transfer::public_share_object(config); transfer::public_transfer(cap,ctx.sender()); clk.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code=13,location=move_stl::skip_list)]
fun bitmap_business_freeze_5_flash_loan() {
 let mut ctx=tx_context::dummy(); let clk=clock::create_for_testing(&mut ctx);
 let (cap,mut config)=config::new_global_config_for_test(&mut ctx,2000);
 let mut pool=pool::new_for_test<CoinA,CoinB>(1000,tick_math::get_sqrt_price_at_tick(i32::zero()),500,string::utf8(b""),0,&clk,&mut ctx);
 config::add_role(&cap,&mut config,ctx.sender(),config::bitmap_migration_role());
 config::update_package_version(&cap,&mut config,config::package_version());
 pool::bitmap_migrate_atomic(&config,&mut pool,128,&ctx); pool::bitmap_repair_begin(&config,&mut pool,&ctx); pool::bitmap_repair_clear_batch(&config,&mut pool,128,&ctx); pool::bitmap_repair_clear_finish(&config,&mut pool,&ctx);
 let (a,b,r)=pool::flash_loan(&config,&mut pool,true,1); a.destroy_for_testing(); b.destroy_for_testing(); pool::repay_flash_loan(&config,&mut pool,sui::balance::zero(),sui::balance::zero(),r);
 transfer::public_share_object(pool); transfer::public_share_object(config); transfer::public_transfer(cap,ctx.sender()); clk.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code=13,location=move_stl::skip_list)]
fun bitmap_business_freeze_5_collect_protocol_fee() {
 let mut ctx=tx_context::dummy(); let clk=clock::create_for_testing(&mut ctx);
 let (cap,mut config)=config::new_global_config_for_test(&mut ctx,2000);
 let mut pool=pool::new_for_test<CoinA,CoinB>(1000,tick_math::get_sqrt_price_at_tick(i32::zero()),500,string::utf8(b""),0,&clk,&mut ctx);
 config::add_role(&cap,&mut config,ctx.sender(),config::bitmap_migration_role());
 config::update_package_version(&cap,&mut config,config::package_version());
 pool::bitmap_migrate_atomic(&config,&mut pool,128,&ctx); pool::bitmap_repair_begin(&config,&mut pool,&ctx); pool::bitmap_repair_clear_batch(&config,&mut pool,128,&ctx); pool::bitmap_repair_clear_finish(&config,&mut pool,&ctx);
 let (a,b)=pool::collect_protocol_fee(&config,&mut pool,&ctx); a.destroy_for_testing(); b.destroy_for_testing();
 transfer::public_share_object(pool); transfer::public_share_object(config); transfer::public_transfer(cap,ctx.sender()); clk.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun begin_role_belongs_to_other_sender() { exercise(0, 3); }

#[test]
#[expected_failure(abort_code = 10, location = cetus_clmm::config)]
fun begin_future_version_gate() { exercise(0, 4); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun migrate_batch_role_belongs_to_other_sender() { exercise(1, 3); }

#[test]
#[expected_failure(abort_code = 10, location = cetus_clmm::config)]
fun migrate_batch_future_version_gate() { exercise(1, 4); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun finalize_role_belongs_to_other_sender() { exercise(2, 3); }

#[test]
#[expected_failure(abort_code = 10, location = cetus_clmm::config)]
fun finalize_future_version_gate() { exercise(2, 4); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun cancel_begin_role_belongs_to_other_sender() { exercise(3, 3); }

#[test]
#[expected_failure(abort_code = 10, location = cetus_clmm::config)]
fun cancel_begin_future_version_gate() { exercise(3, 4); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun cancel_batch_role_belongs_to_other_sender() { exercise(4, 3); }

#[test]
#[expected_failure(abort_code = 10, location = cetus_clmm::config)]
fun cancel_batch_future_version_gate() { exercise(4, 4); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun cancel_finish_role_belongs_to_other_sender() { exercise(5, 3); }

#[test]
#[expected_failure(abort_code = 10, location = cetus_clmm::config)]
fun cancel_finish_future_version_gate() { exercise(5, 4); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun repair_begin_role_belongs_to_other_sender() { exercise(6, 3); }

#[test]
#[expected_failure(abort_code = 10, location = cetus_clmm::config)]
fun repair_begin_future_version_gate() { exercise(6, 4); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun repair_clear_batch_role_belongs_to_other_sender() { exercise(7, 3); }

#[test]
#[expected_failure(abort_code = 10, location = cetus_clmm::config)]
fun repair_clear_batch_future_version_gate() { exercise(7, 4); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun repair_clear_finish_role_belongs_to_other_sender() { exercise(8, 3); }

#[test]
#[expected_failure(abort_code = 10, location = cetus_clmm::config)]
fun repair_clear_finish_future_version_gate() { exercise(8, 4); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun repair_build_batch_role_belongs_to_other_sender() { exercise(9, 3); }

#[test]
#[expected_failure(abort_code = 10, location = cetus_clmm::config)]
fun repair_build_batch_future_version_gate() { exercise(9, 4); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun repair_finalize_role_belongs_to_other_sender() { exercise(10, 3); }

#[test]
#[expected_failure(abort_code = 10, location = cetus_clmm::config)]
fun repair_finalize_future_version_gate() { exercise(10, 4); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun repair_restart_role_belongs_to_other_sender() { exercise(11, 3); }

#[test]
#[expected_failure(abort_code = 10, location = cetus_clmm::config)]
fun repair_restart_future_version_gate() { exercise(11, 4); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun migrate_atomic_role_belongs_to_other_sender() { exercise(12, 3); }

#[test]
#[expected_failure(abort_code = 10, location = cetus_clmm::config)]
fun migrate_atomic_future_version_gate() { exercise(12, 4); }

#[test]
#[expected_failure(abort_code = 18, location = cetus_clmm::config)]
fun repair_atomic_role_belongs_to_other_sender() { exercise(13, 3); }

#[test]
#[expected_failure(abort_code = 10, location = cetus_clmm::config)]
fun repair_atomic_future_version_gate() { exercise(13, 4); }
