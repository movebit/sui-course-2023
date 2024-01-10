/// Example of objects that can be combined to create new objects
module store::sandwich {
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::object::{Self, UID};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct Ham has key {
        id: UID
    }

    struct Bread has key {
        id: UID
    }

    struct Sandwich has key {
        id: UID,
    }

    // This Capability allows the owner to withdraw profits
    struct GroceryOwnerCapability has key {
        id: UID
    }

    // Grocery is created on module init
    struct Grocery has key {
        id: UID,
        profits: Balance<SUI>
    }

    /// Price for ham
    const HAM_PRICE: u64 = 10;
    /// Price for bread
    const BREAD_PRICE: u64 = 2;

    /// Not enough funds to pay for the goods
    const EInsufficientFunds: u64 = 0;
    /// Nothing to withdraw
    const ENoProfits: u64 = 1;

    /// On module init, create a grocery
    fun init(ctx: &mut TxContext) {
        transfer::share_object(Grocery {
            id: object::new(ctx),
            profits: balance::zero<SUI>()
        });

        transfer::transfer(GroceryOwnerCapability {
            id: object::new(ctx)
        }, tx_context::sender(ctx));
    }

    /// Exchange `c` for some ham
    public entry fun buy_ham(
        grocery: &mut Grocery,
        c: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let b = coin::into_balance(c);
        assert!(balance::value(&b) == HAM_PRICE, EInsufficientFunds); // check input value is correct
        balance::join(&mut grocery.profits, b);
        transfer::transfer(Ham { id: object::new(ctx) }, tx_context::sender(ctx))
    }

    /// Exchange `c` for some bread
    public entry fun buy_bread(
        grocery: &mut Grocery,
        c: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let b = coin::into_balance(c);
        assert!(balance::value(&b) == BREAD_PRICE, EInsufficientFunds);
        balance::join(&mut grocery.profits, b);
        transfer::transfer(Bread { id: object::new(ctx) }, tx_context::sender(ctx))
    }

    /// Combine the `ham` and `bread` into a delicious sandwich
    public fun make_sandwich(ham: Ham, bread: Bread, ctx: &mut TxContext): Sandwich {
        let Ham { id: ham_id } = ham;
        let Bread { id: bread_id } = bread;
        object::delete(ham_id);
        object::delete(bread_id);
        Sandwich { id: object::new(ctx)}
    }

    /// Eat the delicious sandwich
    public entry fun eat_sandwich(sandwich: Sandwich) {
        let Sandwich { id: sandwich_id } = sandwich;
        object::delete(sandwich_id);
    }

    /// Store sandwich to the sender
    public entry fun store_sandwich(
        sandwich: Sandwich, ctx: &mut TxContext
    ) {
        transfer::transfer(sandwich, tx_context::sender(ctx))
    }

    /// See the profits of a grocery
    public fun profits(grocery: &Grocery): u64 {
        balance::value(&grocery.profits)
    }

    /// Owner of the grocery can collect profits by passing his capability
    public entry fun collect_profits(_cap: &GroceryOwnerCapability, grocery: &mut Grocery, ctx: &mut TxContext) {
        let amount = balance::value(&grocery.profits);

        assert!(amount > 0, ENoProfits);

        // Take a transferable `Coin` from a `Balance`
        let coin = coin::take(&mut grocery.profits, amount, ctx);

        transfer::public_transfer(coin, tx_context::sender(ctx));
    }
}

