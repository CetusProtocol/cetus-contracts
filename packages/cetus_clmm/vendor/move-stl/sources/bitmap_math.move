/// Pure fixed-width bitmap arithmetic. Storage, list topology and migration
/// authority stay in skip_list. This module never receives a UID.
module move_stl::bitmap_math {
    const EZeroWord: u64 = 0;
    /// Number of 256-bit words required for n bits: ceil(n / 256).
    /// Returns zero for n=0. Uses quotient/remainder instead of n+255 so
    /// every u64 input, including u64::MAX, is safe from addition overflow.
    public(package) fun ceil256(n: u64): u64 { n / 256 + if (n % 256 == 0) 0 else 1 }
    /// Minimum number of bitmap levels, including the leaf, whose root fits
    /// in one u256 word. Each parent bit represents one child word.
    /// For example 256 -> 1, 257 -> 2, 65537 -> 3. Returns 1 for zero;
    /// callers validate nonempty universes and their supported maximum depth.
    public(package) fun depth(mut slots: u64): u8 {
        let mut depth = 1;
        while (slots > 256) { slots = ceil256(slots); depth = depth + 1; };
        depth
    }
    /// Number of valid bits at the requested level (leaf is level 0).
    /// Applies ceil256 once per level; e.g. 65537 -> 257 -> 2 -> 1.
    /// Zero stays zero; a positive universe stays 1 beyond its root.
    /// This arithmetic helper does not check that level is a stored level;
    /// callers enforce the configured depth before reading index storage.
    public(package) fun level_bits(mut slots: u64, level: u8): u64 {
        let mut l = 0;
        while (l < level) { slots = ceil256(slots); l = l + 1; };
        slots
    }
    /// Keep bits in the inclusive query direction, preserving their positions.
    /// forward=true keeps [bit,255]; false keeps [0,bit]. Zero is allowed.
    /// The bit=255 reverse branch avoids shifting a u256 by 256.
    public(package) fun directional_mask(word: u256, bit: u8, forward: bool): u256 {
        if (forward) { (word >> bit) << bit }
        else if (bit == 255) { word } else { word & ((1u256 << (bit + 1)) - 1) }
    }
    /// Locate the lowest set bit when forward=true, or highest when false.
    /// Returns a zero-based position in [0,255]. Aborts with EZeroWord for
    /// zero input. Eight binary partitions bound the work independently of
    /// the number of set bits; no linear scan over ticks or bit positions.
    public(package) fun extreme_bit(mut word: u256, forward: bool): u64 {
        assert!(word != 0, EZeroWord);
        let mut result = 0;
        let mut step: u8 = 128;
        while (step > 0) {
            if (forward) {
                let mask = (1u256 << step) - 1;
                if ((word & mask) == 0) { result = result + (step as u64); word = word >> step; }
                else { word = word & mask; };
            } else {
                if (word >> step != 0) { result = result + (step as u64); word = word >> step; };
            };
            step = step / 2;
        };
        result
    }
}
