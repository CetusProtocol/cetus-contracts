#[test_only]
module cetus_clmm::phase2_recovery_tests;
use cetus_clmm::{config,pool,position,tick_math};
use cetus_clmm::pool_tests::{CoinA,CoinB,open_position_with_liquidity,nt,pt};
use integer_mate::i32;
use sui::{clock,coin,transfer};
use std::string;
// Test-only setup creates recovery-era state; production gates are not changed.
fun exercise(op:u8,mode:u8) {
    let mut ctx=tx_context::dummy(); let clk=clock::create_for_testing(&mut ctx);
    let (cap,mut config)=config::new_global_config_for_test(&mut ctx,2000);
    let mut pool=pool::new_for_test<CoinA,CoinB>(200,tick_math::get_sqrt_price_at_tick(i32::zero()),10000,string::utf8(b""),0,&clk,&mut ctx);
    let pos=open_position_with_liquidity(&config,&mut pool,nt(1800),pt(1800),10000000000,&clk,&mut ctx);
    let id=object::id(&pos);let liq=position::liquidity(&pos);let price=pool.current_sqrt_price();
    let (a,b)=pool.balances();let before_a=a.value();let before_b=b.value();
    if (mode==2) { config::remove_member(&cap,&mut config,ctx.sender()); };
    if (mode!=0) { pool.pause_pool();config::update_package_version_for_test(&cap,&mut config,18446744073709551000); };
    if (op==0) { pool::apply_liquidity_cut(&config,&mut pool,id,0,&clk,&mut ctx); }
    else if (op==1) { pool::governance_fund_injection(&mut config,&mut pool,coin::mint_for_testing<CoinA>(100,&mut ctx),coin::mint_for_testing<CoinB>(100,&mut ctx),&mut ctx); }
    else if (op==2) { pool::governance_fund_withdrawal(&mut config,&mut pool,1,1,&mut ctx); }
    else if (op==3) { pool::emergency_remove_malicious_position(&mut config,&mut pool,id,&mut ctx); }
    else if (op==4) { pool::emergency_restore_pool_state(&mut config,&mut pool,price,liq,&clk,&mut ctx); }
    else if (op==5) { pool::pause(&config,&mut pool,&ctx); }
    else if (op==6) { pool::unpause(&config,&mut pool,&ctx); }
    else if (op==7) { pool::update_pool(&config,&mut pool,coin::mint_for_testing<CoinA>(100,&mut ctx),coin::mint_for_testing<CoinB>(100,&mut ctx),&ctx); }
    else {
        if (mode==3) { pool.unpause_pool(); };
        let percent=if (mode==4) { 1000001 } else if (mode==5) { 0 } else { 1000000 };
        pool::init_position_snapshot(&config,&mut pool,percent,&mut ctx);
        if (mode==6) { pool::init_position_snapshot(&config,&mut pool,percent,&mut ctx); };
        let snapshot=pool.position_liquidity_snapshot();
        assert!(snapshot.remove_percent()==percent && snapshot.current_sqrt_price()==price && snapshot.total_value_cut()==0,100);
        assert!(!pool.is_attacked_position(id) && position::liquidity(&pos)==liq,101);
        let (a,b)=pool.balances();assert!(a.value()==before_a && b.value()==before_b,102);
    };
    transfer::public_transfer(pos,ctx.sender());transfer::public_transfer(cap,ctx.sender());
    transfer::public_share_object(config);transfer::public_share_object(pool);clk.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code = pool::EDeprecatedFunction, location = cetus_clmm::pool)]
fun test_phase2_apply_cut_normal() { exercise(0,0); }

#[test]
#[expected_failure(abort_code = pool::EDeprecatedFunction, location = cetus_clmm::pool)]
fun test_phase2_apply_cut_recovery() { exercise(0,1); }

#[test]
#[expected_failure(abort_code = pool::EDeprecatedFunction, location = cetus_clmm::pool)]
fun test_phase2_inject_normal() { exercise(1,0); }

#[test]
#[expected_failure(abort_code = pool::EDeprecatedFunction, location = cetus_clmm::pool)]
fun test_phase2_inject_recovery() { exercise(1,1); }

#[test]
#[expected_failure(abort_code = pool::EDeprecatedFunction, location = cetus_clmm::pool)]
fun test_phase2_withdraw_normal() { exercise(2,0); }

#[test]
#[expected_failure(abort_code = pool::EDeprecatedFunction, location = cetus_clmm::pool)]
fun test_phase2_withdraw_recovery() { exercise(2,1); }

#[test]
#[expected_failure(abort_code = pool::EDeprecatedFunction, location = cetus_clmm::pool)]
fun test_phase2_remove_malicious_normal() { exercise(3,0); }

#[test]
#[expected_failure(abort_code = pool::EDeprecatedFunction, location = cetus_clmm::pool)]
fun test_phase2_remove_malicious_recovery() { exercise(3,1); }

#[test]
#[expected_failure(abort_code = pool::EDeprecatedFunction, location = cetus_clmm::pool)]
fun test_phase2_restore_pool_normal() { exercise(4,0); }

#[test]
#[expected_failure(abort_code = pool::EDeprecatedFunction, location = cetus_clmm::pool)]
fun test_phase2_restore_pool_recovery() { exercise(4,1); }

#[test]
#[expected_failure(abort_code = pool::EDeprecatedFunction, location = cetus_clmm::pool)]
fun test_phase2_pause_legacy_normal() { exercise(5,0); }

#[test]
#[expected_failure(abort_code = pool::EDeprecatedFunction, location = cetus_clmm::pool)]
fun test_phase2_pause_legacy_recovery() { exercise(5,1); }

#[test]
#[expected_failure(abort_code = pool::EDeprecatedFunction, location = cetus_clmm::pool)]
fun test_phase2_unpause_legacy_normal() { exercise(6,0); }

#[test]
#[expected_failure(abort_code = pool::EDeprecatedFunction, location = cetus_clmm::pool)]
fun test_phase2_unpause_legacy_recovery() { exercise(6,1); }

#[test]
#[expected_failure(abort_code = 0, location = cetus_clmm::pool)]
fun test_phase2_update_pool_legacy_normal() { exercise(7,0); }

#[test]
#[expected_failure(abort_code = 0, location = cetus_clmm::pool)]
fun test_phase2_update_pool_legacy_recovery() { exercise(7,1); }

#[test]
fun test_phase2_snapshot_full_cut() { exercise(8,1); }

#[test]
fun test_phase2_snapshot_zero_cut() { exercise(8,5); }

#[test]
#[expected_failure(abort_code = config::EConfigVersionNotEqualEmergencyRestoreVersion, location = cetus_clmm::config)]
fun test_phase2_snapshot_wrong_version() { exercise(8,0); }

#[test]
#[expected_failure(abort_code = config::ENoPoolManagerPemission, location = cetus_clmm::config)]
fun test_phase2_snapshot_unauthorized() { exercise(8,2); }

#[test]
#[expected_failure(abort_code = pool::EPoolNotPaused, location = cetus_clmm::pool)]
fun test_phase2_snapshot_not_paused() { exercise(8,3); }

#[test]
#[expected_failure(abort_code = pool::EInvalidRemovePercent, location = cetus_clmm::pool)]
fun test_phase2_snapshot_over_ppm() { exercise(8,4); }

#[test]
#[expected_failure(abort_code = sui::dynamic_field::EFieldAlreadyExists, location = sui::dynamic_field)]
fun test_phase2_snapshot_duplicate() { exercise(8,6); }

// Successful global recovery restores a funded user's ability to exit.
fun global_recovery(mode:u8) {
    let mut ctx=tx_context::dummy();let clk=clock::create_for_testing(&mut ctx);
    let (cap,mut config)=config::new_global_config_for_test(&mut ctx,2000);
    config::set_roles(&cap,&mut config,ctx.sender(),127);
    config::update_package_version(&cap,&mut config,config::package_version());
    let mut pool=pool::new_for_test<CoinA,CoinB>(200,tick_math::get_sqrt_price_at_tick(i32::zero()),10000,string::utf8(b""),0,&clk,&mut ctx);
    let mut pos=open_position_with_liquidity(&config,&mut pool,nt(1800),pt(1800),10000000000,&clk,&mut ctx);
    let (a,b)=pool.balances();let before_a=a.value();let before_b=b.value();
    if (mode!=3) {config::emergency_pause(&mut config,&ctx);};
    let target=if (mode==1) {config::package_version()-1} else if (mode==2) {config::package_version()+1} else {config::package_version()};
    config::emergency_unpause(&mut config,target,&ctx);
    config::checked_package_version(&config);
    if (mode==4) {config::emergency_unpause(&mut config,target,&ctx);};
    let all=position::liquidity(&pos);
    let (a,b)=pool::remove_liquidity(&config,&mut pool,&mut pos,all,&clk);
    let (left_a,left_b)=pool.balances();
    assert!(a.value()>0 && b.value()>0 && left_a.value()+a.value()==before_a && left_b.value()+b.value()==before_b,110);
    assert!(position::liquidity(&pos)==0,111);
    a.destroy_for_testing();b.destroy_for_testing();transfer::public_transfer(pos,ctx.sender());
    transfer::public_transfer(cap,ctx.sender());transfer::public_share_object(config);transfer::public_share_object(pool);clk.destroy_for_testing();
}
#[test]
fun test_phase2_global_recovery_funded_exit() {global_recovery(0);}
#[test]
#[expected_failure(abort_code=config::EInvalidPackageVersion,location=cetus_clmm::config)]
fun test_phase2_global_recovery_lower_version() {global_recovery(1);}
#[test]
#[expected_failure(abort_code=config::EInvalidPackageVersion,location=cetus_clmm::config)]
fun test_phase2_global_recovery_future_version() {global_recovery(2);}
#[test]
#[expected_failure(abort_code=config::EProtocolNotEmergencyPause,location=cetus_clmm::config)]
fun test_phase2_global_recovery_not_paused() {global_recovery(3);}
#[test]
#[expected_failure(abort_code=config::EProtocolNotEmergencyPause,location=cetus_clmm::config)]
fun test_phase2_global_recovery_replay() {global_recovery(4);}
