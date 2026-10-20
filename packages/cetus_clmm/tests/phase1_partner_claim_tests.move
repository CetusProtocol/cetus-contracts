#[test_only]
module cetus_clmm::phase1_partner_claim_tests;
use cetus_clmm::{config,partner};
use sui::{balance,clock,transfer};
use std::string;
public struct Token {}
fun exercise(mode:u8) {
    let mut ctx=tx_context::dummy();let clk=clock::create_for_testing(&mut ctx);
    let (admin,mut config)=config::new_global_config_for_test(&mut ctx,2000);config::add_role(&admin,&mut config,ctx.sender(),6);
    let (cap,mut partner)=partner::create_partner_for_test(string::utf8(b"first"),1000,0,1000,&clk,&mut ctx);
    let (foreign,other)=partner::create_partner_for_test(string::utf8(b"second"),1000,0,1000,&clk,&mut ctx);
    if (mode!=4) { partner::receive_ref_fee_internal(&mut partner,balance::create_for_testing<Token>(1000)); };
    if (mode==2) { config::emergency_pause(&mut config,&ctx); };
    if (mode==5) { config::update_package_version(&admin,&mut config,config::package_version()+1); };
    let target=if (mode==1) { &foreign } else { &cap };
    let payout=partner::claim_ref_fee_coin<Token>(&config,target,&mut partner,&mut ctx);
    assert!(payout.value()==1000 && partner::balances(&partner).length()==0,100);
    payout.into_balance().destroy_for_testing();
    if (mode==3) { let duplicate=partner::claim_ref_fee_coin<Token>(&config,target,&mut partner,&mut ctx);duplicate.into_balance().destroy_for_testing(); };
    transfer::public_transfer(cap,ctx.sender());transfer::public_transfer(foreign,ctx.sender());transfer::public_transfer(admin,ctx.sender());transfer::public_share_object(config);transfer::public_share_object(partner);transfer::public_share_object(other);clk.destroy_for_testing();
}

#[test]
fun test_phase1_partner_claim_authorized() { exercise(0); }

#[test]
#[expected_failure(abort_code = cetus_clmm::partner::EInvalidPartnerCap, location = cetus_clmm::partner)]
fun test_phase1_partner_claim_wrong_cap() { exercise(1); }

#[test]
#[expected_failure(abort_code = cetus_clmm::config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_partner_claim_paused() { exercise(2); }

#[test]
#[expected_failure(abort_code = cetus_clmm::partner::EInvalidCoinType, location = cetus_clmm::partner)]
fun test_phase1_partner_claim_repeated_claim() { exercise(3); }

#[test]
#[expected_failure(abort_code = cetus_clmm::partner::EInvalidCoinType, location = cetus_clmm::partner)]
fun test_phase1_partner_claim_missing_asset() { exercise(4); }

#[test]
#[expected_failure(abort_code = cetus_clmm::config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_partner_claim_deprecated() { exercise(5); }
