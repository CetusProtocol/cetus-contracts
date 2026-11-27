#[test_only]
module move_stl::bitmap_boundary_tests {
    use move_stl::skip_list::{Self, SkipList};
    use move_stl::option_u64::{OptionU64, some, none};

    fun assert_status(list: &SkipList<u64>, mode: u8, snapshot: u64, indexed: u64,
        cursor: OptionU64, level: u8, word: u64) {
        let (m, s, i, c, l, w) = skip_list::bitmap_status(list);
        assert!(m == mode && s == snapshot && i == indexed, 100);
        assert!(c == cursor && l == level && w == word, 101);
    }

    // Each state fixture uses the real transition APIs, including empty-list completion.
    fun state(mode: u8): SkipList<u64> {
        let mut list = skip_list::new<u64>(16, 2, 0, &mut tx_context::dummy());
        if (mode > 0) { skip_list::bitmap_begin(&mut list, 0, 256, 1); };
        if (mode == 2) { skip_list::bitmap_cancel_begin(&mut list); };
        if (mode >= 3) { skip_list::bitmap_finalize(&mut list); };
        if (mode >= 4) { skip_list::bitmap_repair_begin(&mut list); };
        if (mode == 5) {
            skip_list::bitmap_repair_clear_batch(&mut list, 128);
            skip_list::bitmap_repair_clear_finish(&mut list);
        };
        list
    }

    #[test]
    #[expected_failure(abort_code = 11, location = move_stl::skip_list)]
    fun config_zero_stride() {
        let mut list = state(0);
        skip_list::bitmap_begin(&mut list, 0, 256, 0);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 11, location = move_stl::skip_list)]
    fun config_reversed_range() {
        let mut list = state(0);
        skip_list::bitmap_begin(&mut list, 1, 0, 1);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 11, location = move_stl::skip_list)]
    fun config_unaligned_max() {
        let mut list = state(0);
        skip_list::bitmap_begin(&mut list, 0, 256, 3);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 11, location = move_stl::skip_list)]
    fun config_universe_one_over_max() {
        let mut list = state(0);
        skip_list::bitmap_begin(&mut list, 0, 16777216, 1);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 11, location = move_stl::skip_list)]
    fun config_full_u64_range() {
        let mut list = state(0);
        skip_list::bitmap_begin(&mut list, 0, 18446744073709551615, 1);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 11, location = move_stl::skip_list)]
    fun mapping_wrong_min() {
        let list = state(1);
        skip_list::bitmap_check_mapping(&list, 1, 256, 1);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 11, location = move_stl::skip_list)]
    fun mapping_wrong_max() {
        let list = state(1);
        skip_list::bitmap_check_mapping(&list, 0, 255, 1);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 11, location = move_stl::skip_list)]
    fun mapping_wrong_stride() {
        let list = state(1);
        skip_list::bitmap_check_mapping(&list, 0, 256, 2);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 10, location = move_stl::skip_list)]
    fun begin_rejects_mode_1() {
        let mut list = state(1);
        skip_list::bitmap_begin(&mut list, 0, 256, 1);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 10, location = move_stl::skip_list)]
    fun begin_rejects_mode_2() {
        let mut list = state(2);
        skip_list::bitmap_begin(&mut list, 0, 256, 1);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 10, location = move_stl::skip_list)]
    fun begin_rejects_mode_3() {
        let mut list = state(3);
        skip_list::bitmap_begin(&mut list, 0, 256, 1);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 10, location = move_stl::skip_list)]
    fun begin_rejects_mode_4() {
        let mut list = state(4);
        skip_list::bitmap_begin(&mut list, 0, 256, 1);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 10, location = move_stl::skip_list)]
    fun begin_rejects_mode_5() {
        let mut list = state(5);
        skip_list::bitmap_begin(&mut list, 0, 256, 1);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 10, location = move_stl::skip_list)]
    fun cursor_wrong_state() {
        let mut list = state(3);
        skip_list::bitmap_cursor(&list);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 10, location = move_stl::skip_list)]
    fun build_wrong_state() {
        let mut list = state(3);
        skip_list::bitmap_build_step(&mut list);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 10, location = move_stl::skip_list)]
    fun finalize_wrong_state() {
        let mut list = state(5);
        skip_list::bitmap_finalize(&mut list);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 10, location = move_stl::skip_list)]
    fun repair_finalize_wrong_state() {
        let mut list = state(1);
        skip_list::bitmap_repair_finalize(&mut list);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 10, location = move_stl::skip_list)]
    fun cancel_begin_wrong_state() {
        let mut list = state(3);
        skip_list::bitmap_cancel_begin(&mut list);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 10, location = move_stl::skip_list)]
    fun repair_begin_wrong_state() {
        let mut list = state(1);
        skip_list::bitmap_repair_begin(&mut list);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 10, location = move_stl::skip_list)]
    fun repair_restart_wrong_state() {
        let mut list = state(4);
        skip_list::bitmap_repair_restart(&mut list);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 10, location = move_stl::skip_list)]
    fun cancel_batch_wrong_state() {
        let mut list = state(4);
        skip_list::bitmap_cancel_batch(&mut list, 1);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 10, location = move_stl::skip_list)]
    fun repair_clear_batch_wrong_state() {
        let mut list = state(2);
        skip_list::bitmap_repair_clear_batch(&mut list, 1);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 10, location = move_stl::skip_list)]
    fun cancel_finish_wrong_state() {
        let mut list = state(1);
        skip_list::bitmap_cancel_finish(&mut list);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 10, location = move_stl::skip_list)]
    fun repair_clear_finish_wrong_state() {
        let mut list = state(5);
        skip_list::bitmap_repair_clear_finish(&mut list);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 14, location = move_stl::skip_list)]
    fun limit_0() {

        skip_list::bitmap_check_limit(0);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 14, location = move_stl::skip_list)]
    fun limit_129() {

        skip_list::bitmap_check_limit(129);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 14, location = move_stl::skip_list)]
    fun limit_18446744073709551615() {

        skip_list::bitmap_check_limit(18446744073709551615);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 14, location = move_stl::skip_list)]
    fun bitmap_cancel_batch_limit_0() {
        let mut list = state(2);
        skip_list::bitmap_cancel_batch(&mut list, 0);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 14, location = move_stl::skip_list)]
    fun bitmap_cancel_batch_limit_129() {
        let mut list = state(2);
        skip_list::bitmap_cancel_batch(&mut list, 129);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 14, location = move_stl::skip_list)]
    fun bitmap_repair_clear_batch_limit_0() {
        let mut list = state(4);
        skip_list::bitmap_repair_clear_batch(&mut list, 0);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 14, location = move_stl::skip_list)]
    fun bitmap_repair_clear_batch_limit_129() {
        let mut list = state(4);
        skip_list::bitmap_repair_clear_batch(&mut list, 129);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 10, location = move_stl::skip_list)]
    fun bitmap_cancel_finish_one_word_remaining() {
        let mut list = state(2); skip_list::bitmap_cancel_batch(&mut list, 2);
        skip_list::bitmap_cancel_finish(&mut list);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 10, location = move_stl::skip_list)]
    fun bitmap_repair_clear_finish_one_word_remaining() {
        let mut list = state(4); skip_list::bitmap_repair_clear_batch(&mut list, 2);
        skip_list::bitmap_repair_clear_finish(&mut list);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 12, location = move_stl::skip_list)]
    fun build_empty_mode_1() {
        let mut list = state(1);
        skip_list::bitmap_build_step(&mut list);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 12, location = move_stl::skip_list)]
    fun build_empty_mode_5() {
        let mut list = state(5);
        skip_list::bitmap_build_step(&mut list);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 12, location = move_stl::skip_list)]
    fun finalize_before_last_node() {
        let mut list = state(0); skip_list::insert(&mut list, 0, 7); skip_list::bitmap_begin(&mut list, 0, 256, 1);
        skip_list::bitmap_finalize(&mut list);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 12, location = move_stl::skip_list)]
    fun build_after_last_node() {
        let mut list = state(0); skip_list::insert(&mut list, 0, 7); skip_list::bitmap_begin(&mut list, 0, 256, 1); skip_list::bitmap_build_step(&mut list);
        skip_list::bitmap_build_step(&mut list);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 12, location = move_stl::skip_list)]
    fun build_rejects_broken_prev() {
        let mut list = state(0); skip_list::insert(&mut list, 0, 7); skip_list::bitmap_begin(&mut list, 0, 256, 1); skip_list::node_set_prev_for_test(&mut list, 0, some(0));
        skip_list::bitmap_build_step(&mut list);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 12, location = move_stl::skip_list)]
    fun bitmap_cursor_changed_snapshot() {
        let mut list = state(0); skip_list::insert(&mut list, 0, 7); skip_list::bitmap_begin(&mut list, 0, 256, 1); skip_list::set_tail_for_test(&mut list, none());
        skip_list::bitmap_cursor(&list);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 12, location = move_stl::skip_list)]
    fun bitmap_build_step_changed_snapshot() {
        let mut list = state(0); skip_list::insert(&mut list, 0, 7); skip_list::bitmap_begin(&mut list, 0, 256, 1); skip_list::set_tail_for_test(&mut list, none());
        skip_list::bitmap_build_step(&mut list);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 12, location = move_stl::skip_list)]
    fun bitmap_finalize_changed_snapshot() {
        let mut list = state(0); skip_list::insert(&mut list, 0, 7); skip_list::bitmap_begin(&mut list, 0, 256, 1); skip_list::set_tail_for_test(&mut list, none());
        skip_list::bitmap_finalize(&mut list);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 12, location = move_stl::skip_list)]
    fun bitmap_cancel_begin_changed_snapshot() {
        let mut list = state(0); skip_list::insert(&mut list, 0, 7); skip_list::bitmap_begin(&mut list, 0, 256, 1); skip_list::set_tail_for_test(&mut list, none());
        skip_list::bitmap_cancel_begin(&mut list);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 11, location = move_stl::skip_list)]
    fun insert_below() {
        let mut list = state(0); skip_list::bitmap_begin(&mut list, 10, 30, 10); skip_list::bitmap_finalize(&mut list);
        skip_list::insert(&mut list, 9, 7);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 11, location = move_stl::skip_list)]
    fun insert_above() {
        let mut list = state(0); skip_list::bitmap_begin(&mut list, 10, 30, 10); skip_list::bitmap_finalize(&mut list);
        skip_list::insert(&mut list, 31, 7);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 11, location = move_stl::skip_list)]
    fun insert_unaligned() {
        let mut list = state(0); skip_list::bitmap_begin(&mut list, 10, 30, 10); skip_list::bitmap_finalize(&mut list);
        skip_list::insert(&mut list, 11, 7);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 0, location = move_stl::skip_list)]
    fun insert_duplicate() {
        let mut list = state(3); skip_list::insert(&mut list, 0, 7);
        skip_list::insert(&mut list, 0, 8);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 12, location = move_stl::skip_list)]
    fun remove_missing_leaf() {
        let mut list = state(3); skip_list::insert(&mut list, 0, 7); skip_list::insert(&mut list, 1, 8); skip_list::bitmap_write_word_for_test(&mut list, 0, 0, 2);
        skip_list::remove(&mut list, 0);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 12, location = move_stl::skip_list)]
    fun health_wrong_count() {
        let mut list = state(3); skip_list::bitmap_set_count_for_test(&mut list, 1);
        skip_list::find_next(&list, 0, true);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 12, location = move_stl::skip_list)]
    fun health_empty_with_root() {
        let mut list = state(3); skip_list::bitmap_write_word_for_test(&mut list, 1, 0, 1);
        skip_list::find_next(&list, 0, true);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 12, location = move_stl::skip_list)]
    fun leaf_padding() {
        let mut list = state(3); skip_list::insert(&mut list, 256, 1); skip_list::bitmap_write_word_for_test(&mut list, 0, 1, 2);
        skip_list::find_next(&list, 256, true);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 13, location = move_stl::skip_list)]
    fun neighbor_frozen_1() {
        let list = state(1);
        skip_list::bitmap_checked_neighbor(&list, 0, true);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 13, location = move_stl::skip_list)]
    fun neighbor_frozen_2() {
        let list = state(2);
        skip_list::bitmap_checked_neighbor(&list, 0, true);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 13, location = move_stl::skip_list)]
    fun neighbor_frozen_4() {
        let list = state(4);
        skip_list::bitmap_checked_neighbor(&list, 0, true);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 13, location = move_stl::skip_list)]
    fun neighbor_frozen_5() {
        let list = state(5);
        skip_list::bitmap_checked_neighbor(&list, 0, true);
        abort 999
    }

    #[test]
    fun status_and_mapping_all_modes() {
        let mut list = state(0);
        assert_status(&list, 0, 0, 0, none(), 0, 0);
        skip_list::assert_bitmap_available(&list);
        skip_list::insert(&mut list, 256, 7);
        skip_list::bitmap_begin(&mut list, 0, 256, 1);
        skip_list::bitmap_check_mapping(&list, 0, 256, 1);
        assert_status(&list, 1, 1, 0, some(256), 0, 0);
        skip_list::bitmap_build_step(&mut list);
        assert_status(&list, 1, 1, 1, none(), 0, 0);
        skip_list::bitmap_finalize(&mut list);
        assert!(skip_list::bitmap_mode(&list) == 3, 3);
        skip_list::assert_bitmap_available(&list);
        skip_list::bitmap_repair_begin(&mut list);
        assert_status(&list, 4, 1, 1, none(), 0, 0);
        skip_list::bitmap_repair_clear_batch(&mut list, 1);
        assert_status(&list, 4, 1, 1, none(), 0, 1);
        skip_list::bitmap_repair_clear_batch(&mut list, 1);
        assert_status(&list, 4, 1, 1, none(), 1, 0);
        skip_list::bitmap_repair_clear_batch(&mut list, 1);
        assert_status(&list, 4, 1, 1, none(), 2, 0);
        skip_list::bitmap_repair_clear_finish(&mut list);
        assert_status(&list, 5, 1, 0, some(256), 2, 0);
        skip_list::bitmap_repair_restart(&mut list);
        assert_status(&list, 4, 1, 0, some(256), 0, 0);
        skip_list::bitmap_repair_clear_batch(&mut list, 128);
        skip_list::bitmap_repair_clear_finish(&mut list);
        skip_list::bitmap_build_step(&mut list);
        skip_list::bitmap_repair_finalize(&mut list);
        assert!(skip_list::remove(&mut list, 256) == 7, 10);
        skip_list::destroy_empty(list);
    }

    #[test]
    fun cancel_empty_counts_missing_words_and_completed_batch_is_noop() {
        let mut list = state(2);
        skip_list::bitmap_check_limit(1); skip_list::bitmap_check_limit(128);
        skip_list::bitmap_cancel_batch(&mut list, 1);
        assert_status(&list, 2, 0, 0, none(), 0, 1);
        skip_list::bitmap_cancel_batch(&mut list, 1);
        assert_status(&list, 2, 0, 0, none(), 1, 0);
        skip_list::bitmap_cancel_batch(&mut list, 128);
        assert_status(&list, 2, 0, 0, none(), 2, 0);
        skip_list::bitmap_cancel_batch(&mut list, 128);
        assert_status(&list, 2, 0, 0, none(), 2, 0);
        skip_list::bitmap_cancel_finish(&mut list);
        assert_status(&list, 0, 0, 0, none(), 0, 0);
        skip_list::destroy_empty(list);
    }

    #[test]
    fun queries_near_u64_max_and_stride_rounding() {
        let max = 18446744073709551615;
        let min = max - 20;
        let mut list = state(0);
        skip_list::bitmap_begin(&mut list, min, max, 10);
        skip_list::bitmap_finalize(&mut list);
        skip_list::insert(&mut list, min, 1); skip_list::insert(&mut list, max, 2);
        let queries = vector[0, min - 1, min, min + 1, max - 1, max];
        let mut i = 0;
        while (i < queries.length()) {
            let q = queries[i];
            let forward_inclusive = if (q <= min) some(min) else some(max);
            let forward_exclusive = if (q < min) some(min) else if (q < max) some(max) else none();
            let backward_inclusive = if (q < min) none() else if (q < max) some(min) else some(max);
            let backward_exclusive = if (q <= min) none() else some(min);
            assert!(skip_list::find_next(&list, q, true) == forward_inclusive, 0);
            assert!(skip_list::find_next(&list, q, false) == forward_exclusive, 1);
            assert!(skip_list::find_prev(&list, q, true) == backward_inclusive, 2);
            assert!(skip_list::find_prev(&list, q, false) == backward_exclusive, 3);
            i = i + 1;
        };
        assert!(skip_list::bitmap_checked_neighbor(&list, min, false) == none(), 4);
        assert!(skip_list::bitmap_checked_neighbor(&list, min, true) == some(max), 5);
        assert!(skip_list::bitmap_checked_neighbor(&list, max, false) == some(min), 6);
        assert!(skip_list::bitmap_checked_neighbor(&list, max, true) == none(), 7);
        skip_list::remove(&mut list, min); skip_list::remove(&mut list, max);
        skip_list::destroy_empty(list);
    }

    #[test]
    fun singleton_max_score_and_max_stride() {
        let max = 18446744073709551615;
        let mut list = state(0);
        skip_list::bitmap_begin(&mut list, max, max, max);
        skip_list::bitmap_finalize(&mut list);
        skip_list::insert(&mut list, max, 7);
        assert!(skip_list::find_next(&list, max, false) == none(), 0);
        assert!(skip_list::find_prev(&list, max, false) == none(), 1);
        assert!(skip_list::find_next(&list, max, true) == some(max), 2);
        assert!(skip_list::find_prev(&list, max, true) == some(max), 3);
        skip_list::remove(&mut list, max); skip_list::destroy_empty(list);
        let mut list = state(0);
        skip_list::bitmap_begin(&mut list, 0, max, max);
        skip_list::bitmap_finalize(&mut list);
        skip_list::insert(&mut list, 0, 1); skip_list::insert(&mut list, max, 2);
        assert!(skip_list::find_next(&list, 1, true) == some(max), 4);
        assert!(skip_list::find_prev(&list, max - 1, true) == some(0), 5);
        skip_list::remove(&mut list, 0); skip_list::remove(&mut list, max);
        skip_list::destroy_empty(list);
    }
    #[test]
    fun find_predecessor_then_successor_and_zero_boundary() {
        let mut list = state(3);
        assert!(skip_list::find_nearest(&list, 0) == none(), 0);
        skip_list::insert(&mut list, 1, 1); skip_list::insert(&mut list, 256, 2);
        assert!(skip_list::find_nearest(&list, 0) == some(1), 1);
        assert!(skip_list::find_nearest(&list, 1) == some(1), 2);
        assert!(skip_list::find_nearest(&list, 255) == some(1), 3);
        assert!(skip_list::find_nearest(&list, 256) == some(256), 4);
        skip_list::insert(&mut list, 0, 3);
        assert!(skip_list::find_prev(&list, 0, false) == none(), 5);
        assert!(skip_list::find_prev(&list, 0, true) == some(0), 6);
        skip_list::remove(&mut list, 0); skip_list::remove(&mut list, 1);
        skip_list::remove(&mut list, 256); skip_list::destroy_empty(list);
    }

    #[test]
    fun legacy_neighbor_singleton_and_endpoints() {
        let mut list = state(0);
        skip_list::insert(&mut list, 0, 1);
        assert!(skip_list::bitmap_checked_neighbor(&list, 0, false) == none(), 0);
        assert!(skip_list::bitmap_checked_neighbor(&list, 0, true) == none(), 1);
        skip_list::insert(&mut list, 256, 2);
        assert!(skip_list::bitmap_checked_neighbor(&list, 0, true) == some(256), 2);
        assert!(skip_list::bitmap_checked_neighbor(&list, 256, false) == some(0), 3);
        skip_list::remove(&mut list, 0); skip_list::remove(&mut list, 256);
        skip_list::destroy_empty(list);
    }

    #[test]
    fun empty_repair_completed_scan_and_finalize() {
        let mut list = state(4);
        skip_list::bitmap_repair_clear_batch(&mut list, 128);
        skip_list::bitmap_repair_clear_batch(&mut list, 1);
        assert_status(&list, 4, 0, 0, none(), 2, 0);
        skip_list::bitmap_repair_clear_finish(&mut list);
        assert!(skip_list::bitmap_cursor(&list) == none(), 0);
        skip_list::bitmap_repair_finalize(&mut list);
        assert!(skip_list::find_next(&list, 0, true) == none(), 1);
        assert!(skip_list::find_prev(&list, 256, true) == none(), 2);
        skip_list::destroy_empty(list);
    }

    #[test]
    #[expected_failure(abort_code = 12, location = move_stl::skip_list)]
    fun repair_finalize_before_last_node() {
        let mut list = state(3);
        skip_list::insert(&mut list, 256, 1);
        skip_list::bitmap_repair_begin(&mut list);
        skip_list::bitmap_repair_clear_batch(&mut list, 128);
        skip_list::bitmap_repair_clear_finish(&mut list);
        skip_list::bitmap_repair_finalize(&mut list);
        abort 999
    }

    #[test]
    #[expected_failure(abort_code = 12, location = move_stl::skip_list)]
    fun finalize_rejects_padding_in_unvisited_boundary_word() {
        let mut list = state(1);
        // Empty build: root is empty, but the final leaf contains an out-of-range bit.
        skip_list::bitmap_write_word_for_test(&mut list, 0, 1, 2);
        skip_list::bitmap_finalize(&mut list);
        abort 999
    }
}
