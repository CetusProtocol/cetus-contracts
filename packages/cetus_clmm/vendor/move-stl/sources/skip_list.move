module move_stl::skip_list {
    use std::vector::push_back;
    use move_stl::bitmap_math;
    use move_stl::option_u64::{Self, OptionU64, none, some, is_none, is_some, swap_or_fill, is_some_and_lte};
    use move_stl::random::{Self, Random};
    use sui::dynamic_field as field;

    const ENodeAlreadyExist: u64 = 0;
    const ENodeDoesNotExist: u64 = 1;
    const ESkipListNotEmpty: u64 = 3;

    #[allow(unused_const)]
    const ESkipListIsEmpty: u64 = 4;
    const EInvalidListP: u64 = 5;
    const EInvalidMaxLevel: u64 = 6;

    /// The skip list.
    public struct SkipList<phantom V: store> has key, store {
        /// The id of this skip list.
        id: UID,
        /// The skip list header of each level. i.e. the score of node.
        head: vector<OptionU64>,
        /// The level0's tail of skip list. i.e. the score of node.
        tail: OptionU64,
        /// The current level of this skip list.
        level: u64,
        /// The max level of this skip list.
        max_level: u64,
        /// Basic probability of random of node indexer's level i.e. (list_p = 2, level2 = 1/2, level3 = 1/4).
        list_p: u64,

        /// The size of skip list
        size: u64,

        /// The random for generate ndoe's level
        random: Random,
    }

    /// The node of skip list.
    public struct Node<V: store> has store {
        /// The score of node.
        score: u64,
        /// The next node score of node's each level.
        nexts: vector<OptionU64>,
        /// The prev node score of node.
        prev: OptionU64,
        /// The data being stored
        value: V,
    }

    /// Create a new empty skip list.
    public fun new<V: store>(max_level: u64, list_p: u64, seed: u64, ctx: &mut TxContext): SkipList<V> {
        assert!(list_p > 1, EInvalidListP);
        // A zero max level makes rand_level return 0 after the first insert.
        // The node is then stored without bottom links, so traversal and bitmap
        // migration can never reach it.
        assert!(max_level > 0, EInvalidMaxLevel);
        let list = SkipList<V> {
            id: object::new(ctx),
            head: vector::empty(),
            tail: none(),
            level: 0,
            max_level,
            list_p,
            random: random::new(seed),
            size: 0
        };
        list
    }

    /// Return the length of the skip list.
    public fun length<V: store>(list: &SkipList<V>): u64 {
        list.size
    }

    /// Returns true if the skip list is empty (if `length` returns `0`)
    public fun is_empty<V: store>(list: &SkipList<V>): bool {
        list.size == 0
    }

    /// Return the head of the skip list.
    public fun head<V: store>(list: &SkipList<V>): OptionU64 {
        if (is_empty(list)) {
            return none()
        };
        *vector::borrow(&list.head, 0)
    }

    /// Return the tail of the skip list.
    public fun tail<V: store>(list: &SkipList<V>): OptionU64 {
        list.tail
    }

    /// Destroys an empty skip list
    /// Aborts with `ETableNotEmpty` if the list still contains values
    public fun destroy_empty<V: store + drop>(mut list: SkipList<V>) {
        let mode = checked_bitmap_mode(&list);
        if (mode == BITMAP) {
            let _ = bitmap_health(&list);
            assert!(list.size == 0, ESkipListNotEmpty);
            let _: BitmapState = field::remove(&mut list.id, BitmapStateKey {});
        };
        let SkipList<V> {
            id,
            head: _,
            tail: _,
            level: _,
            max_level: _,
            list_p: _,
            random: _,
            size,
        } = list;
        assert!(size == 0, ESkipListNotEmpty);
        object::delete(id);
    }

    /// Returns true if there is a value associated with the score `score` in skip list
    public fun contains<V: store>(list: &SkipList<V>, score: u64): bool {
        field::exists_with_type<u64, Node<V>>(&list.id, score)
    }

    /// Acquire an immutable reference to the `score` element of the skip list `list`.
    /// Aborts if element not exist.
    public fun borrow<V: store>(list: &SkipList<V>, score: u64): &V {
        &field::borrow<u64, Node<V>>(&list.id, score).value
    }

    /// Return a mutable reference to the `score` element in the skip list `list`.
    /// Aborts if element is not exist.
    public fun borrow_mut<V: store>(list: &mut SkipList<V>, score: u64): &mut V {
        assert_bitmap_available(list);
        &mut field::borrow_mut<u64, Node<V>>(&mut list.id, score).value
    }

    /// Acquire an immutable reference to the `score` node of the skip list `list`.
    /// Aborts if node not exist.
    public fun borrow_node<V: store>(list: &SkipList<V>, score: u64): &Node<V> {
        field::borrow<u64, Node<V>>(&list.id, score)
    }

    /// Return a mutable reference to the `score` node in the skip list `list`.
    /// Aborts if node is not exist.
    public fun borrow_mut_node<V: store>(list: &mut SkipList<V>, score: u64): &mut Node<V> {
        assert_bitmap_available(list);
        field::borrow_mut<u64, Node<V>>(&mut list.id, score)
    }

    /// Return the metadata info of skip list.
    public fun metadata<V: store>(list: &SkipList<V>): (vector<OptionU64>, OptionU64, u64, u64, u64, u64) {
        (
            list.head,
            list.tail,
            list.level,
            list.max_level,
            list.list_p,
            list.size
        )
    }

    /// Return the next score of the node.
    public fun next_score<V: store>(node: &Node<V>): OptionU64 {
        *vector::borrow(&node.nexts, 0)
    }

    /// Return the prev score of the node.
    public fun prev_score<V: store>(node: &Node<V>): OptionU64 {
        node.prev
    }

    /// Return the immutable reference to the ndoe's value.
    public fun borrow_value<V: store>(node: &Node<V>): &V {
        &node.value
    }

    /// Return the mutable reference to the ndoe's value.
    public fun borrow_mut_value<V: store>(node: &mut Node<V>): &mut V {
        &mut node.value
    }

    /// Insert a score-value into skip list, abort if the score alread exist.
    public fun insert<V: store>(list: &mut SkipList<V>, score: u64, v: V) {
        if (checked_bitmap_mode(list) == BITMAP) { bitmap_insert(list, score, v); return };
        assert!(!contains(list, score), ENodeAlreadyExist);
        let (level, mut new_node) = create_node(list, score, v);
        let (mut l, mut nexts, mut prev) = (list.level, &mut list.head, none());
        let mut opt_l0_next_score = none();
        while(l > 0) {
            let mut opt_next_score = vector::borrow_mut(nexts, l - 1);
            while (is_some_and_lte(opt_next_score, score)) {
                let node =
                    field::borrow_mut<u64, Node<V>>(&mut list.id, option_u64::borrow(opt_next_score));
                prev = some(node.score);
                nexts = &mut node.nexts;
                opt_next_score = vector::borrow_mut(nexts, l - 1);
            };
            if (level >= l) {
                vector::push_back(&mut new_node.nexts, *opt_next_score);
                if (l == 1) {
                    new_node.prev = prev;
                    if (is_some(opt_next_score)) {
                        opt_l0_next_score = *opt_next_score;
                    } else {
                        list.tail = some(score);
                    }
                };
                swap_or_fill(opt_next_score, score);
            };
            l = l - 1;
        };
        if (is_some(&opt_l0_next_score)) {
            let next_node = borrow_mut_node(list, option_u64::borrow(&opt_l0_next_score));
            next_node.prev = some(score);
        };

        vector::reverse(&mut new_node.nexts);
        field::add(&mut list.id, score, new_node);
        list.size = list.size + 1;
    }

    /// Remove the score-value from skip list, abort if the score not exist in list.
    public fun remove<V: store>(list: &mut SkipList<V>, score: u64): V {
        if (checked_bitmap_mode(list) == BITMAP) { return bitmap_remove(list, score) };
        assert!(contains(list, score), ENodeDoesNotExist);
        let (mut l, mut nexts) = (list.level, &mut list.head);
        let node: Node<V> = field::remove(&mut list.id, score);
        while (l > 0) {
            let mut opt_next_score = vector::borrow_mut(nexts, l - 1);
            while (is_some_and_lte(opt_next_score, score)) {
                let next_score = option_u64::borrow(opt_next_score);
                if (next_score == score) {
                    *opt_next_score = *vector::borrow(&node.nexts, l - 1);
                } else {
                    let node = borrow_mut_node(list, next_score);
                    nexts = &mut node.nexts;
                    opt_next_score = vector::borrow_mut(nexts, l - 1);
                }
            };
            l = l - 1;
        };

        if (option_u64::borrow(&list.tail) == score) {
            list.tail = node.prev;
        };

        let opt_l0_next_score = vector::borrow(&node.nexts, 0);
        if (is_some(opt_l0_next_score)) {
            let next_node = borrow_mut_node(list, option_u64::borrow(opt_l0_next_score));
            next_node.prev = node.prev;
        };
        list.size = list.size - 1;

        drop_node(node)
    }

    /// Return the next score.
    public fun find_next<V: store>(list: &SkipList<V>, score: u64, include: bool): OptionU64 {
        let mode = checked_bitmap_mode(list);
        if (mode == BITMAP) { return bitmap_find(list, score, include, true) };
        let opt_finded_score = find_legacy(list, score);
        if (is_none(&opt_finded_score)) {
            return opt_finded_score
        };
        let finded_score = option_u64::borrow(&opt_finded_score);
        if ((include && finded_score == score) || (finded_score > score)) {
            return opt_finded_score
        };
        let node = borrow_node(list, finded_score);
        *vector::borrow(&node.nexts, 0)
    }

    /// Return the prev socre.
    public fun find_prev<V: store>(list: &SkipList<V>, score: u64, include: bool): OptionU64 {
        let mode = checked_bitmap_mode(list);
        if (mode == BITMAP) { return bitmap_find(list, score, include, false) };
        let opt_finded_score = find_legacy(list, score);
        if (is_none(&opt_finded_score)) {
            return opt_finded_score
        };
        let finded_score = option_u64::borrow(&opt_finded_score);
        if ((include && finded_score == score) || (finded_score < score)) {
            return opt_finded_score
        };
        let node = borrow_node(list, finded_score);
        node.prev
    }

    /// Find the nearest score. 1. score, 2. prev, 3. next
    fun find<V: store>(list: &SkipList<V>, score: u64): OptionU64 {
        if (checked_bitmap_mode(list) == BITMAP) {
            let prev = bitmap_find(list, score, true, false);
            return if (is_some(&prev)) prev else bitmap_find(list, score, true, true)
        };
        find_legacy(list, score)
    }

    /// Legacy nearest-score search; the caller has already validated Legacy mode.
    fun find_legacy<V: store>(list: &SkipList<V>, score: u64): OptionU64 {
        if (list.size == 0) {
            return none()
        };
        let (mut l, mut nexts,mut current_score) = (list.level, &list.head, none());
        while (l > 0) {
            let mut opt_next_score = *vector::borrow(nexts, l - 1);
            while(is_some_and_lte(&opt_next_score, score)) {
                let next_score = option_u64::borrow(&opt_next_score);
                if (next_score == score) {
                    return some(next_score)
                } else {
                    let node = borrow_node(list, next_score);
                    current_score = opt_next_score;
                    nexts = &node.nexts;
                    opt_next_score = *vector::borrow(nexts, l - 1);
                };
            };
            if (l == 1 && is_some(&current_score)) {
                return current_score
            };
            l = l - 1;
        };
        return *vector::borrow(&list.head, 0)
    }

    fun rand_level<V: store>(seed: u64, list: &SkipList<V>): u64 {
        let mut level = 1;
        let mut mod = list.list_p;
        while ((seed % mod) == 0 && level < list.level + 1) {
            mod = mod * list.list_p;
            level = level + 1;
            if (level > list.level) {
                if (level >= list.max_level) {
                    level = list.max_level;
                    break
                } else {
                    level = list.level + 1;
                    break
                }
            }
        };
        level
    }

    /// Create a new skip list node
    fun create_node<V: store>(list: &mut SkipList<V>, score: u64, value: V): (u64, Node<V>) {
        let rand = random::rand(&mut list.random);
        let level = rand_level(rand, list);

        // Create a new level for skip list.
        if (level > list.level) {
            list.level = level;
            push_back(&mut list.head, none());
        };

        (
            level,
            Node<V> {
                score,
                nexts: vector::empty(),
                prev: none(),
                value
            }
        )
    }

    fun drop_node<V: store>(node: Node<V>): V {
        let Node {
            score: _,
            nexts: _,
            prev: _,
            value,
        } = node;
        value
    }

    // tests
    // ============================================================================================
    #[test_only]
    use std::debug;

    #[allow(unused)]
    public struct Item has drop, store {
        n: u64,
        score: u64,
        finded: OptionU64,
    }

    #[test_only]
    public fun find_nearest<V: store>(list: &SkipList<V>, score: u64): OptionU64 {
        list.find(score)
    }

    #[test_only]
    public fun print_skip_list<V: store>(list: &SkipList<V>) {
        if (list.length() == 0) {
            return
        };
        let mut next_score = list.head();
        while (next_score.is_some()) {
            let node = list.borrow_node(next_score.borrow());
            next_score = node.next_score();
            debug::print(node);
        };
    }

    #[test_only]
    public fun check_skip_list<V: store>(list: &SkipList<V>) {
        if (list.level == 0) {
            assert!(length(list) == 0, 0);
            return
        };

        // Check level 0
        let (
            mut size,
            mut opt_next_score,
            mut tail,
            mut prev,
            mut current_score,
        ) = (
            0,
            list.head(),
            none(),
            none(),
            none()
        );
        while (opt_next_score.is_some()) {
            let next_score = opt_next_score.borrow();
            let next_node = list.borrow_node(next_score);
            if (current_score.is_some()) {
                assert!(next_score > current_score.borrow(), 0);
            };
            assert!(next_node.score == next_score, 0);
            if (prev.is_none()) {
                assert!(next_node.prev.is_none(), 0)
            } else {
                assert!(next_node.prev.borrow() == prev.borrow(), 0);
            };
            prev = some(next_node.score);
            tail = some(next_node.score);
            current_score.swap_or_fill(next_node.score);
            size = size + 1;
            opt_next_score = next_node.next_score();
        };
        if (tail.is_none()) {
            assert!(list.tail.is_none(), 0);
        } else {
            assert!(list.tail.borrow() == tail.borrow(), 0);
        };
        assert!(size == list.length(), 0);

        // Check indexer levels
        let mut l = list.level - 1;
        while (l > 0) {
            let mut opt_next_l_score = list.head.borrow(l);
            let mut opt_next_0_score = list.head.borrow(0);
            while(opt_next_0_score.is_some()) {
                let next_0_score = opt_next_0_score.borrow();
                let node = list.borrow_node(next_0_score);
                if (opt_next_l_score.is_none() || opt_next_l_score.borrow() > node.score) {
                    assert!(node.nexts.length() <= l, 0);
                } else {
                    if (node.nexts.length() > l) {
                        assert!(opt_next_l_score.borrow() == node.score, 0);
                        opt_next_l_score = node.nexts.borrow(l);
                    }
                };
                opt_next_0_score = node.nexts.borrow(0);
            };
            l = l - 1;
        };
    }

    #[test_only]
    public fun get_all_socres<V: store>(list: &SkipList<V>): vector<u64> {
        let (mut opt_next_score,mut scores ) = (list.head(), vector::empty<u64>());
        while (opt_next_score.is_some()) {
            let next_score = opt_next_score.borrow();
            let next_node = list.borrow_node(next_score);
            scores.push_back(next_node.score);
            opt_next_score = next_node.next_score();
        };
        scores
    }
    // Optional index format 1. Absence of the typed key is the only Legacy state.
    const EBitmapState: u64 = 10;
    const EBitmapConfig: u64 = 11;
    const EBitmapIntegrity: u64 = 12;
    const EBitmapFrozen: u64 = 13;
    const EBitmapLimit: u64 = 14;
    const MIGRATING: u8 = 1;
    const CANCELLING: u8 = 2;
    const BITMAP: u8 = 3;
    const REPAIR_CLEARING: u8 = 4;
    const REPAIR_BUILDING: u8 = 5;
    const MAX_BATCH: u64 = 128;

    /// Dynamic-field key for the optional index state; absence denotes Legacy.
    public struct BitmapStateKey has copy, drop, store {}
    /// Sparse word address: level 0 stores positions, higher levels summarize child words.
    public struct BitmapWordKey has copy, drop, store { level: u8, word_index: u64 }
    /// Persisted mapping, mode and resumable maintenance progress under the existing list UID.
    public struct BitmapState has copy, drop, store {
        /// Persisted sidecar format; currently 1.
        format_version: u64,
        /// Maintenance or active mode; absence of this entire state denotes Legacy.
        mode: u8,
        /// Inclusive minimum aligned score.
        min_score: u64,
        /// Inclusive maximum aligned score.
        max_score: u64,
        /// Distance between adjacent legal scores.
        stride: u64,
        /// Number of legal positions, including both endpoints.
        universe_size: u64,
        /// Number of bitmap levels, including the leaf (1..=3).
        depth: u8,
        /// Indexed node count; build progress during migration or rebuilding.
        indexed_size: u64,
        /// Node count captured when maintenance begins.
        snapshot_size: u64,
        /// Authoritative bottom head captured for maintenance.
        snapshot_head: OptionU64,
        /// Authoritative tail captured for maintenance.
        snapshot_tail: OptionU64,
        /// Next bottom-chain node to index.
        cursor: OptionU64,
        /// Last indexed node, used to validate order and reciprocal links.
        last_score: OptionU64,
        /// Next level to scan; depth means cleanup is complete.
        cleanup_level: u8,
        /// Next word position to scan within cleanup_level.
        cleanup_word_index: u64,
    }

    /// Borrow and validate the persisted format, mode and mapping.
    /// A malformed existing state aborts; it is never interpreted as Legacy.
    fun bitmap_state<V: store>(list: &SkipList<V>): &BitmapState {
        let state = field::borrow<BitmapStateKey, BitmapState>(&list.id, BitmapStateKey {});
        assert!(state.format_version == 1 && state.mode >= MIGRATING && state.mode <= REPAIR_BUILDING, EBitmapState);
        let (u, depth) = bitmap_config(state.min_score, state.max_score, state.stride);
        assert!(u == state.universe_size && depth == state.depth, EBitmapConfig);
        state
    }

    /// Return 0 for Legacy (state key absent), or the validated persisted mode:
    /// 1 Migrating, 2 Cancelling, 3 Bitmap, 4 RepairClearing, 5 RepairBuilding.
    public fun bitmap_mode<V: store>(list: &SkipList<V>): u8 {
        if (!field::exists_(&list.id, BitmapStateKey {})) { 0 }
        else { bitmap_state(list).mode }
    }

    /// Allow ordinary operations only in Legacy or active Bitmap mode.
    /// Migration, cancellation and both repair phases freeze guarded operations.
    /// Return the validated mode so dispatching callers do not repeat the storage read.
    public fun checked_bitmap_mode<V: store>(list: &SkipList<V>): u8 {
        let mode = bitmap_mode(list);
        assert!(mode == 0 || mode == BITMAP, EBitmapFrozen);
        mode
    }
    /// Allow ordinary operations only in Legacy or active Bitmap mode.
    public fun assert_bitmap_available<V: store>(list: &SkipList<V>) {
        let _ = checked_bitmap_mode(list);
    }

    /// Return (mode, snapshot_size, indexed_size, build_cursor, cleanup_level, cleanup_word_index).
    /// Legacy returns zeros and no cursor. During cleanup, build counters retain their previous values.
    public fun bitmap_status<V: store>(list: &SkipList<V>): (u8, u64, u64, OptionU64, u8, u64) {
        let mode = bitmap_mode(list);
        if (mode == 0) { return (0, 0, 0, none(), 0, 0) };
        let st = bitmap_state(list);
        (mode, st.snapshot_size, st.indexed_size, st.cursor, st.cleanup_level, st.cleanup_word_index)
    }

    /// Return true when the cleanup cursor has scanned every legal word position.
    /// Requires an existing bitmap state; Legacy lists abort.
    public fun bitmap_cleanup_done<V: store>(list: &SkipList<V>): bool {
        let st = bitmap_state(list);
        st.cleanup_level == st.depth
    }

    /// Require the persisted inclusive score range and stride to match the business adapter.
    /// Requires an existing state; mismatches abort with EBitmapConfig.
    public fun bitmap_check_mapping<V: store>(list: &SkipList<V>, min: u64, max: u64, stride: u64) {
        let st = bitmap_state(list);
        assert!(st.min_score == min && st.max_score == max && st.stride == stride, EBitmapConfig);
    }

    /// Validate an inclusive, aligned score range and return (position_count, depth).
    /// The mapping q = (score - min) / stride supports at most 256^3 positions and three levels.
    fun bitmap_config(min: u64, max: u64, stride: u64): (u64, u8) {
        assert!(stride > 0 && min <= max && (max - min) % stride == 0, EBitmapConfig);
        let slots = (max - min) / stride;
        // At most three levels, including the leaf. Also bounds all cleanup loops.
        assert!(slots < 16777216, EBitmapConfig);
        let u = slots + 1;
        (u, bitmap_math::depth(u))
    }

    /// Return the number of 256-bit words needed to cover n positions, rounding upward.
    fun ceil256(n: u64): u64 { bitmap_math::ceil256(n) }
    /// Return the number of valid bits at level (0 is the leaf).
    /// Reject levels outside the configured depth; higher levels summarize nonempty child words.
    fun level_bits(st: &BitmapState, level: u8): u64 {
        assert!(level < st.depth, EBitmapIntegrity);
        bitmap_math::level_bits(st.universe_size, level)
    }
    /// Map an in-range, stride-aligned score to its zero-based leaf bit index.
    /// Reject invalid scores rather than rounding them to a different node.
    fun bitmap_q(st: &BitmapState, score: u64): u64 {
        assert!(score >= st.min_score && score <= st.max_score, EBitmapConfig);
        assert!((score - st.min_score) % st.stride == 0, EBitmapConfig);
        (score - st.min_score) / st.stride
    }

    /// Read a sparse word without checking its bounds or padding.
    /// An absent key represents zero; an existing key with the wrong value type aborts.
    fun raw_word<V: store>(list: &SkipList<V>, level: u8, idx: u64): (bool, u256) {
        let key = BitmapWordKey { level, word_index: idx };
        if (!field::exists_(&list.id, key)) { (false, 0) }
        else { (true, *field::borrow<BitmapWordKey, u256>(&list.id, key)) }
    }
    /// Read a word and validate its index, unused high bits and sparse representation.
    /// Stored zero words are invalid; absent words represent empty ranges.
    fun bitmap_word<V: store>(list: &SkipList<V>, st: &BitmapState, level: u8, idx: u64): u256 {
        let n = level_bits(st, level);
        assert!(idx < ceil256(n), EBitmapIntegrity);
        let (exists, w) = raw_word(list, level, idx);
        let remaining = n - idx * 256;
        if (remaining < 256) { assert!(w >> (remaining as u8) == 0, EBitmapIntegrity); };
        // Zero words are removed by every normal index update.
        if (exists) { assert!(w != 0, EBitmapIntegrity); };
        w
    }
    /// Persist a nonzero word, or remove its dynamic field when the new word is zero.
    /// The caller maintains bounds and parent summaries.
    fun write_word<V: store>(list: &mut SkipList<V>, level: u8, idx: u64, word: u256) {
        let key = BitmapWordKey { level, word_index: idx };
        if (field::exists_(&list.id, key)) {
            if (word == 0) { let _: u256 = field::remove(&mut list.id, key); }
            else { *field::borrow_mut<BitmapWordKey, u256>(&mut list.id, key) = word; }
        } else if (word != 0) { field::add(&mut list.id, key, word); };
    }
    /// Set or clear the leaf bit for score, requiring its previous state to be the opposite.
    /// Propagate to parent summaries only when a child word changes between empty and nonempty.
    fun bitmap_set<V: store>(list: &mut SkipList<V>, score: u64, present: bool) {
        let st = *bitmap_state(list);
        let mut q = bitmap_q(&st, score);
        let mut level = 0;
        loop {
            let idx = q / 256;
            let mask = 1u256 << ((q % 256) as u8);
            let old = bitmap_word(list, &st, level, idx);
            assert!(((old & mask) != 0) != present, EBitmapIntegrity);
            let new = if (present) old | mask else old ^ mask;
            write_word(list, level, idx, new);
            level = level + 1;
            if (level == st.depth || (old != 0 && new != 0)) { break };
            q = idx;
        };
    }

    /// Find the nearest set bit at or beyond q (forward), or at or below q (backward).
    /// Ascend summaries across empty ranges, then descend to a leaf; return the original score.
    /// A summary pointing to an empty child aborts; no linear scan of empty words is needed.
    fun bitmap_search<V: store>(list: &SkipList<V>, st: &BitmapState, mut q: u64, forward: bool): OptionU64 {
        let mut level = 0;
        loop {
            let n = level_bits(st, level);
            if (q >= n) { return none() };
            let idx = q / 256;
            let bit = (q % 256) as u8;
            let word = bitmap_word(list, st, level, idx);
            let masked = bitmap_math::directional_mask(word, bit, forward);
            if (masked != 0) {
                q = idx * 256 + bitmap_math::extreme_bit(masked, forward);
                while (level > 0) {
                    level = level - 1;
                    let child = bitmap_word(list, st, level, q);
                    assert!(child != 0, EBitmapIntegrity);
                    q = q * 256 + bitmap_math::extreme_bit(child, forward);
                };
                assert!(q < st.universe_size, EBitmapIntegrity);
                return some(st.min_score + q * st.stride)
            };
            level = level + 1;
            if (level == st.depth) { return none() };
            if (forward) { q = idx + 1; }
            else { if (idx == 0) { return none() }; q = idx - 1; };
        }
    }

    /// Read the bottom-chain head, treating an empty head vector as no head.
    fun base_head<V: store>(list: &SkipList<V>): OptionU64 {
        if (list.head.is_empty()) { none() } else { list.head[0] }
    }
    /// Check that head and tail presence agrees with whether the list is empty.
    /// This checks endpoint presence, not every node or link.
    fun bitmap_endpoints<V: store>(list: &SkipList<V>) {
        let h = base_head(list);
        if (list.size == 0) { assert!(is_none(&h) && is_none(&list.tail), EBitmapIntegrity); }
        else { assert!(is_some(&h) && is_some(&list.tail), EBitmapIntegrity); };
    }
    /// Check active-mode count, single-level head metadata and root emptiness.
    /// This bounded check does not replace candidate and bottom-link validation.
    fun bitmap_health<V: store>(list: &SkipList<V>): BitmapState {
        let st = *bitmap_state(list);
        assert!(st.mode == BITMAP && st.indexed_size == list.size, EBitmapIntegrity);
        assert!(list.level == 1 && list.head.length() == 1, EBitmapIntegrity);
        bitmap_endpoints(list);
        let root = bitmap_word(list, &st, st.depth - 1, 0);
        assert!((root == 0) == (list.size == 0), EBitmapIntegrity);
        st
    }
    /// Validate an already borrowed node's key/score identity, successor slot and score alignment.
    fun check_node_ref<V: store>(list: &SkipList<V>, score: u64, node: &Node<V>) {
        assert!(node.score == score && !node.nexts.is_empty(), EBitmapIntegrity);
        let _ = bitmap_q(bitmap_state(list), score);
    }
    /// Borrow a node and validate its key/score identity, bottom successor slot and score alignment.
    fun checked_node<V: store>(list: &SkipList<V>, score: u64): &Node<V> {
        let node = borrow_node(list, score);
        check_node_ref(list, score, node);
        node
    }
    /// Validate the bottom-chain neighbor of an already validated node.
    fun checked_neighbor_from_node<V: store>(list: &SkipList<V>, node: &Node<V>, forward: bool): OptionU64 {
        let score = node.score;
        let neighbor = if (forward) next_score(node) else node.prev;
        if (is_some(&neighbor)) {
            let other_score = option_u64::borrow(&neighbor);
            let other = checked_node(list, other_score);
            if (forward) { assert!(other_score > score && other.prev == some(score), EBitmapIntegrity); }
            else { assert!(other_score < score && next_score(other) == some(score), EBitmapIntegrity); };
        } else {
            assert!((if (forward) list.tail else base_head(list)) == some(score), EBitmapIntegrity);
        };
        neighbor
    }
    /// Return the bottom-chain successor (forward) or predecessor (backward).
    /// Bitmap mode validates ordering, reciprocal links and terminal endpoints without a bitmap search.
    /// Legacy uses the original link; maintenance modes abort.
    public fun bitmap_checked_neighbor<V: store>(list: &SkipList<V>, score: u64, forward: bool): OptionU64 {
        let mode = checked_bitmap_mode(list);
        let node = borrow_node(list, score);
        if (mode == 0) { return if (forward) next_score(node) else node.prev };
        check_node_ref(list, score, node);
        checked_neighbor_from_node(list, node, forward)
    }
    /// Validate a candidate against the query and the adjacent bottom-chain node.
    /// For no result, check the corresponding endpoint proves that no qualifying node exists.
    fun bitmap_validate_result<V: store>(list: &SkipList<V>, score: u64, include: bool, forward: bool, found: OptionU64) {
        if (is_some(&found)) {
            let n = option_u64::borrow(&found);
            let node = checked_node(list, n);
            assert!(if (forward) { n > score || (include && n == score) }
                else { n < score || (include && n == score) }, EBitmapIntegrity);
            let neighbor = checked_neighbor_from_node(list, node, !forward);
            // Also check the opposite endpoint when the candidate is itself an endpoint.
            if (is_none(&node.prev)) { assert!(base_head(list) == found, EBitmapIntegrity); };
            if (is_none(&next_score(node))) { assert!(list.tail == found, EBitmapIntegrity); };
            if (is_some(&neighbor)) {
                let x = option_u64::borrow(&neighbor);
                assert!(if (forward) { x < score || (!include && x == score) }
                    else { x > score || (!include && x == score) }, EBitmapIntegrity);
            };
        } else {
            let endpoint = if (forward) list.tail else base_head(list);
            if (is_some(&endpoint)) {
                let x = option_u64::borrow(&endpoint);
                let node = checked_node(list, x);
                assert!(is_none(&(if (forward) next_score(node) else node.prev)), EBitmapIntegrity);
                assert!(if (forward) { x < score || (!include && x == score) }
                    else { x > score || (!include && x == score) }, EBitmapIntegrity);
            };
        };
    }
    /// Find the nearest qualifying score with optional equality in the requested direction.
    /// Queries need not align to stride: forward rounds up, backward rounds down.
    /// Clamp to the configured range and validate the result against the authoritative bottom chain.
    fun bitmap_find<V: store>(list: &SkipList<V>, score: u64, include: bool, forward: bool): OptionU64 {
        let st = bitmap_health(list);
        let mut result = none();
        if (forward) {
            if (score < st.max_score || (include && score == st.max_score)) {
                let threshold = if (include) score else score + 1;
                let t = if (threshold < st.min_score) st.min_score else threshold;
                let d = t - st.min_score;
                let q = d / st.stride + if (d % st.stride == 0) 0 else 1;
                result = bitmap_search(list, &st, q, true);
            };
        } else {
            if (score > st.min_score || (include && score == st.min_score)) {
                let threshold = if (include) score else score - 1;
                let t = if (threshold > st.max_score) st.max_score else threshold;
                result = bitmap_search(list, &st, (t - st.min_score) / st.stride, false);
            };
        };
        bitmap_validate_result(list, score, include, forward, result);
        result
    }

    /// Insert an aligned score into an active bitmap list after validating its neighbors.
    /// Atomically update the bottom chain, sparse bitmap and counts; new nodes have one successor level.
    fun bitmap_insert<V: store>(list: &mut SkipList<V>, score: u64, value: V) {
        assert!(!contains(list, score), ENodeAlreadyExist);
        let st = *bitmap_state(list);
        let _ = bitmap_q(&st, score);
        let prev = bitmap_find(list, score, false, false);
        let next = bitmap_find(list, score, false, true);
        if (is_some(&prev)) { assert!(next_score(checked_node(list, option_u64::borrow(&prev))) == next, EBitmapIntegrity); }
        else { assert!(base_head(list) == next, EBitmapIntegrity); };
        if (is_some(&next)) { assert!(checked_node(list, option_u64::borrow(&next)).prev == prev, EBitmapIntegrity); }
        else { assert!(list.tail == prev, EBitmapIntegrity); };
        if (is_some(&prev)) { *vector::borrow_mut(&mut field::borrow_mut<u64, Node<V>>(&mut list.id, option_u64::borrow(&prev)).nexts, 0) = some(score); }
        else { *vector::borrow_mut(&mut list.head, 0) = some(score); };
        if (is_some(&next)) { field::borrow_mut<u64, Node<V>>(&mut list.id, option_u64::borrow(&next)).prev = some(score); }
        else { list.tail = some(score); };
        field::add(&mut list.id, score, Node { score, nexts: vector[next], prev, value });
        bitmap_set(list, score, true);
        list.size = list.size + 1;
        field::borrow_mut<BitmapStateKey, BitmapState>(&mut list.id, BitmapStateKey {}).indexed_size = st.indexed_size + 1;
        let _ = bitmap_health(list);
    }
    /// Remove an active bitmap node after checking both bottom-chain edges.
    /// Clear its bit and empty summaries, reconnect neighbors, update counts and return its value.
    fun bitmap_remove<V: store>(list: &mut SkipList<V>, score: u64): V {
        let _ = bitmap_health(list);
        let prev = bitmap_checked_neighbor(list, score, false);
        let next = bitmap_checked_neighbor(list, score, true);
        // bitmap_set requires the bit to be present before clearing.
        bitmap_set(list, score, false);
        if (is_some(&prev)) { *vector::borrow_mut(&mut field::borrow_mut<u64, Node<V>>(&mut list.id, option_u64::borrow(&prev)).nexts, 0) = next; }
        else { *vector::borrow_mut(&mut list.head, 0) = next; };
        if (is_some(&next)) { field::borrow_mut<u64, Node<V>>(&mut list.id, option_u64::borrow(&next)).prev = prev; }
        else { list.tail = prev; };
        let node: Node<V> = field::remove(&mut list.id, score);
        list.size = list.size - 1;
        let st = field::borrow_mut<BitmapStateKey, BitmapState>(&mut list.id, BitmapStateKey {});
        st.indexed_size = st.indexed_size - 1;
        let _ = bitmap_health(list);
        drop_node(node)
    }

    /// Require size, bottom head and tail to match the maintenance snapshot.
    /// Per-node ordering and links are checked separately during rebuilding.
    fun bitmap_snapshot<V: store>(list: &SkipList<V>): BitmapState {
        let st = *bitmap_state(list);
        assert!(list.size == st.snapshot_size && base_head(list) == st.snapshot_head && list.tail == st.snapshot_tail, EBitmapIntegrity);
        st
    }
    /// Start migration from Legacy and persist the mapping and bottom-chain snapshot.
    /// Guarded operations remain frozen until migration finalizes or cancellation finishes.
    /// The caller is responsible for business authorization and selecting the mapping.
    public fun bitmap_begin<V: store>(list: &mut SkipList<V>, min_score: u64, max_score: u64, stride: u64) {
        assert!(bitmap_mode(list) == 0, EBitmapState);
        bitmap_endpoints(list);
        let (universe_size, depth) = bitmap_config(min_score, max_score, stride);
        let h = base_head(list);
        let st = BitmapState { format_version: 1, mode: MIGRATING, min_score, max_score, stride, universe_size, depth,
            indexed_size: 0, snapshot_size: list.size, snapshot_head: h, snapshot_tail: list.tail,
            cursor: h, last_score: none(), cleanup_level: 0, cleanup_word_index: 0 };
        field::add(&mut list.id, BitmapStateKey {}, st);
    }
    /// Return the next node to index in Migrating or RepairBuilding mode.
    /// Validate the snapshot even when the cursor is empty.
    public fun bitmap_cursor<V: store>(list: &SkipList<V>): OptionU64 {
        let st = bitmap_snapshot(list);
        assert!(st.mode == MIGRATING || st.mode == REPAIR_BUILDING, EBitmapState);
        st.cursor
    }
    /// Require a batch limit in 1..=128; zero and oversized batches abort.
    public fun bitmap_check_limit(limit: u64) { assert!(limit > 0 && limit <= MAX_BATCH, EBitmapLimit); }
    /// Index exactly the node at the build cursor and advance along its bottom successor.
    /// Require Migrating or RepairBuilding, valid ordering/links and remaining snapshot capacity.
    /// Business adapters must validate the cursor node value (for example tick identity) before this call.
    public fun bitmap_build_step<V: store>(list: &mut SkipList<V>) {
        let st = bitmap_snapshot(list);
        assert!(st.mode == MIGRATING || st.mode == REPAIR_BUILDING, EBitmapState);
        assert!(st.indexed_size < st.snapshot_size && is_some(&st.cursor), EBitmapIntegrity);
        let score = option_u64::borrow(&st.cursor);
        let node = checked_node(list, score);
        assert!(node.prev == st.last_score, EBitmapIntegrity);
        if (is_some(&st.last_score)) { assert!(score > option_u64::borrow(&st.last_score), EBitmapIntegrity); };
        let next = next_score(node);
        if (is_some(&next)) { assert!(option_u64::borrow(&next) > score, EBitmapIntegrity); };
        bitmap_set(list, score, true);
        let state = field::borrow_mut<BitmapStateKey, BitmapState>(&mut list.id, BitmapStateKey {});
        state.indexed_size = state.indexed_size + 1;
        state.last_score = some(score);
        state.cursor = next;
    }
    /// Complete migration or repair after all snapshot nodes have been indexed.
    /// Check progress, endpoints, root and boundary padding without rescanning the full list.
    /// Initial activation reduces head metadata to one level; existing nodes retain unused higher links.
    fun bitmap_finish<V: store>(list: &mut SkipList<V>, repair: bool) {
        let st = bitmap_snapshot(list);
        assert!(st.mode == if (repair) REPAIR_BUILDING else MIGRATING, EBitmapState);
        assert!(is_none(&st.cursor) && st.last_score == st.snapshot_tail && st.indexed_size == st.snapshot_size, EBitmapIntegrity);
        bitmap_endpoints(list);
        let root = bitmap_word(list, &st, st.depth - 1, 0);
        assert!((root == 0) == (list.size == 0), EBitmapIntegrity);
        // Check each boundary word, including summary padding, in bounded depth.
        let mut l = 0;
        while (l < st.depth) { let _ = bitmap_word(list, &st, l, ceil256(level_bits(&st, l)) - 1); l = l + 1; };
        if (is_some(&st.snapshot_head)) {
            assert!(is_none(&checked_node(list, option_u64::borrow(&st.snapshot_head)).prev), EBitmapIntegrity);
            assert!(is_none(&next_score(checked_node(list, option_u64::borrow(&st.snapshot_tail)))), EBitmapIntegrity);
        };
        if (!repair) { list.head = vector[st.snapshot_head]; list.level = 1; }
        else { assert!(list.level == 1 && list.head.length() == 1, EBitmapIntegrity); };
        field::borrow_mut<BitmapStateKey, BitmapState>(&mut list.id, BitmapStateKey {}).mode = BITMAP;
        let _ = bitmap_health(list);
    }
    /// Activate a fully built migration (Migrating -> Bitmap).
    /// Activation cannot be cancelled back to Legacy.
    public fun bitmap_finalize<V: store>(list: &mut SkipList<V>) { bitmap_finish(list, false); }
    /// Activate a fully rebuilt index (RepairBuilding -> Bitmap).
    public fun bitmap_repair_finalize<V: store>(list: &mut SkipList<V>) { bitmap_finish(list, true); }

    /// Start cancelling a preactivation migration and reset the cleanup cursor.
    /// The list stays frozen until all legal word positions are scanned and cancellation finishes.
    public fun bitmap_cancel_begin<V: store>(list: &mut SkipList<V>) {
        let snap = bitmap_snapshot(list);
        assert!(snap.mode == MIGRATING, EBitmapState);
        let st = field::borrow_mut<BitmapStateKey, BitmapState>(&mut list.id, BitmapStateKey {});
        st.mode = CANCELLING; st.cleanup_level = 0; st.cleanup_word_index = 0;
    }
    /// Freeze an active Bitmap list and snapshot its authoritative bottom chain for repair.
    /// Do not require a healthy old bitmap or indexed count. To retain the freeze after a later
    /// repair failure, commit this operation in a separate successful transaction.
    public fun bitmap_repair_begin<V: store>(list: &mut SkipList<V>) {
        // Deliberately do not inspect indexed_size or any old word.
        assert!(bitmap_mode(list) == BITMAP, EBitmapState);
        assert!(list.level == 1 && list.head.length() == 1, EBitmapIntegrity);
        bitmap_endpoints(list);
        let h = base_head(list);
        let st = field::borrow_mut<BitmapStateKey, BitmapState>(&mut list.id, BitmapStateKey {});
        st.mode = REPAIR_CLEARING; st.snapshot_size = list.size;
        st.snapshot_head = h; st.snapshot_tail = list.tail;
        st.cleanup_level = 0; st.cleanup_word_index = 0;
    }
    /// Discard an in-progress rebuild by returning RepairBuilding to RepairClearing.
    /// Reset the cleanup cursor; preserve the original maintenance snapshot.
    public fun bitmap_repair_restart<V: store>(list: &mut SkipList<V>) {
        let snap = bitmap_snapshot(list);
        assert!(snap.mode == REPAIR_BUILDING, EBitmapState);
        let st = field::borrow_mut<BitmapStateKey, BitmapState>(&mut list.id, BitmapStateKey {});
        st.mode = REPAIR_CLEARING; st.cleanup_level = 0; st.cleanup_word_index = 0;
    }
    /// Scan at most scan_limit legal word positions and remove any existing words.
    /// Missing positions also consume the limit, bounding work for sparse indexes.
    /// Persist the next level/word cursor; require Cancelling or RepairClearing as selected.
    fun bitmap_cleanup<V: store>(list: &mut SkipList<V>, scan_limit: u64, repair: bool) {
        bitmap_check_limit(scan_limit);
        let st = bitmap_snapshot(list);
        assert!(st.mode == if (repair) REPAIR_CLEARING else CANCELLING, EBitmapState);
        let mut level = st.cleanup_level;
        let mut idx = st.cleanup_word_index;
        let mut words = if (level < st.depth) ceil256(level_bits(&st, level)) else 0;
        let mut visits = 0;
        while (level < st.depth && visits < scan_limit) {
            let key = BitmapWordKey { level, word_index: idx };
            if (field::exists_(&list.id, key)) { let _: u256 = field::remove(&mut list.id, key); };
            visits = visits + 1; idx = idx + 1;
            if (idx == words) {
                level = level + 1; idx = 0;
                if (level < st.depth) { words = ceil256(level_bits(&st, level)); };
            };
        };
        let state = field::borrow_mut<BitmapStateKey, BitmapState>(&mut list.id, BitmapStateKey {});
        state.cleanup_level = level; state.cleanup_word_index = idx;
    }
    /// Remove a bounded batch of word positions while Cancelling; limit must be 1..=128.
    public fun bitmap_cancel_batch<V: store>(list: &mut SkipList<V>, limit: u64) { bitmap_cleanup(list, limit, false); }
    /// Remove a bounded batch of word positions while RepairClearing; limit must be 1..=128.
    public fun bitmap_repair_clear_batch<V: store>(list: &mut SkipList<V>, limit: u64) { bitmap_cleanup(list, limit, true); }
    /// Return to Legacy only after cancellation has scanned every legal word position.
    /// Remove the sidecar state; retain the original skip-list topology and random state.
    public fun bitmap_cancel_finish<V: store>(list: &mut SkipList<V>) {
        let st = bitmap_snapshot(list);
        assert!(st.mode == CANCELLING && st.cleanup_level == st.depth && st.cleanup_word_index == 0, EBitmapState);
        let _: BitmapState = field::remove(&mut list.id, BitmapStateKey {});
    }
    /// After complete cleanup, enter RepairBuilding with count zero and cursor at the snapshot head.
    /// Preserve the score mapping and keep guarded operations frozen until repair finalizes.
    public fun bitmap_repair_clear_finish<V: store>(list: &mut SkipList<V>) {
        let _ = bitmap_snapshot(list);
        let st = field::borrow_mut<BitmapStateKey, BitmapState>(&mut list.id, BitmapStateKey {});
        assert!(st.mode == REPAIR_CLEARING && st.cleanup_level == st.depth && st.cleanup_word_index == 0, EBitmapState);
        st.mode = REPAIR_BUILDING; st.indexed_size = 0;
        st.cursor = st.snapshot_head; st.last_score = none();
    }

    /// Test-only storage observation; never exposes the parent UID or mutable state.
    #[test_only]
    public fun bitmap_word_for_test<V: store>(list: &SkipList<V>, level: u8, idx: u64): (bool, u256) {
        raw_word(list, level, idx)
    }
    /// Test-only: Observe whether every legal word position has been scanned.
    #[test_only]
    public fun bitmap_cleanup_done_for_test<V: store>(list: &SkipList<V>): bool {
        bitmap_cleanup_done(list)
    }
    /// Test-only: Observe the number of successor levels without exposing private fields.
    #[test_only]
    public fun node_height_for_test<V: store>(node: &Node<V>): u64 {
        node.nexts.length()
    }
    /// Test-only: Read an unchecked word for corruption test setup.
    #[test_only]
    public fun bitmap_raw_word_for_test<V: store>(list: &SkipList<V>, level: u8, idx: u64): u256 {
        let (_, word) = raw_word(list, level, idx);
        word
    }
    /// Test-only: Inject a word without updating its summaries.
    #[test_only]
    public fun bitmap_write_word_for_test<V: store>(list: &mut SkipList<V>, level: u8, idx: u64, word: u256) {
        write_word(list, level, idx, word);
    }
    /// Test-only: Inject an inconsistent indexed count for recovery tests.
    #[test_only]
    public fun bitmap_set_count_for_test<V: store>(list: &mut SkipList<V>, count: u64) {
        field::borrow_mut<BitmapStateKey, BitmapState>(&mut list.id, BitmapStateKey {}).indexed_size = count;
    }
    /// Test-only: Inject an unknown mode to verify fail-closed dispatch.
    #[test_only]
    public fun bitmap_set_mode_for_test<V: store>(list: &mut SkipList<V>, mode: u8) {
        field::borrow_mut<BitmapStateKey, BitmapState>(&mut list.id, BitmapStateKey {}).mode = mode;
    }
    /// Test-only: Inject a broken reciprocal bottom-chain link.
    #[test_only]
    public fun node_set_prev_for_test<V: store>(list: &mut SkipList<V>, score: u64, prev: OptionU64) {
        field::borrow_mut<u64, Node<V>>(&mut list.id, score).prev = prev;
    }
    /// Test-only: Inject an inconsistent tail for endpoint validation tests.
    #[test_only]
    public fun set_tail_for_test<V: store>(list: &mut SkipList<V>, tail: OptionU64) {
        list.tail = tail;
    }
    /// Test-only: Install the state key with the wrong value type.
    #[test_only]
    public fun bitmap_wrong_state_type_for_test<V: store>(list: &mut SkipList<V>) {
        field::add(&mut list.id, BitmapStateKey {}, 1u64);
    }
    /// Test-only: Replace an existing word with the wrong value type.
    #[test_only]
    public fun bitmap_wrong_word_type_for_test<V: store>(list: &mut SkipList<V>, level: u8, idx: u64) {
        let key = BitmapWordKey { level, word_index: idx }; let _: u256 = field::remove(&mut list.id, key); field::add(&mut list.id, key, 1u64);
    }
    /// Test-only: Prepare metadata for a deliberately degenerate legacy fixture.
    #[test_only]
    public fun set_base_metadata_for_test<V: store>(list: &mut SkipList<V>, head: OptionU64, tail: OptionU64, size: u64) {
        list.head = vector[head]; list.tail = tail; list.level = 1; list.size = size;
    }
    /// Test-only: Add a height-one fixture node without randomized insertion.
    #[test_only]
    public fun add_base_node_for_test<V: store>(list: &mut SkipList<V>, score: u64, prev: OptionU64, next: OptionU64, value: V) {
        field::add(&mut list.id, score, Node { score, nexts: vector[next], prev, value });
    }
    #[test_only]
    public fun bitmap_corrupt_header_for_test<V: store>(list: &mut SkipList<V>, format: bool) {
        let st = field::borrow_mut<BitmapStateKey, BitmapState>(&mut list.id, BitmapStateKey {});
        if (format) { st.format_version = 255 } else { st.universe_size = 0 };
    }
    #[test_only]
    public fun node_set_next_for_test<V: store>(list: &mut SkipList<V>, score: u64, next: OptionU64) {
        *vector::borrow_mut(&mut field::borrow_mut<u64, Node<V>>(&mut list.id, score).nexts, 0) = next;
    }

}
