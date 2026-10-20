#[test_only]
module cetus_clmm::phase1_liquidity_receipt_tests;
use cetus_clmm::{config,pool,tick_math};
use cetus_clmm::pool_tests::{CoinA,CoinB,nt,pt};
use integer_mate::i32;
use sui::{balance,clock,transfer};
use std::string;
fun exercise(mode:u8) {
    let mut ctx=tx_context::dummy();let clk=clock::create_for_testing(&mut ctx);
    let (cap,mut config)=config::new_global_config_for_test(&mut ctx,2000);config::add_role(&cap,&mut config,ctx.sender(),6);
    let mut pool=pool::new_for_test<CoinA,CoinB>(200,tick_math::get_sqrt_price_at_tick(i32::zero()),10000,string::utf8(b""),0,&clk,&mut ctx);
    let mut other=pool::new_for_test<CoinA,CoinB>(200,tick_math::get_sqrt_price_at_tick(i32::zero()),10000,string::utf8(b""),1,&clk,&mut ctx);
    let mut pos=pool::open_position(&config,&mut pool,nt(1800).as_u32(),pt(1800).as_u32(),&mut ctx);
    let cert=pool::add_liquidity(&config,&mut pool,&mut pos,1000000,&clk);
    let (a,b)=cert.add_liquidity_pay_amount();assert!(a>0 && b>0,100);
    let pay_a=if (mode==2) { a-1 } else if (mode==3) { a+1 } else { a };
    let pay_b=if (mode==4) { b-1 } else if (mode==5) { b+1 } else { b };
    if (mode==1) { config::emergency_pause(&mut config,&ctx); };
    if (mode==7) { config::update_package_version(&cap,&mut config,config::package_version()+1); };
    let target=if (mode==6) { &mut other } else { &mut pool };
    let (ba,bb)=pool::balances(target);let before_a=ba.value();let before_b=bb.value();
    pool::repay_add_liquidity(&config,target,balance::create_for_testing<CoinA>(pay_a),balance::create_for_testing<CoinB>(pay_b),cert);
    let (aa,ab)=pool::balances(target);assert!(aa.value()==before_a+a && ab.value()==before_b+b,101);
    transfer::public_transfer(pos,ctx.sender());transfer::public_transfer(cap,ctx.sender());transfer::public_share_object(pool);transfer::public_share_object(other);transfer::public_share_object(config);clk.destroy_for_testing();
}

#[test]
fun test_phase1_repay_liquidity_exact() { exercise(0); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_repay_liquidity_paused() { exercise(1); }

#[test]
#[expected_failure(abort_code = pool::EAmountIncorrect, location = cetus_clmm::pool)]
fun test_phase1_repay_liquidity_underpay_a() { exercise(2); }

#[test]
#[expected_failure(abort_code = pool::EAmountIncorrect, location = cetus_clmm::pool)]
fun test_phase1_repay_liquidity_overpay_a() { exercise(3); }

#[test]
#[expected_failure(abort_code = pool::EAmountIncorrect, location = cetus_clmm::pool)]
fun test_phase1_repay_liquidity_underpay_b() { exercise(4); }

#[test]
#[expected_failure(abort_code = pool::EAmountIncorrect, location = cetus_clmm::pool)]
fun test_phase1_repay_liquidity_overpay_b() { exercise(5); }

#[test]
#[expected_failure(abort_code = pool::EPoolIdIsError, location = cetus_clmm::pool)]
fun test_phase1_repay_liquidity_wrong_pool() { exercise(6); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_repay_liquidity_deprecated() { exercise(7); }
