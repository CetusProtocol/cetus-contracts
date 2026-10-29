/// Disposable local-network coin for funded ownership and recovery witnesses.
module ownership_coin::probe;

use sui::coin;

public struct PROBE has drop {}

fun init(witness: PROBE, ctx: &mut TxContext) {
    let (mut treasury, metadata) = coin::create_currency(
        witness, 9, b"PROBE", b"Local ownership probe", b"Not a deployed protocol asset", option::none(), ctx,
    );
    let coins = coin::mint(&mut treasury, 1_000_000_000_000, ctx);
    transfer::public_transfer(coins, ctx.sender());
    transfer::public_transfer(treasury, ctx.sender());
    transfer::public_freeze_object(metadata);
}
