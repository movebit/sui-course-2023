module helloworld::helloworld {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer::{Self};

    struct Message has key {
        id: UID,
        content: vector<u8>
    }

    public entry fun save(content: vector<u8>, ctx: &mut TxContext) {
        let msgObject = Message {
            id: object::new(ctx),
            content: content,
        };

        transfer::transfer(msgObject, tx_context::sender(ctx));
    }
}
