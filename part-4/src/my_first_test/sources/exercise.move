module my_first_test::exercise {

    // Part 1: Imports
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    // errors
    const ESwordValuesMismatch: u64 = 0;
    const ESwordNotBurned: u64 = 1;

    // Part 2: Struct definitions
    struct Sword has key, store {
        id: UID,
        magic: u64,
        strength: u64,
    }

    struct Forge has key, store {
        id: UID,
        swords_created: u64,
    }

    // Part 3: Module initializer to be executed when this module is published
    fun init(ctx: &mut TxContext) {
        let admin = Forge {
            id: object::new(ctx),
            swords_created: 0,
        };
        // Transfer the forge object to the module/package publisher
        transfer::transfer(admin, tx_context::sender(ctx));
    }

    // Part 4: Accessors required to read the struct attributes
    public fun magic(self: &Sword): u64 {
        self.magic
    }

    public fun strength(self: &Sword): u64 {
        self.strength
    }

    public fun swords_created(self: &Forge): u64 {
        self.swords_created
    }

    public entry fun sword_create(magic: u64, strength: u64, recipient: address, ctx: &mut TxContext) {
        use sui::transfer;

        // create a sword
        let sword = Sword {
            id: object::new(ctx),
            magic: magic,
            strength: strength,
        };
        // transfer the sword
        transfer::transfer(sword, recipient);
    }

    public entry fun sword_transfer(sword: Sword, recipient: address, _ctx: &mut TxContext) {
        use sui::transfer;
        // transfer the sword
        transfer::transfer(sword, recipient);
    }

    // this function will update the fields of sword
    public fun sword_update(sword: &mut Sword, magic: u64, strength: u64, _ctx: &mut TxContext) {
        sword.magic = magic;
        sword.strength = strength;
    }

    // this function will burn the sword
    public fun sword_burn(sword:Sword, _ctx: &mut TxContext) {
        let Sword{id: id, magic: _, strength: _,} = sword;
        object::delete(id);
    }

    // this test will test sword_update function
    #[test]
    public fun test_sword_update() {
    use sui::test_scenario;

        // create test addresses representing users
        let admin = @0xBABE;
        let owner = @0xCAFE;

        // first transaction to emulate module initialization
        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        {
            init(test_scenario::ctx(scenario));
        };
        // second transaction executed by admin to create the sword
        test_scenario::next_tx(scenario, admin);
        {
            // create the sword and transfer it to the initial owner
            sword_create(42, 7, owner, test_scenario::ctx(scenario));
        };
        // third transaction executed by the initial sword owner
        test_scenario::next_tx(scenario, owner);
        {
            // extract the sword owned by the initial owner
            let sword = test_scenario::take_from_sender<Sword>(scenario);
            // update the sword fields to new values
            sword_update(&mut sword, 100, 10, test_scenario::ctx(scenario));
            assert!(magic(&sword) == 100 && strength(&sword) == 10, ESwordValuesMismatch);
            test_scenario::return_to_sender(scenario, sword)
        };
        test_scenario::end(scenario_val);
    }

    // this test will test sword_burn function
    #[test]
    public fun test_sword_burn() {
    use sui::test_scenario;

        // create test addresses representing users
        let admin = @0xBABE;
        let owner = @0xCAFE;

        // first transaction to emulate module initialization
        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        {
            init(test_scenario::ctx(scenario));
        };
        // second transaction executed by admin to create the sword
        test_scenario::next_tx(scenario, admin);
        {
            // create the sword and transfer it to the initial owner
            sword_create(42, 7, owner, test_scenario::ctx(scenario));
        };
        // third transaction executed by the initial sword owner
        test_scenario::next_tx(scenario, owner);
        {
            // extract the sword owned by the initial owner
            let sword = test_scenario::take_from_sender<Sword>(scenario);
            sword_burn(sword, test_scenario::ctx(scenario)); // after burning the sword, it does not need to be returned to the scenario
        };
        test_scenario::end(scenario_val);
    }   
}