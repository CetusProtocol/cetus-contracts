#[test_only]
module move_stl::bitmap_integrity_tests {
    use move_stl::skip_list::{
        SkipList, new, insert, remove, borrow_mut, borrow_node, destroy_empty, find_next, find_prev,
        bitmap_begin, bitmap_build_step, bitmap_cancel_begin, bitmap_cancel_batch,
        bitmap_cancel_finish, bitmap_cursor, bitmap_finalize, bitmap_repair_begin,
        bitmap_repair_clear_batch, bitmap_repair_clear_finish, bitmap_repair_restart,
        bitmap_repair_finalize, bitmap_checked_neighbor, bitmap_cleanup_done_for_test,
        node_height_for_test, bitmap_raw_word_for_test, bitmap_write_word_for_test,
        bitmap_set_count_for_test, bitmap_set_mode_for_test, node_set_prev_for_test,
        set_tail_for_test, bitmap_wrong_state_type_for_test, bitmap_wrong_word_type_for_test,
        set_base_metadata_for_test, add_base_node_for_test,
    };
    use move_stl::option_u64::{some, none, is_some, is_none};
    use sui::tx_context::{Self, TxContext};
    #[test]
    fun bitmap_test_differential_and_lifecycle() {
        let ctx = &mut tx_context::dummy();
        let mut legacy = new<u64>(16, 2, 42, ctx);
        let mut indexed = new<u64>(16, 2, 42, ctx);
        let scores = vector[6, 16, 2546, 2556, 2566, 655356, 655366, 887266];
        let mut i = 0;
        while (i < scores.length()) {
            insert(&mut legacy, scores[i], scores[i]);
            insert(&mut indexed, scores[i], scores[i]); i = i + 1;
        };
        let original = std::bcs::to_bytes(&indexed);
        bitmap_begin(&mut indexed, 6, 887266, 10);
        bitmap_build_step(&mut indexed);
        bitmap_cancel_begin(&mut indexed);
        while (!bitmap_cleanup_done_for_test(&indexed)) { bitmap_cancel_batch(&mut indexed, 128); };
        bitmap_cancel_finish(&mut indexed);
        assert!(original == std::bcs::to_bytes(&indexed), 100);
        bitmap_begin(&mut indexed, 6, 887266, 10);
        while (is_some(&bitmap_cursor(&indexed))) { bitmap_build_step(&mut indexed); };
        bitmap_finalize(&mut indexed);
        let queries = vector[0, 5, 6, 7, 15, 16, 17, 2545, 2546, 2555, 2556, 2565, 2566, 655355, 655356, 655357, 655365, 655366, 655367, 887265, 887266, 887267, 0xffffffffffffffff];
        i = 0;
        while (i < queries.length()) {
            let q = queries[i];
            assert!(find_next(&indexed, q, true) == find_next(&legacy, q, true), 101);
            assert!(find_next(&indexed, q, false) == find_next(&legacy, q, false), 102);
            assert!(find_prev(&indexed, q, true) == find_prev(&legacy, q, true), 103);
            assert!(find_prev(&indexed, q, false) == find_prev(&legacy, q, false), 104);
            i = i + 1;
        };
        // A post-activation insert only has the bottom successor, even between old tall nodes.
        insert(&mut indexed, 256, 9);
        assert!(node_height_for_test(borrow_node(&indexed, 256)) == 1, 105);
        assert!(remove(&mut indexed, 256) == 9, 106);
        let before = std::bcs::to_bytes(&indexed);
        let mut nodes = vector[];
        i = 0;
        while (i < scores.length()) { nodes.push_back(std::bcs::to_bytes(borrow_node(&indexed, scores[i]))); i = i + 1; };
        // A corrupt count and missing leaf must not lock out repair_begin.
        bitmap_write_word_for_test(&mut indexed, 0, 0, 0);
        bitmap_set_count_for_test(&mut indexed, 999);
        bitmap_repair_begin(&mut indexed);
        while (!bitmap_cleanup_done_for_test(&indexed)) { bitmap_repair_clear_batch(&mut indexed, 128); };
        bitmap_repair_clear_finish(&mut indexed);
        bitmap_build_step(&mut indexed);
        bitmap_repair_restart(&mut indexed);
        while (!bitmap_cleanup_done_for_test(&indexed)) { bitmap_repair_clear_batch(&mut indexed, 128); };
        bitmap_repair_clear_finish(&mut indexed);
        while (is_some(&bitmap_cursor(&indexed))) { bitmap_build_step(&mut indexed); };
        bitmap_repair_finalize(&mut indexed);
        assert!(before == std::bcs::to_bytes(&indexed), 107);
        i = 0;
        while (i < scores.length()) {
            assert!(nodes[i] == std::bcs::to_bytes(borrow_node(&indexed, scores[i])), 108);
            i = i + 1;
        };
        i = 0;
        while (i < scores.length()) {
            assert!(remove(&mut indexed, scores[i]) == remove(&mut legacy, scores[i]), 109); i = i + 1;
        };
        destroy_empty(indexed); destroy_empty(legacy);
    }

    #[test]
    #[expected_failure(abort_code = 12, location = move_stl::skip_list)]
    fun bitmap_test_missing_leaf_rejects_skipped_candidate() {
        let ctx = &mut tx_context::dummy();
        let mut list = new<u64>(16, 2, 0, ctx);
        insert(&mut list, 100, 0); insert(&mut list, 120, 0); insert(&mut list, 140, 0);
        bitmap_begin(&mut list, 0, 1000, 1);
        bitmap_build_step(&mut list); bitmap_build_step(&mut list); bitmap_build_step(&mut list);
        bitmap_finalize(&mut list);
        let word = bitmap_raw_word_for_test(&list, 0, 0) ^ (1u256 << 120);
        bitmap_write_word_for_test(&mut list, 0, 0, word);
        find_next(&list, 110, false);
        abort 999
    }
    #[test]
    #[expected_failure(abort_code = 13, location = move_stl::skip_list)]
    fun bitmap_test_frozen_mutable_value() {
        let ctx = &mut tx_context::dummy();
        let mut list = new<u64>(16, 2, 0, ctx);
        insert(&mut list, 10, 0); bitmap_begin(&mut list, 0, 1000, 1);
        *borrow_mut(&mut list, 10) = 5;
        abort 999
    }

    #[test_only]
    fun bitmap_fixture(ctx: &mut TxContext): SkipList<u64> {
        let mut list = new<u64>(16, 2, 1, ctx);
        insert(&mut list, 0, 0); insert(&mut list, 256, 1); insert(&mut list, 65536, 2);
        bitmap_begin(&mut list, 0, 887272, 1);
        bitmap_build_step(&mut list); bitmap_build_step(&mut list); bitmap_build_step(&mut list);
        bitmap_finalize(&mut list); list
    }

    #[test]
    #[expected_failure(abort_code = 12, location = move_stl::skip_list)]
    fun bitmap_test_missing_summary_cannot_return_none() {
        let ctx = &mut tx_context::dummy(); let mut list = bitmap_fixture(ctx);
        bitmap_write_word_for_test(&mut list, 1, 0, 0);
        find_next(&list, 1, true); abort 999
    }
    #[test]
    #[expected_failure(abort_code = 12, location = move_stl::skip_list)]
    fun bitmap_test_summary_points_to_missing_child() {
        let ctx = &mut tx_context::dummy(); let mut list = bitmap_fixture(ctx);
        bitmap_write_word_for_test(&mut list, 0, 1, 0);
        find_next(&list, 1, true); abort 999
    }
    #[test]
    #[expected_failure(abort_code = 12, location = move_stl::skip_list)]
    fun bitmap_test_summary_padding_rejected() {
        let ctx = &mut tx_context::dummy(); let mut list = bitmap_fixture(ctx);
        bitmap_write_word_for_test(&mut list, 2, 0, 1u256 << 255);
        find_next(&list, 1, true); abort 999
    }
    #[test]
    #[expected_failure(abort_code = 12, location = move_stl::skip_list)]
    fun bitmap_test_crossing_reciprocal_rejected() {
        let ctx = &mut tx_context::dummy(); let mut list = bitmap_fixture(ctx);
        node_set_prev_for_test(&mut list, 256, none());
        // The first candidate is valid. The next crossing must independently reject.
        assert!(find_next(&list, 0, true) == some(0), 999);
        bitmap_checked_neighbor(&list, 0, true); abort 999
    }
    #[test]
    #[expected_failure(abort_code = 12, location = move_stl::skip_list)]
    fun bitmap_test_nonempty_missing_tail_rejected() {
        let ctx = &mut tx_context::dummy(); let mut list = bitmap_fixture(ctx);
        set_tail_for_test(&mut list, none()); find_next(&list, 0xffffffffffffffff, false); abort 999
    }
    #[test]
    #[expected_failure(abort_code = 10, location = move_stl::skip_list)]
    fun bitmap_test_unknown_mode_is_not_legacy() {
        let ctx = &mut tx_context::dummy(); let mut list = bitmap_fixture(ctx);
        bitmap_set_mode_for_test(&mut list, 99);
        find_next(&list, 0, true); abort 999
    }
    #[test]
    #[expected_failure(abort_code = 2, location = sui::dynamic_field)]
    fun bitmap_test_wrong_state_type_is_not_legacy() {
        let ctx = &mut tx_context::dummy(); let mut list = new<u64>(16, 2, 0, ctx);
        bitmap_wrong_state_type_for_test(&mut list);
        find_next(&list, 0, true); abort 999
    }
    #[test]
    #[expected_failure(abort_code = 2, location = sui::dynamic_field)]
    fun bitmap_test_wrong_word_type_is_not_empty() {
        let ctx = &mut tx_context::dummy(); let mut list = bitmap_fixture(ctx);
        bitmap_wrong_word_type_for_test(&mut list, 0, 0);
        find_next(&list, 0, true); abort 999
    }
    #[test]
    #[expected_failure(abort_code = 11, location = move_stl::skip_list)]
    fun bitmap_test_unaligned_historical_node_rejected() {
        let ctx = &mut tx_context::dummy(); let mut list = new<u64>(16, 2, 0, ctx);
        insert(&mut list, 7, 0); bitmap_begin(&mut list, 6, 887266, 10);
        bitmap_build_step(&mut list); abort 999
    }
    #[test]
    #[expected_failure(abort_code = 14, location = move_stl::skip_list)]
    fun bitmap_test_zero_cleanup_limit_rejected() {
        let ctx = &mut tx_context::dummy(); let mut list = new<u64>(16, 2, 0, ctx);
        bitmap_begin(&mut list, 0, 65536, 1); bitmap_cancel_begin(&mut list);
        bitmap_cancel_batch(&mut list, 0); abort 999
    }
    #[test]
    fun bitmap_test_paginated_single_layer_legacy_recovery() {
        use sui::test_scenario as scenario;
        // Separate transactions exercise persistent cursors and reset the object
        // runtime cache, as real paginated recovery must.
        let mut sc = scenario::begin(@0x123);
        let mut list = new<u64>(1, 2, 0, sc.ctx());
        set_base_metadata_for_test(&mut list, some(0), some(255 * 400), 256);
        sui::transfer::public_share_object(list);
        let mut i = 0;
        while (i < 256) {
            sc.next_tx(@0x123);
            let mut list = sc.take_shared<SkipList<u64>>();
            let end = if (i + 100 < 256) i + 100 else 256;
            while (i < end) {
                let prev = if (i == 0) none() else some((i - 1) * 400);
                let next = if (i == 255) none() else some((i + 1) * 400);
                add_base_node_for_test(&mut list, i * 400, prev, next, i);
                i = i + 1;
            };
            scenario::return_shared(list);
        };
        sc.next_tx(@0x123);
        let mut list = sc.take_shared<SkipList<u64>>();
        bitmap_begin(&mut list, 0, 887272, 1);
        scenario::return_shared(list);
        let mut finished = false;
        while (!finished) {
            sc.next_tx(@0x123);
            let mut list = sc.take_shared<SkipList<u64>>();
            let mut count = 0;
            while (count < 100 && is_some(&bitmap_cursor(&list))) {
                bitmap_build_step(&mut list); count = count + 1;
            };
            finished = is_none(&bitmap_cursor(&list));
            scenario::return_shared(list);
        };
        sc.next_tx(@0x123);
        let mut list = sc.take_shared<SkipList<u64>>();
        bitmap_finalize(&mut list);
        assert!(find_next(&list, 100801, true) == some(101200), 0);
        scenario::return_shared(list);
        sc.end();
    }

}
