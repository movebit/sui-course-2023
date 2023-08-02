module car::shop{
    use sui::object::{Self,UID};
    use sui::transfer;
    use sui::tx_context::{Self,TxContext};
    use sui::dynamic_object_field as ofield;
    use std::string::{Self, String};
    use std::option::{Self, Option};

    struct ShopAdminCap has key { id: UID }

    struct Tesla has key { 
        id: UID,
        type: String,
        speed: u32,
        autopilot: Option<Autopilot>, // optional field
    }

    struct Autopilot has key, store { 
        id: UID,
        level: u32,
    }

    struct Jarvis has key { 
        id: UID,
        language: String, 
    }

    struct Shop has key { 
        id: UID,
    }
    
    // we will initialize this contract with a ShopAdminCap being the deployer
    fun init(ctx: &mut TxContext) {
        transfer::transfer(
            ShopAdminCap {id: object::new(ctx)}
        , tx_context::sender(ctx))
    }

    // admin can create a tesla for the buyer
    public entry fun create_tesla(_: &ShopAdminCap, buyer:address, name:vector<u8>, ctx: &mut TxContext) {
        let tesla = Tesla {
            id: object::new(ctx),
            type: string::utf8(name),
            speed: 220,
            autopilot:option::none(),
        };
        
        transfer::transfer(tesla, buyer);
    }
    
    // admin can also build a autopilor for specific tesla
    public entry fun create_autopilot(_: &ShopAdminCap, parent: &mut Tesla, level:u32,  ctx: &mut TxContext) {
        let child = Autopilot { id: object::new(ctx), level: level };
        ofield::add(&mut parent.id, b"child", child);
    }

    public entry fun create_jarvis(lan: vector<u8>, ctx: &mut TxContext) {
        let jarvis = Jarvis { id: object::new(ctx), language: string::utf8(lan) };
	    transfer::share_object(jarvis);
    }

    public entry fun create_shop(_:&ShopAdminCap, ctx: &mut TxContext) {
        let shop = Shop { id: object::new(ctx) };
        transfer::freeze_object(shop);
    }
}

