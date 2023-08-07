module game::bag {
  
    use sui::bag::{Bag, Self};
    use sui::tx_context::{TxContext};

   struct GameInventory {
       items: Bag
    }

    // Create a new, empty GameInventory
    public fun create(ctx: &mut TxContext): GameInventory {
        GameInventory{
            items: bag::new(ctx)
        }
    }
    // Adds a key-value pair to GameInventory
    public fun add<K: copy + drop + store, V: store>(bag: &mut GameInventory, k: K, v: V) {
       bag::add(&mut bag.items, k, v);
    }

    /// Removes the key-value pair from the GameInventory with the provided key and returns the value.   
    public fun remove<K: copy + drop + store, V: store>(bag: &mut GameInventory, k: K): V {
        bag::remove(&mut bag.items, k)
    }

    // Borrows an immutable reference to the value associated with the key in GameInventory
    public fun borrow<K: copy + drop + store, V: store>(bag: &GameInventory, k: K): &V {
        bag::borrow(&bag.items, k)
    }

    /// Borrows a mutable reference to the value associated with the key in GameInventory
    public fun borrow_mut<K: copy + drop + store, V: store>(bag: &mut GameInventory, k: K): &mut V {
        bag::borrow_mut(&mut bag.items, k)
    }

    /// Check if a value associated with the key exists in the GameInventory
    public fun contains<K: copy + drop + store>(bag: &GameInventory, k: K): bool {
        bag::contains<K>(&bag.items, k)
    }

    /// Returns the size of the GameInventory, the number of key-value pairs
    public fun length(bag: &GameInventory): u64 {
        bag::length(&bag.items)
    }


}