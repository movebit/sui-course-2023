module nft_in_sui::event {
    use sui::event;
    use sui::tx_context::{sender, Self,TxContext};

    struct My_Event has copy, drop {
        user: address,
        value: u64
    }
    
    fun init(ctx: &mut sui::tx_context::TxContext) {
        event::emit(My_Event {
            user: sender(ctx),
            value: tx_context::epoch(ctx)
        })
    }

    public fun emit(value: u64, ctx: &mut TxContext) {
        event::emit(My_Event {
            user: sender(ctx),
            value: value
        })
    }
    

}