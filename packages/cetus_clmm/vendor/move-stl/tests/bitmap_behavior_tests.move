#[test_only]
module move_stl::bitmap_behavior_tests {
    use move_stl::skip_list::{new, insert, remove, contains, borrow_mut, find_next, find_prev,
        destroy_empty, get_all_socres, bitmap_begin, bitmap_finalize, bitmap_cancel_begin,
        bitmap_repair_begin, bitmap_repair_clear_batch, bitmap_repair_clear_finish};
    use move_stl::option_u64::{some, none};
    #[test]
    fun bitmap_test_depth_boundaries_and_empty() {
        let ctx = &mut tx_context::dummy();
        let sizes = vector[1, 255, 256, 257, 65536, 65537, 887273];
        let mut i = 0;
        while (i < sizes.length()) {
            let mut list = new<u64>(16, 2, 0, ctx);
            bitmap_begin(&mut list, 0, sizes[i] - 1, 1);
            bitmap_finalize(&mut list);
            assert!(find_next(&list, 0, true) == none(), 0);
            insert(&mut list, sizes[i] - 1, 7);
            assert!(find_next(&list, 0, true) == some(sizes[i] - 1), 0);
            assert!(find_prev(&list, 0xffffffffffffffff, true) == some(sizes[i] - 1), 0);
            remove(&mut list, sizes[i] - 1);
            insert(&mut list, 0, 8); remove(&mut list, 0);
            destroy_empty(list); i = i + 1;
        };
    }

    #[test_only]
    fun bitmap_random_trace(seed: u64) {
        let ctx = &mut tx_context::dummy();
        let mut a = new<u64>(16, 2, seed, ctx);
        let mut b = new<u64>(16, 2, seed, ctx);
        bitmap_begin(&mut b, 0, 887272, 1); bitmap_finalize(&mut b);
        let mut state = seed; let mut i = 0;
        while (i < 24) {
            state = (state * 1664525 + 1013904223) % 4294967296;
            let key = (state % 8) * 110001;
            if (contains(&a, key)) { assert!(remove(&mut a, key) == remove(&mut b, key), 100); }
            else { insert(&mut a, key, i); insert(&mut b, key, i); };
            let q = (state / 32) % 887274;
            assert!(find_next(&a,q,true) == find_next(&b,q,true),101);
            assert!(find_next(&a,q,false) == find_next(&b,q,false),102);
            assert!(find_prev(&a,q,true) == find_prev(&b,q,true),103);
            assert!(find_prev(&a,q,false) == find_prev(&b,q,false),104);
            assert!(get_all_socres(&a) == get_all_socres(&b),105);
            i = i + 1;
        };
        sui::transfer::public_share_object(a); sui::transfer::public_share_object(b);
    }

    #[test] fun bitmap_random_seed_1() { bitmap_random_trace(1); }

    #[test] fun bitmap_random_seed_7() { bitmap_random_trace(7); }

    #[test] fun bitmap_random_seed_42() { bitmap_random_trace(42); }

    #[test] fun bitmap_random_seed_12345() { bitmap_random_trace(12345); }

    #[test] fun bitmap_random_seed_987654() { bitmap_random_trace(987654); }

    #[test]
    #[expected_failure(abort_code=13,location=move_stl::skip_list)]
    fun bitmap_frozen_1_insert() { let ctx=&mut tx_context::dummy(); let mut list = new<u64>(16,2,0,ctx); bitmap_begin(&mut list,0,256,1); insert(&mut list,0,1); abort 999 }

    #[test]
    #[expected_failure(abort_code=13,location=move_stl::skip_list)]
    fun bitmap_frozen_1_remove() { let ctx=&mut tx_context::dummy(); let mut list = new<u64>(16,2,0,ctx); bitmap_begin(&mut list,0,256,1); remove(&mut list,0); abort 999 }

    #[test]
    #[expected_failure(abort_code=13,location=move_stl::skip_list)]
    fun bitmap_frozen_1_borrow_mut() { let ctx=&mut tx_context::dummy(); let mut list = new<u64>(16,2,0,ctx); bitmap_begin(&mut list,0,256,1); let _ = borrow_mut(&mut list,0); abort 999 }

    #[test]
    #[expected_failure(abort_code=13,location=move_stl::skip_list)]
    fun bitmap_frozen_1_find_next() { let ctx=&mut tx_context::dummy(); let mut list = new<u64>(16,2,0,ctx); bitmap_begin(&mut list,0,256,1); find_next(&list,0,true); abort 999 }

    #[test]
    #[expected_failure(abort_code=13,location=move_stl::skip_list)]
    fun bitmap_frozen_1_find_prev() { let ctx=&mut tx_context::dummy(); let mut list = new<u64>(16,2,0,ctx); bitmap_begin(&mut list,0,256,1); find_prev(&list,0,true); abort 999 }

    #[test]
    #[expected_failure(abort_code=13,location=move_stl::skip_list)]
    fun bitmap_frozen_1_destroy_empty() { let ctx=&mut tx_context::dummy(); let mut list = new<u64>(16,2,0,ctx); bitmap_begin(&mut list,0,256,1); destroy_empty(list); abort 999 }

    #[test]
    #[expected_failure(abort_code=13,location=move_stl::skip_list)]
    fun bitmap_frozen_2_insert() { let ctx=&mut tx_context::dummy(); let mut list = new<u64>(16,2,0,ctx); bitmap_begin(&mut list,0,256,1); bitmap_cancel_begin(&mut list); insert(&mut list,0,1); abort 999 }

    #[test]
    #[expected_failure(abort_code=13,location=move_stl::skip_list)]
    fun bitmap_frozen_2_remove() { let ctx=&mut tx_context::dummy(); let mut list = new<u64>(16,2,0,ctx); bitmap_begin(&mut list,0,256,1); bitmap_cancel_begin(&mut list); remove(&mut list,0); abort 999 }

    #[test]
    #[expected_failure(abort_code=13,location=move_stl::skip_list)]
    fun bitmap_frozen_2_borrow_mut() { let ctx=&mut tx_context::dummy(); let mut list = new<u64>(16,2,0,ctx); bitmap_begin(&mut list,0,256,1); bitmap_cancel_begin(&mut list); let _ = borrow_mut(&mut list,0); abort 999 }

    #[test]
    #[expected_failure(abort_code=13,location=move_stl::skip_list)]
    fun bitmap_frozen_2_find_next() { let ctx=&mut tx_context::dummy(); let mut list = new<u64>(16,2,0,ctx); bitmap_begin(&mut list,0,256,1); bitmap_cancel_begin(&mut list); find_next(&list,0,true); abort 999 }

    #[test]
    #[expected_failure(abort_code=13,location=move_stl::skip_list)]
    fun bitmap_frozen_2_find_prev() { let ctx=&mut tx_context::dummy(); let mut list = new<u64>(16,2,0,ctx); bitmap_begin(&mut list,0,256,1); bitmap_cancel_begin(&mut list); find_prev(&list,0,true); abort 999 }

    #[test]
    #[expected_failure(abort_code=13,location=move_stl::skip_list)]
    fun bitmap_frozen_2_destroy_empty() { let ctx=&mut tx_context::dummy(); let mut list = new<u64>(16,2,0,ctx); bitmap_begin(&mut list,0,256,1); bitmap_cancel_begin(&mut list); destroy_empty(list); abort 999 }

    #[test]
    #[expected_failure(abort_code=13,location=move_stl::skip_list)]
    fun bitmap_frozen_4_insert() { let ctx=&mut tx_context::dummy(); let mut list = new<u64>(16,2,0,ctx); bitmap_begin(&mut list,0,256,1); bitmap_finalize(&mut list); bitmap_repair_begin(&mut list); insert(&mut list,0,1); abort 999 }

    #[test]
    #[expected_failure(abort_code=13,location=move_stl::skip_list)]
    fun bitmap_frozen_4_remove() { let ctx=&mut tx_context::dummy(); let mut list = new<u64>(16,2,0,ctx); bitmap_begin(&mut list,0,256,1); bitmap_finalize(&mut list); bitmap_repair_begin(&mut list); remove(&mut list,0); abort 999 }

    #[test]
    #[expected_failure(abort_code=13,location=move_stl::skip_list)]
    fun bitmap_frozen_4_borrow_mut() { let ctx=&mut tx_context::dummy(); let mut list = new<u64>(16,2,0,ctx); bitmap_begin(&mut list,0,256,1); bitmap_finalize(&mut list); bitmap_repair_begin(&mut list); let _ = borrow_mut(&mut list,0); abort 999 }

    #[test]
    #[expected_failure(abort_code=13,location=move_stl::skip_list)]
    fun bitmap_frozen_4_find_next() { let ctx=&mut tx_context::dummy(); let mut list = new<u64>(16,2,0,ctx); bitmap_begin(&mut list,0,256,1); bitmap_finalize(&mut list); bitmap_repair_begin(&mut list); find_next(&list,0,true); abort 999 }

    #[test]
    #[expected_failure(abort_code=13,location=move_stl::skip_list)]
    fun bitmap_frozen_4_find_prev() { let ctx=&mut tx_context::dummy(); let mut list = new<u64>(16,2,0,ctx); bitmap_begin(&mut list,0,256,1); bitmap_finalize(&mut list); bitmap_repair_begin(&mut list); find_prev(&list,0,true); abort 999 }

    #[test]
    #[expected_failure(abort_code=13,location=move_stl::skip_list)]
    fun bitmap_frozen_4_destroy_empty() { let ctx=&mut tx_context::dummy(); let mut list = new<u64>(16,2,0,ctx); bitmap_begin(&mut list,0,256,1); bitmap_finalize(&mut list); bitmap_repair_begin(&mut list); destroy_empty(list); abort 999 }

    #[test]
    #[expected_failure(abort_code=13,location=move_stl::skip_list)]
    fun bitmap_frozen_5_insert() { let ctx=&mut tx_context::dummy(); let mut list = new<u64>(16,2,0,ctx); bitmap_begin(&mut list,0,256,1); bitmap_finalize(&mut list); bitmap_repair_begin(&mut list); bitmap_repair_clear_batch(&mut list,128); bitmap_repair_clear_finish(&mut list); insert(&mut list,0,1); abort 999 }

    #[test]
    #[expected_failure(abort_code=13,location=move_stl::skip_list)]
    fun bitmap_frozen_5_remove() { let ctx=&mut tx_context::dummy(); let mut list = new<u64>(16,2,0,ctx); bitmap_begin(&mut list,0,256,1); bitmap_finalize(&mut list); bitmap_repair_begin(&mut list); bitmap_repair_clear_batch(&mut list,128); bitmap_repair_clear_finish(&mut list); remove(&mut list,0); abort 999 }

    #[test]
    #[expected_failure(abort_code=13,location=move_stl::skip_list)]
    fun bitmap_frozen_5_borrow_mut() { let ctx=&mut tx_context::dummy(); let mut list = new<u64>(16,2,0,ctx); bitmap_begin(&mut list,0,256,1); bitmap_finalize(&mut list); bitmap_repair_begin(&mut list); bitmap_repair_clear_batch(&mut list,128); bitmap_repair_clear_finish(&mut list); let _ = borrow_mut(&mut list,0); abort 999 }

    #[test]
    #[expected_failure(abort_code=13,location=move_stl::skip_list)]
    fun bitmap_frozen_5_find_next() { let ctx=&mut tx_context::dummy(); let mut list = new<u64>(16,2,0,ctx); bitmap_begin(&mut list,0,256,1); bitmap_finalize(&mut list); bitmap_repair_begin(&mut list); bitmap_repair_clear_batch(&mut list,128); bitmap_repair_clear_finish(&mut list); find_next(&list,0,true); abort 999 }

    #[test]
    #[expected_failure(abort_code=13,location=move_stl::skip_list)]
    fun bitmap_frozen_5_find_prev() { let ctx=&mut tx_context::dummy(); let mut list = new<u64>(16,2,0,ctx); bitmap_begin(&mut list,0,256,1); bitmap_finalize(&mut list); bitmap_repair_begin(&mut list); bitmap_repair_clear_batch(&mut list,128); bitmap_repair_clear_finish(&mut list); find_prev(&list,0,true); abort 999 }

    #[test]
    #[expected_failure(abort_code=13,location=move_stl::skip_list)]
    fun bitmap_frozen_5_destroy_empty() { let ctx=&mut tx_context::dummy(); let mut list = new<u64>(16,2,0,ctx); bitmap_begin(&mut list,0,256,1); bitmap_finalize(&mut list); bitmap_repair_begin(&mut list); bitmap_repair_clear_batch(&mut list,128); bitmap_repair_clear_finish(&mut list); destroy_empty(list); abort 999 }

    #[test] fun bitmap_random_seed_100() { bitmap_random_trace(100); }

    #[test] fun bitmap_random_seed_101() { bitmap_random_trace(101); }

    #[test] fun bitmap_random_seed_102() { bitmap_random_trace(102); }

    #[test] fun bitmap_random_seed_103() { bitmap_random_trace(103); }

    #[test] fun bitmap_random_seed_104() { bitmap_random_trace(104); }

    #[test] fun bitmap_random_seed_105() { bitmap_random_trace(105); }

    #[test] fun bitmap_random_seed_106() { bitmap_random_trace(106); }

    #[test] fun bitmap_random_seed_107() { bitmap_random_trace(107); }

    #[test] fun bitmap_random_seed_108() { bitmap_random_trace(108); }

    #[test] fun bitmap_random_seed_109() { bitmap_random_trace(109); }

    #[test] fun bitmap_random_seed_110() { bitmap_random_trace(110); }

    #[test] fun bitmap_random_seed_111() { bitmap_random_trace(111); }

    #[test] fun bitmap_random_seed_112() { bitmap_random_trace(112); }

    #[test] fun bitmap_random_seed_113() { bitmap_random_trace(113); }

    #[test] fun bitmap_random_seed_114() { bitmap_random_trace(114); }
}
