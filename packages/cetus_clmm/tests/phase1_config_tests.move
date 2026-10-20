#[test_only]
module cetus_clmm::phase1_config_tests;
use cetus_clmm::config;
use sui::transfer;

fun exercise(op: u8, mode: u8) {
    let mut ctx = tx_context::dummy();
    let (cap, mut config) = config::new_global_config_for_test(&mut ctx, 1000);
    if (op >= 2) { config::add_fee_tier(&mut config, 2, 2000, &ctx); };
    let role = if (op == 0) { 0 } else { 1 };
    // Preserve valid target state; isolate only authorization/version state.
    config::set_roles(&cap, &mut config, ctx.sender(), 1u128 << role);
    if (mode == 1) { config::remove_role(&cap, &mut config, ctx.sender(), role); };
    if (mode == 2) { config::set_roles(&cap, &mut config, ctx.sender(), 1u128 << 3); };
    if (mode == 3) {
        config::add_role(&cap, &mut config, ctx.sender(), 6);
        config::emergency_pause(&mut config, &ctx);
    };
    if (mode == 4) { config::update_package_version(&cap, &mut config, config::package_version() + 1); };
    if (op == 0) {
        config::update_protocol_fee_rate(&mut config, 2000, &ctx);
        assert!(config::protocol_fee_rate(&config) == 2000, 100);
    } else if (op == 1) {
        config::add_fee_tier(&mut config, 2, 2000, &ctx);
        assert!(config::get_fee_rate(2, &config) == 2000, 101);
    } else if (op == 2) {
        config::update_fee_tier(&mut config, 2, 1000, &ctx);
        assert!(config::get_fee_rate(2, &config) == 1000, 102);
    } else {
        config::delete_fee_tier(&mut config, 2, &ctx);
        assert!(!config::fee_tiers(&config).contains(&2), 103);
    };
    transfer::public_share_object(config);
    transfer::public_transfer(cap, ctx.sender());
}

#[test]
fun test_phase1_update_protocol_fee_rate_authorized() { exercise(0, 0); }

#[test]
#[expected_failure(abort_code = config::ENoPoolManagerPemission, location = cetus_clmm::config)]
fun test_phase1_update_protocol_fee_rate_revoked() { exercise(0, 1); }

#[test]
#[expected_failure(abort_code = config::ENoPoolManagerPemission, location = cetus_clmm::config)]
fun test_phase1_update_protocol_fee_rate_wrong_role() { exercise(0, 2); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_update_protocol_fee_rate_paused() { exercise(0, 3); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_update_protocol_fee_rate_deprecated() { exercise(0, 4); }

#[test]
fun test_phase1_add_fee_tier_authorized() { exercise(1, 0); }

#[test]
#[expected_failure(abort_code = config::ENoFeeTierManagerPermission, location = cetus_clmm::config)]
fun test_phase1_add_fee_tier_revoked() { exercise(1, 1); }

#[test]
#[expected_failure(abort_code = config::ENoFeeTierManagerPermission, location = cetus_clmm::config)]
fun test_phase1_add_fee_tier_wrong_role() { exercise(1, 2); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_add_fee_tier_paused() { exercise(1, 3); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_add_fee_tier_deprecated() { exercise(1, 4); }

#[test]
fun test_phase1_update_fee_tier_authorized() { exercise(2, 0); }

#[test]
#[expected_failure(abort_code = config::ENoFeeTierManagerPermission, location = cetus_clmm::config)]
fun test_phase1_update_fee_tier_revoked() { exercise(2, 1); }

#[test]
#[expected_failure(abort_code = config::ENoFeeTierManagerPermission, location = cetus_clmm::config)]
fun test_phase1_update_fee_tier_wrong_role() { exercise(2, 2); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_update_fee_tier_paused() { exercise(2, 3); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_update_fee_tier_deprecated() { exercise(2, 4); }

#[test]
fun test_phase1_delete_fee_tier_authorized() { exercise(3, 0); }

#[test]
#[expected_failure(abort_code = config::ENoFeeTierManagerPermission, location = cetus_clmm::config)]
fun test_phase1_delete_fee_tier_revoked() { exercise(3, 1); }

#[test]
#[expected_failure(abort_code = config::ENoFeeTierManagerPermission, location = cetus_clmm::config)]
fun test_phase1_delete_fee_tier_wrong_role() { exercise(3, 2); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_delete_fee_tier_paused() { exercise(3, 3); }

#[test]
#[expected_failure(abort_code = config::EPackageVersionDeprecate, location = cetus_clmm::config)]
fun test_phase1_delete_fee_tier_deprecated() { exercise(3, 4); }
