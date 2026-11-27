#[test_only]
module move_stl::bitmap_math_tests {
    use move_stl::bitmap_math::{ceil256, depth, level_bits, directional_mask, extreme_bit};

    #[test]
    fun ceil256_boundaries_and_max() {
        let inputs = vector[0,1,255,256,257,511,512,513,65535,65536,65537,18446744073709551615];
        let expected = vector[0,1,1,1,2,2,2,3,256,256,257,72057594037927936];
        let mut i = 0;
        while (i < inputs.length()) { assert!(ceil256(inputs[i]) == expected[i], 1); i = i + 1; };
    }

    #[test]
    fun depth_boundaries_and_max() {
        let inputs = vector[0,1,255,256,257,65535,65536,65537,16777216,16777217,18446744073709551615];
        let expected = vector[1u8,1,1,1,2,2,2,3,3,4,8];
        let mut i = 0;
        while (i < inputs.length()) { assert!(depth(inputs[i]) == expected[i], 1); i = i + 1; };
    }

    #[test]
    fun level_bits_zero_identity_and_above_root() {
        assert!(level_bits(0,0) == 0 && level_bits(0,255) == 0, 1);
        assert!(level_bits(65537,0) == 65537, 2);
        assert!(level_bits(65537,1) == 257, 3);
        assert!(level_bits(65537,2) == 2, 4);
        assert!(level_bits(65537,3) == 1 && level_bits(65537,255) == 1, 5);
        assert!(level_bits(256,1) == 1 && level_bits(257,1) == 2, 6);
        assert!(level_bits(18446744073709551615,1) == 72057594037927936, 7);
        assert!(level_bits(18446744073709551615,7) == 256, 8);
        assert!(level_bits(18446744073709551615,8) == 1, 9);
    }

    #[test]
    fun directional_mask_every_cut_against_bit_reference() {
        let all = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffu256;
        let mut low = 0u256;
        let mut i: u16 = 0;
        while (i < 256) {
            let one = 1u256 << (i as u8);
            let high = all ^ low;
            low = low | one;
            assert!(directional_mask(all,i as u8,true) == high, 1);
            assert!(directional_mask(all,i as u8,false) == low, 2);
            assert!(directional_mask(0,i as u8,true) == 0, 3);
            assert!(directional_mask(0,i as u8,false) == 0, 4);
            assert!(directional_mask(one,i as u8,true) == one, 5);
            assert!(directional_mask(one,i as u8,false) == one, 6);
            i = i + 1;
        };
    }

    #[test]
    fun directional_mask_sparse_and_empty_results() {
        let word = (1u256 << 2) | (1u256 << 5) | (1u256 << 9);
        assert!(directional_mask(word,5,true) == (1u256 << 5) | (1u256 << 9), 1);
        assert!(directional_mask(word,5,false) == (1u256 << 2) | (1u256 << 5), 2);
        assert!(directional_mask(word,10,true) == 0, 3);
        assert!(directional_mask(word,1,false) == 0, 4);
        assert!(directional_mask(word,0,true) == word, 5);
        assert!(directional_mask(word,255,false) == word, 6);
        assert!(directional_mask(word,0,false) == 0, 7);
        assert!(directional_mask(word,255,true) == 0, 8);
    }

    #[test]
    fun extreme_bit_every_single_bit() {
        let mut i: u16 = 0;
        while (i < 256) {
            let word = 1u256 << (i as u8);
            assert!(extreme_bit(word,true) == (i as u64),1);
            assert!(extreme_bit(word,false) == (i as u64),2);
            i = i + 1;
        };
    }

    #[test]
    fun extreme_bit_multiple_bits_across_binary_partitions() {
        let positions = vector[0u8,1,2,3,7,8,15,16,31,32,63,64,127,128,254,255];
        let mut i = 0;
        while (i < positions.length()) {
            let mut j = i;
            while (j < positions.length()) {
                let word = (1u256 << positions[i]) | (1u256 << positions[j]);
                assert!(extreme_bit(word,true) == (positions[i] as u64),1);
                assert!(extreme_bit(word,false) == (positions[j] as u64),2);
                j = j + 1;
            };
            i = i + 1;
        };
        let all = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffu256;
        assert!(extreme_bit(all,true) == 0 && extreme_bit(all,false) == 255,3);
    }

    #[test]
    #[expected_failure(abort_code=0,location=move_stl::bitmap_math)]
    fun extreme_bit_zero_forward_rejected() { extreme_bit(0,true); }

    #[test]
    #[expected_failure(abort_code=0,location=move_stl::bitmap_math)]
    fun extreme_bit_zero_reverse_rejected() { extreme_bit(0,false); }

    fun mask_near_each_cut(start: u16) {
        let mut cut = start;
        while (cut < start + 32) {
            let points = vector[0u16,if (cut==0) 0 else cut-1,cut,if (cut==255) 255 else cut+1,255];
            let mut j = 0;
            while (j < points.length()) {
                let pos = points[j]; let one = 1u256 << (pos as u8);
                assert!(directional_mask(one,cut as u8,true)==if (pos>=cut) one else 0,10);
                assert!(directional_mask(one,cut as u8,false)==if (pos<=cut) one else 0,11);
                j=j+1;
            };
            cut=cut+1;
        };
    }
    #[test]
    fun depth_every_u64_power_boundary() {
        let mut power = 256u64; let mut expected = 1u8;
        while (expected < 8) {
            assert!(depth(power-1)==expected,1);
            assert!(depth(power)==expected,2);
            assert!(depth(power+1)==expected+1,3);
            assert!(level_bits(power,expected)==1,4);
            assert!(level_bits(power+1,expected)==2,5);
            if (expected < 7) { power=power*256; };
            expected=expected+1;
        };
    }
    #[test] fun mask_cut_bucket_0() { mask_near_each_cut(0); }
    #[test] fun mask_cut_bucket_1() { mask_near_each_cut(32); }
    #[test] fun mask_cut_bucket_2() { mask_near_each_cut(64); }
    #[test] fun mask_cut_bucket_3() { mask_near_each_cut(96); }
    #[test] fun mask_cut_bucket_4() { mask_near_each_cut(128); }
    #[test] fun mask_cut_bucket_5() { mask_near_each_cut(160); }
    #[test] fun mask_cut_bucket_6() { mask_near_each_cut(192); }
    #[test] fun mask_cut_bucket_7() { mask_near_each_cut(224); }
}
