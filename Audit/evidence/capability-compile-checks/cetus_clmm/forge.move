module cetus_clmm::capability_compile_probe {
    public fun forge_0(ctx: &mut sui::tx_context::TxContext): cetus_clmm::config::AdminCap {
        cetus_clmm::config::AdminCap { id: sui::object::new(ctx) }
    }
    public fun forge_1(ctx: &mut sui::tx_context::TxContext): cetus_clmm::config::ProtocolFeeClaimCap {
        cetus_clmm::config::ProtocolFeeClaimCap { id: sui::object::new(ctx) }
    }
    public fun forge_2(ctx: &mut sui::tx_context::TxContext): cetus_clmm::pool::ProtocolFeeCollectCap {
        cetus_clmm::pool::ProtocolFeeCollectCap { id: sui::object::new(ctx) }
    }
    public fun forge_3(ctx: &mut sui::tx_context::TxContext): cetus_clmm::factory::PoolCreationCap {
        cetus_clmm::factory::PoolCreationCap { id: sui::object::new(ctx), coin_type: std::type_name::get<u64>() }
    }
    public fun forge_4(ctx: &mut sui::tx_context::TxContext): cetus_clmm::partner::PartnerCap {
        cetus_clmm::partner::PartnerCap { id: sui::object::new(ctx), name: std::string::utf8(b"probe"), partner_id: sui::object::id_from_address(@0x1) }
    }
}
