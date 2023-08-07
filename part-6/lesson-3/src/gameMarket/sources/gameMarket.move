/// Copyright (c) Sui Foundation, Inc.
/// SPDX-License-Identifier: Apache-2.0
///

module gamemarket::gameMarket {
    use sui::dynamic_object_field as ofield;
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, ID, UID};
    use sui::coin::{Self, Coin};
    use sui::bag::{Bag, Self};
    use sui::table::{Table, Self};
    use sui::transfer;

    /// For when amount paid does not match the expected.
    const EAmountIncorrect: u64 = 0;
    /// For when someone tries to delist without ownership.
    const ENotOwner: u64 = 1;

    /// A shared `GameMarket`. Can be created by anyone using the
    /// `create` function. One instance of `GameMarket` accepts
    /// only one type of Coin - `COIN` for all its listings.
    struct GameMarket<phantom COIN> has key {
        id: UID,
        gameItems: Bag,
        payments: Table<address, Coin<COIN>>
    }

    /// A single listing which contains the listed item and its
    /// price in [`Coin<COIN>`].
    struct GameListing has key, store {
        id: UID,
        ask: u64,
        owner: address,
    }

    /// Create a new shared GameMarket.
    public entry fun create<COIN>(ctx: &mut TxContext) {
        let id = object::new(ctx);
        let gameItems = bag::new(ctx);
        let payments = table::new<address, Coin<COIN>>(ctx);
        transfer::share_object(GameMarket<COIN> { 
            id, 
            gameItems,
            payments
        })
    }

    /// List an item at the GameMarket.
    public entry fun list<T: key + store, COIN>(
        gameMarket: &mut GameMarket<COIN>,
        item: T,
        ask: u64,
        ctx: &mut TxContext
    ) {
        let item_id = object::id(&item);
        let gameListing = GameListing {
            ask,
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
        };

        ofield::add(&mut gameListing.id, true, item);
        bag::add(&mut gameMarket.gameItems, item_id, gameListing)
    }

    /// Internal function to remove listing and get an item back. Only owner can do that.
    fun delist<T: key + store, COIN>(
        gameMarket: &mut GameMarket<COIN>,
        item_id: ID,
        ctx: &mut TxContext
    ): T {
        let GameListing {
            id,
            owner,
            ask: _,
        } = bag::remove(&mut gameMarket.gameItems, item_id);

        assert!(tx_context::sender(ctx) == owner, ENotOwner);

        let item = ofield::remove(&mut id, true);
        object::delete(id);
        item
    }

    /// Call [`delist`] and transfer item to the sender.
    public entry fun delist_and_take<T: key + store, COIN>(
        gameMarket: &mut GameMarket<COIN>,
        item_id: ID,
        ctx: &mut TxContext
    ) {
        let item = delist<T, COIN>(gameMarket, item_id, ctx);
        transfer::public_transfer(item, tx_context::sender(ctx));
    }

    /// Internal function to purchase an item using a known GameListing. Payment is done in Coin<C>.
    /// Amount paid must match the requested amount. If conditions are met,
    /// owner of the item gets the payment and buyer receives their item.
    fun buy<T: key + store, COIN>(
        gameMarket: &mut GameMarket<COIN>,
        item_id: ID,
        paid: Coin<COIN>,
    ): T {
        let GameListing {
            id,
            ask,
            owner
        } = bag::remove(&mut gameMarket.gameItems, item_id);

        assert!(ask == coin::value(&paid), EAmountIncorrect);

        // Check if there's already a Coin hanging and merge `paid` with it.
        // Otherwise attach `paid` to the `GameMarket` under owner's `address`.
        if (table::contains<address, Coin<COIN>>(&gameMarket.payments, owner)) {
            coin::join(
                table::borrow_mut<address, Coin<COIN>>(&mut gameMarket.payments, owner),
                paid
            )
        } else {
            table::add(&mut gameMarket.payments, owner, paid)
        };

        let item = ofield::remove(&mut id, true);
        object::delete(id);
        item
    }

    /// Call [`buy`] and transfer item to the sender.
    public entry fun buy_and_take<T: key + store, COIN>(
        gameMarket: &mut GameMarket<COIN>,
        item_id: ID,
        paid: Coin<COIN>,
        ctx: &mut TxContext
    ) {
        transfer::public_transfer(
            buy<T, COIN>(gameMarket, item_id, paid),
            tx_context::sender(ctx)
        )
    }

    /// Internal function to take profits from selling items on the `GameMarket`.
    fun take_profits<COIN>(
        gameMarket: &mut GameMarket<COIN>,
        ctx: &mut TxContext
    ): Coin<COIN> {
        table::remove<address, Coin<COIN>>(&mut gameMarket.payments, tx_context::sender(ctx))
    }

    /// Call [`take_profits`] and transfer Coin object to the sender.
    public entry fun take_profits_and_keep<COIN>(
        gameMarket: &mut GameMarket<COIN>,
        ctx: &mut TxContext
    ) {
        transfer::public_transfer(
            take_profits(gameMarket, ctx),
            tx_context::sender(ctx)
        )
    }
}
