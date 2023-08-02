module car::car{
    use sui::object::{Self,UID};
    use sui::transfer;
    use sui::tx_context::{Self,TxContext};
    use sui::dynamic_object_field as ofield;

    struct ObjectOwnedByAddress has key { id: UID }
    struct ObjectOwnedByObject has key, store { id: UID }
    struct ObjectShared has key { id: UID }
    struct ObjectImmutable has key { id: UID }

    public entry fun create_object_owned_by_an_address(ctx: &mut TxContext) {
        transfer::transfer({
            ObjectOwnedByAddress { id: object::new(ctx) }
        }, tx_context::sender(ctx))
    }
    
    public entry fun create_object_owned_by_an_object(parent: &mut ObjectOwnedByAddress, ctx: &mut TxContext) {
        let child = ObjectOwnedByObject { id: object::new(ctx) };
        ofield::add(&mut parent.id, b"child", child);
    }

    public entry fun create_shared_object(ctx: &mut TxContext) {
	    transfer::share_object(ObjectShared { id: object::new(ctx) })
    }

    public entry fun create_immutable_object(ctx: &mut TxContext) {
	    transfer::freeze_object(ObjectImmutable { id: object::new(ctx) })
    }
}