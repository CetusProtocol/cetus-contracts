#[test_only]
module move_stl::bitmap_word_lifecycle_tests {
    use move_stl::skip_list::{Self, SkipList};
    use move_stl::option_u64::{some, none};

    fun word(list: &SkipList<u64>, level: u8, index: u64, expected: u256) {
        let (exists, actual) = skip_list::bitmap_word_for_test(list,level,index);
        assert!(exists == (expected != 0), 100);
        assert!(actual == expected, 101);
    }

    // Independent expected hierarchy built from the remaining two keys.
    fun hierarchy(list: &SkipList<u64>, a: u64, b: u64, keep_a: bool, keep_b: bool, depth: u8) {
        let mut qa = a; let mut qb = b; let mut l = 0;
        while (l < depth) {
            let ia = qa / 256; let ib = qb / 256;
            let ma = 1u256 << ((qa % 256) as u8);
            let mb = 1u256 << ((qb % 256) as u8);
            if (ia == ib) {
                word(list,l,ia,(if (keep_a) ma else 0) | (if (keep_b) mb else 0));
            } else {
                word(list,l,ia,if (keep_a) ma else 0);
                word(list,l,ib,if (keep_b) mb else 0);
            };
            // Parent presence denotes a nonempty child word, not its node count.
            qa = ia; qb = ib; l = l + 1;
        };
    }

    fun exercise(a: u64, b: u64, size: u64, depth: u8, remove_head_first: bool) {
        let ctx = &mut tx_context::dummy();
        let mut list = skip_list::new<u64>(16,2,7,ctx);
        skip_list::bitmap_begin(&mut list,0,size - 1,1);
        skip_list::bitmap_finalize(&mut list);
        hierarchy(&list,a,b,false,false,depth);
        skip_list::insert(&mut list,a,11);
        hierarchy(&list,a,b,true,false,depth);
        skip_list::insert(&mut list,b,22);
        hierarchy(&list,a,b,true,true,depth);
        assert!(skip_list::head(&list)==some(a) && skip_list::tail(&list)==some(b),102);
        assert!(skip_list::find_next(&list,a,false)==some(b),103);
        assert!(skip_list::find_prev(&list,b,false)==some(a),104);
        assert!(skip_list::find_next(&list,b,false)==none(),105);
        assert!(skip_list::find_prev(&list,a,false)==none(),106);
        if (remove_head_first) {
            assert!(skip_list::remove(&mut list,a)==11,107);
            hierarchy(&list,a,b,false,true,depth);
            assert!(skip_list::head(&list)==some(b),108);
            assert!(skip_list::remove(&mut list,b)==22,109);
        } else {
            assert!(skip_list::remove(&mut list,b)==22,110);
            hierarchy(&list,a,b,true,false,depth);
            assert!(skip_list::tail(&list)==some(a),111);
            assert!(skip_list::remove(&mut list,a)==11,112);
        };
        hierarchy(&list,a,b,false,false,depth);
        assert!(skip_list::head(&list)==none() && skip_list::tail(&list)==none(),113);
        assert!(skip_list::length(&list)==0,114);
        // Recreate the entire hierarchy after every word, including the root, was removed.
        skip_list::insert(&mut list,b,33);
        hierarchy(&list,a,b,false,true,depth);
        assert!(skip_list::remove(&mut list,b)==33,115);
        hierarchy(&list,a,b,false,false,depth);
        skip_list::destroy_empty(list);
    }

    #[test] fun word_lifecycle_0_true() { exercise(0,255,256,1,true); }

    #[test] fun word_lifecycle_0_false() { exercise(0,255,256,1,false); }

    #[test] fun word_lifecycle_1_true() { exercise(254,255,257,2,true); }

    #[test] fun word_lifecycle_1_false() { exercise(254,255,257,2,false); }

    #[test] fun word_lifecycle_2_true() { exercise(255,256,257,2,true); }

    #[test] fun word_lifecycle_2_false() { exercise(255,256,257,2,false); }

    #[test] fun word_lifecycle_3_true() { exercise(65534,65535,65536,2,true); }

    #[test] fun word_lifecycle_3_false() { exercise(65534,65535,65536,2,false); }

    #[test] fun word_lifecycle_4_true() { exercise(65535,65536,65537,3,true); }

    #[test] fun word_lifecycle_4_false() { exercise(65535,65536,65537,3,false); }

    #[test] fun word_lifecycle_5_true() { exercise(65536,65537,887273,3,true); }

    #[test] fun word_lifecycle_5_false() { exercise(65536,65537,887273,3,false); }

    #[test] fun word_lifecycle_6_true() { exercise(0,887272,887273,3,true); }

    #[test] fun word_lifecycle_6_false() { exercise(0,887272,887273,3,false); }

    #[test] fun word_lifecycle_7_true() { exercise(0,16777215,16777216,3,true); }

    #[test] fun word_lifecycle_7_false() { exercise(0,16777215,16777216,3,false); }
}
