
module fungible_tokens::SCC {
    use std::option;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct SCC has drop {}

    fun init(witness: SCC, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency<SCC>(
            witness, 
            9, 
            b"SCC", 
            b"Sui Course Coin", 
            b"", 
            option::none(), 
            ctx
        );
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx))
    }

    public entry fun mint(
        treasury_cap: &mut TreasuryCap<SCC>, amount: u64, recipient: address, ctx: &mut TxContext
    ) {
        coin::mint_and_transfer(treasury_cap, amount, recipient, ctx)
    }

    public entry fun burn(treasury_cap: &mut TreasuryCap<SCC>, coin: Coin<SCC>) {
        coin::burn(treasury_cap, coin);
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        init(SCC {}, ctx)
    }
}
