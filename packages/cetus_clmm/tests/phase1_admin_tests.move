#[test_only]
module cetus_clmm::phase1_admin_tests;
use cetus_clmm::{config, pool, rewarder, partner};
use cetus_clmm::pool_tests::{CoinA, CoinB, CoinC, open_position_with_liquidity, nt, pt};
use integer_mate::i32;
use sui::{balance, clock, transfer};
use std::string;

fun exercise(op: u8, mode: u8) {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let (cap, mut config) = config::new_global_config_for_test(&mut ctx, 2000);
    let mut pool = pool::new_for_test<CoinA,CoinB>(200, cetus_clmm::tick_math::get_sqrt_price_at_tick(i32::zero()), 10000, string::utf8(b""), 0, &clk, &mut ctx);
    let mut vault = rewarder::new_vault_for_test(&mut ctx);
    let (partner_cap, mut partner) = partner::create_partner_for_test(string::utf8(b"phase1"),1000,0,1000,&clk,&mut ctx);
    if (op == 3) {
        pool::initialize_rewarder<CoinA,CoinB,CoinC>(&config,&mut pool,&ctx);
        rewarder::deposit_reward(&config,&mut vault,balance::create_for_testing<CoinC>(100000000));
    };
    if (op == 4) {
        let pos = open_position_with_liquidity(&config,&mut pool,nt(1800),pt(1800),10000000000,&clk,&mut ctx);
        transfer::public_transfer(pos,ctx.sender());
        let (a,b,receipt) = pool::flash_loan(&config,&mut pool,true,10000);
        a.destroy_for_testing(); b.destroy_zero();
        pool::repay_flash_loan(&config,&mut pool,balance::create_for_testing<CoinA>(10100),balance::zero<CoinB>(),receipt);
    };
    let role = if (op < 2) { 0 } else if (op < 4) { 4 } else if (op == 4) { 2 } else { 3 };
    config::set_roles(&cap,&mut config,ctx.sender(),1u128 << role);
    if (mode == 1) { config::remove_role(&cap,&mut config,ctx.sender(),role); };
    if (mode == 2) { config::set_roles(&cap,&mut config,ctx.sender(),1u128 << 1); };
    if (mode == 3) { config::add_role(&cap,&mut config,ctx.sender(),6); config::emergency_pause(&mut config,&ctx); };
    if (mode == 4) { config::update_package_version(&cap,&mut config,config::package_version()+1); };
    if (op == 0) {
        pool::update_fee_rate(&config,&mut pool,2000,&ctx);
        assert!(pool::fee_rate(&pool)==2000,100);
    } else if (op == 1) {
        pool::set_pool_status(&config,&mut pool,true,false,false,false,false,false,&mut ctx);
        assert!(!pool::is_allow_add_liquidity(&pool) && pool::is_allow_swap(&pool),101);
    } else if (op == 2) {
        pool::initialize_rewarder<CoinA,CoinB,CoinC>(&config,&mut pool,&ctx);
        assert!(rewarder::rewarder_index<CoinC>(pool::rewarder_manager(&pool)).is_some(),102);
    } else if (op == 3) {
        pool::update_emission<CoinA,CoinB,CoinC>(&config,&mut pool,&vault,1u128 << 64,&clk,&ctx);
        assert!(rewarder::emissions_per_second(rewarder::borrow_rewarder<CoinC>(pool::rewarder_manager(&pool))) == 1u128 << 64,103);
    } else if (op == 4) {
        let (ba,bb)=pool::balances(&pool);
        let before_a=ba.value();let before_b=bb.value();
        let (a,b)=pool::collect_protocol_fee(&config,&mut pool,&ctx);
        assert!(a.value()==20 && b.value()==0,104);
        let (after_a,after_b)=pool::balances(&pool);
        assert!(after_a.value()+a.value()==before_a && after_b.value()==before_b,105);
        a.destroy_for_testing();b.destroy_zero();
    } else if (op == 5) {
        partner::update_ref_fee_rate(&config,&mut partner,2000,&ctx);
        assert!(partner::ref_fee_rate(&partner)==2000,106);
    } else {
        partner::update_time_range(&config,&mut partner,1,2000,&clk,&mut ctx);
        assert!(partner::start_time(&partner)==1 && partner::end_time(&partner)==2000,107);
    };
    transfer::public_share_object(pool);transfer::public_share_object(vault);transfer::public_share_object(partner);
    transfer::public_share_object(config);transfer::public_transfer(cap,ctx.sender());transfer::public_transfer(partner_cap,ctx.sender());clk.destroy_for_testing();
}

#[test]
fun test_phase1_update_fee_rate_authorized() { exercise(0,0); }

#[test]
#[expected_failure(abort_code = config::ENoPoolManagerPemission, location = cetus_clmm::config)]
fun test_phase1_update_fee_rate_revoked() { exercise(0,1); }

#[test]
#[expected_failure(abort_code = config::ENoPoolManagerPemission, location = cetus_clmm::config)]
fun test_phase1_update_fee_rate_wrong_role() { exercise(0,2); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_update_fee_rate_paused() { exercise(0,3); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_update_fee_rate_deprecated() { exercise(0,4); }

#[test]
fun test_phase1_set_pool_status_authorized() { exercise(1,0); }

#[test]
#[expected_failure(abort_code = config::ENoPoolManagerPemission, location = cetus_clmm::config)]
fun test_phase1_set_pool_status_revoked() { exercise(1,1); }

#[test]
#[expected_failure(abort_code = config::ENoPoolManagerPemission, location = cetus_clmm::config)]
fun test_phase1_set_pool_status_wrong_role() { exercise(1,2); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_set_pool_status_paused() { exercise(1,3); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_set_pool_status_deprecated() { exercise(1,4); }

#[test]
fun test_phase1_initialize_rewarder_authorized() { exercise(2,0); }

#[test]
#[expected_failure(abort_code = config::ENoRewarderManagerPermission, location = cetus_clmm::config)]
fun test_phase1_initialize_rewarder_revoked() { exercise(2,1); }

#[test]
#[expected_failure(abort_code = config::ENoRewarderManagerPermission, location = cetus_clmm::config)]
fun test_phase1_initialize_rewarder_wrong_role() { exercise(2,2); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_initialize_rewarder_paused() { exercise(2,3); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_initialize_rewarder_deprecated() { exercise(2,4); }

#[test]
fun test_phase1_update_emission_authorized() { exercise(3,0); }

#[test]
#[expected_failure(abort_code = config::ENoRewarderManagerPermission, location = cetus_clmm::config)]
fun test_phase1_update_emission_revoked() { exercise(3,1); }

#[test]
#[expected_failure(abort_code = config::ENoRewarderManagerPermission, location = cetus_clmm::config)]
fun test_phase1_update_emission_wrong_role() { exercise(3,2); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_update_emission_paused() { exercise(3,3); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_update_emission_deprecated() { exercise(3,4); }

#[test]
fun test_phase1_collect_protocol_fee_authorized() { exercise(4,0); }

#[test]
#[expected_failure(abort_code = config::ENoProtocolFeeClaimPermission, location = cetus_clmm::config)]
fun test_phase1_collect_protocol_fee_revoked() { exercise(4,1); }

#[test]
#[expected_failure(abort_code = config::ENoProtocolFeeClaimPermission, location = cetus_clmm::config)]
fun test_phase1_collect_protocol_fee_wrong_role() { exercise(4,2); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_collect_protocol_fee_paused() { exercise(4,3); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_collect_protocol_fee_deprecated() { exercise(4,4); }

#[test]
fun test_phase1_update_ref_fee_rate_authorized() { exercise(5,0); }

#[test]
#[expected_failure(abort_code = config::ENoPartnerManagerPermission, location = cetus_clmm::config)]
fun test_phase1_update_ref_fee_rate_revoked() { exercise(5,1); }

#[test]
#[expected_failure(abort_code = config::ENoPartnerManagerPermission, location = cetus_clmm::config)]
fun test_phase1_update_ref_fee_rate_wrong_role() { exercise(5,2); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_update_ref_fee_rate_paused() { exercise(5,3); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_update_ref_fee_rate_deprecated() { exercise(5,4); }

#[test]
fun test_phase1_update_time_range_authorized() { exercise(6,0); }

#[test]
#[expected_failure(abort_code = config::ENoPartnerManagerPermission, location = cetus_clmm::config)]
fun test_phase1_update_time_range_revoked() { exercise(6,1); }

#[test]
#[expected_failure(abort_code = config::ENoPartnerManagerPermission, location = cetus_clmm::config)]
fun test_phase1_update_time_range_wrong_role() { exercise(6,2); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_update_time_range_paused() { exercise(6,3); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_update_time_range_deprecated() { exercise(6,4); }
