module hello_world::hello_world {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct Counter has key {
        id: UID,
        value: u64,
    }

    public entry fun create(value: u64, ctx: &mut TxContext) {
        let counter= Counter {
            id: object::new(ctx),
            value
        };
        transfer::transfer(counter, tx_context::sender(ctx));
    }
}
