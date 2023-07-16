module store::bread_store {
    use std::string::{Self, String};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    const ENoFlavor : u64 = 1;

    struct Flavor has store {
        flavor: String
    }

    struct Bread has key {
        id: UID,
        flavor: Flavor
    }

    // TODO: define the Sandwich struct

    public entry fun buy_bread(option: u8, ctx: &mut TxContext) {
        // select the flavor
        let flavor: String = string::utf8(b"original");
        if (option == 1) {
            flavor = string::utf8(b"original");
        } else if (option == 2) {
            flavor = string::utf8(b"cheese toast");
        } else if (option == 3) {
            flavor = string::utf8(b"with butter");
        } else {
            assert!(false, ENoFlavor);
        };

        // prepare the bread
        let bread = Bread {
            id: object::new(ctx),
            flavor: Flavor {flavor: flavor}
        };

        // transfer Bread to customer
        transfer::transfer(bread, tx_context::sender(ctx));
    }

    public entry fun buy_sandwich(option: u8, ctx: &mut TxContext) {
        // TODO: implement this function, supporting flavors: mixed meat sandwich, chicken sandwich, cheese sandwich, and more

        
    }
}
