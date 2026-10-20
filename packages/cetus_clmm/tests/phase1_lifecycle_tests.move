#[test_only]
module cetus_clmm::phase1_lifecycle_tests;
use cetus_clmm::{config,pool,rewarder,position,tick_math};
use cetus_clmm::pool_tests::{CoinA,CoinB,CoinC,open_position_with_liquidity,nt,pt};
use integer_mate::i32;
use sui::{balance,clock,transfer};
use std::{string,type_name};
fun exercise(op:u8,mode:u8) {
    let mut ctx=tx_context::dummy();let mut clk=clock::create_for_testing(&mut ctx);
    let (cap,mut config)=config::new_global_config_for_test(&mut ctx,2000);
    config::add_role(&cap,&mut config,ctx.sender(),6);
    let mut pool=pool::new_for_test<CoinA,CoinB>(200,tick_math::get_sqrt_price_at_tick(i32::zero()),10000,string::utf8(b""),0,&clk,&mut ctx);
    let mut other=pool::new_for_test<CoinA,CoinB>(200,tick_math::get_sqrt_price_at_tick(i32::zero()),10000,string::utf8(b""),1,&clk,&mut ctx);
    let mut pos=open_position_with_liquidity(&config,&mut pool,nt(1800),pt(1800),10000000000,&clk,&mut ctx);
    let mut vault=rewarder::new_vault_for_test(&mut ctx);
    if (op==3) {
        let (a,b,receipt)=pool::flash_loan(&config,&mut pool,true,10000);a.destroy_for_testing();b.destroy_zero();
        pool::repay_flash_loan(&config,&mut pool,balance::create_for_testing<CoinA>(10100),balance::zero<CoinB>(),receipt);
    };
    if (op==4) {
        pool::initialize_rewarder<CoinA,CoinB,CoinC>(&config,&mut pool,&ctx);
        rewarder::deposit_reward(&config,&mut vault,balance::create_for_testing<CoinC>(100000000));
        pool::update_emission<CoinA,CoinB,CoinC>(&config,&mut pool,&vault,1u128<<64,&clk,&ctx);
        clk.set_for_testing(100000);
    };
    if (op==5 && mode!=5) {
        let all=position::liquidity(&pos);
        let (a,b)=pool::remove_liquidity(&config,&mut pool,&mut pos,all,&clk);a.destroy_for_testing();b.destroy_for_testing();
    };
    if (mode==1) { config::emergency_pause(&mut config,&ctx); };
    if (mode==2) { config::update_package_version(&cap,&mut config,config::package_version()+1); };
    if (mode==3) { pool::set_pool_status(&config,&mut pool,op < 2 || op==8,op==2 || op==5,op==6,op==7,op==3,op==4,&mut ctx); };
    let target=if (mode==4) { &mut other } else { &mut pool };
    let (ba,bb)=pool::balances(target);let before_a=ba.value();let before_b=bb.value();
    if (op < 2) {
        let before_liq=position::liquidity(&pos);
        let cert=if (op==0) { pool::add_liquidity(&config,target,&mut pos,1000000,&clk) } else { pool::add_liquidity_fix_coin(&config,target,&mut pos,1000000,true,&clk) };
        let (a,b)=cert.add_liquidity_pay_amount();
        pool::repay_add_liquidity(&config,target,balance::create_for_testing<CoinA>(a),balance::create_for_testing<CoinB>(b),cert);
        let (aa,ab)=pool::balances(target);assert!(aa.value()==before_a+a && ab.value()==before_b+b && position::liquidity(&pos)>before_liq,100);
        transfer::public_transfer(pos,ctx.sender());
    } else if (op==2) {
        let all=position::liquidity(&pos);
        let (a,b)=pool::remove_liquidity(&config,target,&mut pos,all,&clk);
        let (aa,ab)=pool::balances(target);assert!(a.value()>0 && b.value()>0 && aa.value()+a.value()==before_a && ab.value()+b.value()==before_b && position::liquidity(&pos)==0,101);
        a.destroy_for_testing();b.destroy_for_testing();transfer::public_transfer(pos,ctx.sender());
    } else if (op==3) {
        let (a,b)=pool::collect_fee(&config,target,&pos,true);
        let (aa,ab)=pool::balances(target);assert!(a.value()>0 && b.value()==0 && aa.value()+a.value()==before_a && ab.value()==before_b,102);
        a.destroy_for_testing();b.destroy_zero();
        let (a,b)=pool::collect_fee(&config,target,&pos,true);a.destroy_zero();b.destroy_zero();transfer::public_transfer(pos,ctx.sender());
    } else if (op==4) {
        let key=type_name::with_defining_ids<CoinC>();
        let before=rewarder::balances(&vault).borrow<type_name::TypeName,balance::Balance<CoinC>>(key).value();
        let r=pool::collect_reward<CoinA,CoinB,CoinC>(&config,target,&pos,&mut vault,true,&clk);
        let after=rewarder::balances(&vault).borrow<type_name::TypeName,balance::Balance<CoinC>>(key).value();
        assert!(r.value()>0 && after+r.value()==before,103);r.destroy_for_testing();
        pool::collect_reward<CoinA,CoinB,CoinC>(&config,target,&pos,&mut vault,true,&clk).destroy_zero();transfer::public_transfer(pos,ctx.sender());
    } else if (op==5) { pool::close_position(&config,target,pos); }
    else if (op==6) {
        let (a,b,receipt)=pool::flash_swap(&config,target,true,true,10000,tick_math::min_sqrt_price(),&clk);
        assert!(b.value()>0,104);a.destroy_zero();b.destroy_for_testing();let pay=pool::swap_pay_amount(&receipt);
        pool::repay_flash_swap(&config,target,balance::create_for_testing<CoinA>(pay),balance::zero<CoinB>(),receipt);transfer::public_transfer(pos,ctx.sender());
    } else if (op==7) {
        let (a,b,receipt)=pool::flash_loan(&config,target,true,10000);assert!(a.value()==10000,105);a.destroy_for_testing();b.destroy_zero();
        pool::repay_flash_loan(&config,target,balance::create_for_testing<CoinA>(10100),balance::zero<CoinB>(),receipt);transfer::public_transfer(pos,ctx.sender());
    } else {
        let p=pool::open_position(&config,target,nt(1800).as_u32(),pt(1800).as_u32(),&mut ctx);
        assert!(position::liquidity(&p)==0,106);transfer::public_transfer(p,ctx.sender());transfer::public_transfer(pos,ctx.sender());
    };
    transfer::public_share_object(pool);transfer::public_share_object(other);transfer::public_share_object(vault);transfer::public_share_object(config);transfer::public_transfer(cap,ctx.sender());clk.destroy_for_testing();
}

#[test]
fun test_phase1_add_liquidity_active() { exercise(0,0); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_add_liquidity_paused() { exercise(0,1); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_add_liquidity_deprecated() { exercise(0,2); }

#[test]
#[expected_failure(abort_code = pool::EOperationNotPermitted, location = cetus_clmm::pool)]
fun test_phase1_add_liquidity_pool_disabled() { exercise(0,3); }

#[test]
#[expected_failure(abort_code = pool::EPoolPositionNotMatch, location = cetus_clmm::pool)]
fun test_phase1_add_liquidity_wrong_pool() { exercise(0,4); }

#[test]
fun test_phase1_add_liquidity_fix_coin_active() { exercise(1,0); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_add_liquidity_fix_coin_paused() { exercise(1,1); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_add_liquidity_fix_coin_deprecated() { exercise(1,2); }

#[test]
#[expected_failure(abort_code = pool::EOperationNotPermitted, location = cetus_clmm::pool)]
fun test_phase1_add_liquidity_fix_coin_pool_disabled() { exercise(1,3); }

#[test]
#[expected_failure(abort_code = pool::EPoolPositionNotMatch, location = cetus_clmm::pool)]
fun test_phase1_add_liquidity_fix_coin_wrong_pool() { exercise(1,4); }

#[test]
fun test_phase1_remove_liquidity_active() { exercise(2,0); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_remove_liquidity_paused() { exercise(2,1); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_remove_liquidity_deprecated() { exercise(2,2); }

#[test]
#[expected_failure(abort_code = pool::EOperationNotPermitted, location = cetus_clmm::pool)]
fun test_phase1_remove_liquidity_pool_disabled() { exercise(2,3); }

#[test]
#[expected_failure(abort_code = pool::EPoolPositionNotMatch, location = cetus_clmm::pool)]
fun test_phase1_remove_liquidity_wrong_pool() { exercise(2,4); }

#[test]
fun test_phase1_collect_fee_active() { exercise(3,0); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_collect_fee_paused() { exercise(3,1); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_collect_fee_deprecated() { exercise(3,2); }

#[test]
#[expected_failure(abort_code = pool::EOperationNotPermitted, location = cetus_clmm::pool)]
fun test_phase1_collect_fee_pool_disabled() { exercise(3,3); }

#[test]
#[expected_failure(abort_code = pool::EPoolPositionNotMatch, location = cetus_clmm::pool)]
fun test_phase1_collect_fee_wrong_pool() { exercise(3,4); }

#[test]
fun test_phase1_collect_reward_active() { exercise(4,0); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_collect_reward_paused() { exercise(4,1); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_collect_reward_deprecated() { exercise(4,2); }

#[test]
#[expected_failure(abort_code = pool::EOperationNotPermitted, location = cetus_clmm::pool)]
fun test_phase1_collect_reward_pool_disabled() { exercise(4,3); }

#[test]
#[expected_failure(abort_code = pool::EPoolPositionNotMatch, location = cetus_clmm::pool)]
fun test_phase1_collect_reward_wrong_pool() { exercise(4,4); }

#[test]
fun test_phase1_close_position_active() { exercise(5,0); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_close_position_paused() { exercise(5,1); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_close_position_deprecated() { exercise(5,2); }

#[test]
#[expected_failure(abort_code = pool::EOperationNotPermitted, location = cetus_clmm::pool)]
fun test_phase1_close_position_pool_disabled() { exercise(5,3); }

#[test]
#[expected_failure(abort_code = pool::EPoolPositionNotMatch, location = cetus_clmm::pool)]
fun test_phase1_close_position_wrong_pool() { exercise(5,4); }

#[test]
fun test_phase1_flash_swap_active() { exercise(6,0); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_flash_swap_paused() { exercise(6,1); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_flash_swap_deprecated() { exercise(6,2); }

#[test]
#[expected_failure(abort_code = pool::EOperationNotPermitted, location = cetus_clmm::pool)]
fun test_phase1_flash_swap_pool_disabled() { exercise(6,3); }

#[test]
fun test_phase1_flash_loan_active() { exercise(7,0); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_flash_loan_paused() { exercise(7,1); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_flash_loan_deprecated() { exercise(7,2); }

#[test]
#[expected_failure(abort_code = pool::EOperationNotPermitted, location = cetus_clmm::pool)]
fun test_phase1_flash_loan_pool_disabled() { exercise(7,3); }

#[test]
fun test_phase1_open_position_active() { exercise(8,0); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_open_position_paused() { exercise(8,1); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_open_position_deprecated() { exercise(8,2); }

#[test]
#[expected_failure(abort_code = pool::EOperationNotPermitted, location = cetus_clmm::pool)]
fun test_phase1_open_position_pool_disabled() { exercise(8,3); }

#[test]
#[expected_failure(abort_code = position::EPositionIsNotEmpty, location = cetus_clmm::position)]
fun test_phase1_close_position_nonempty() { exercise(5,5); }
