module cetus_clmm::capability_compile_probe {
    public fun forward_0(cap: cetus_clmm::config::AdminCap): cetus_clmm::config::AdminCap { cap }
    public fun forward_1(cap: cetus_clmm::config::ProtocolFeeClaimCap): cetus_clmm::config::ProtocolFeeClaimCap { cap }
    public fun forward_2(cap: cetus_clmm::pool::ProtocolFeeCollectCap): cetus_clmm::pool::ProtocolFeeCollectCap { cap }
    public fun forward_3(cap: cetus_clmm::factory::PoolCreationCap): cetus_clmm::factory::PoolCreationCap { cap }
    public fun forward_4(cap: cetus_clmm::partner::PartnerCap): cetus_clmm::partner::PartnerCap { cap }
}
