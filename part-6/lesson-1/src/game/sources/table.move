module game::table {

    use sui::table::{Table, Self};
    use sui::tx_context::{TxContext};

    // Defining a table with specified types for the key and value
    struct ItemTable {
        table_values: Table<u8, u8>
    }

    // Defining a table with generic types for the key and value 
    struct GenericItemTable<phantom K: copy + drop + store, phantom V: store> {
        table_values: Table<K, V>
    }

    // Create a new, empty GenericItemTable with key type K, and value type V
    public fun create<K: copy + drop + store, V: store>(ctx: &mut TxContext): GenericItemTable<K, V> {
        GenericItemTable<K, V> {
            table_values: table::new<K, V>(ctx)
        }
    }

    // Adds a key-value pair to GenericItemTable
    public fun add<K: copy + drop + store, V: store>(table: &mut GenericItemTable<K, V>, k: K, v: V) {
        table::add(&mut table.table_values, k, v);
    }

    /// Removes the key-value pair in the GenericItemTable `table: &mut Table<K, V>` and returns the value.   
    public fun remove<K: copy + drop + store, V: store>(table: &mut GenericItemTable<K, V>, k: K): V {
        table::remove(&mut table.table_values, k)
    }

    // Borrows an immutable reference to the value associated with the key in GenericItemTable
    public fun borrow<K: copy + drop + store, V: store>(table: &GenericItemTable<K, V>, k: K): &V {
        table::borrow(&table.table_values, k)
    }

    /// Borrows a mutable reference to the value associated with the key in GenericItemTable
    public fun borrow_mut<K: copy + drop + store, V: store>(table: &mut GenericItemTable<K, V>, k: K): &mut V {
        table::borrow_mut(&mut table.table_values, k)
    }

    /// Check if a value associated with the key exists in the GenericItemTable
    public fun contains<K: copy + drop + store, V: store>(table: &GenericItemTable<K, V>, k: K): bool {
        table::contains<K, V>(&table.table_values, k)
    }

    /// Returns the size of the GenericItemTable, the number of key-value pairs
    public fun length<K: copy + drop + store, V: store>(table: &GenericItemTable<K, V>): u64 {
        table::length(&table.table_values)
    }

}