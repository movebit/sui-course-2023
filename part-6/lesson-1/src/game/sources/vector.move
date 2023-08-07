module game::vector {

    use std::vector;

    struct Item {
    }

    // Vector for a specified item type
    struct ItemVector {
        items: vector<Item>
    }

    // Vector for a generic type 
    struct GenericVector<T> {
        values: vector<T>
    }

    // Creates a GenericVector that holds a generic type T
    public fun create<T>(): GenericVector<T> {
        GenericVector<T> {
            values: vector::empty<T>()
        }
    }

    // Add an item of type T to a GenericVector
    public fun addItem<T>(vec: &mut GenericVector<T>, item: T) {
        vector::push_back<T>(&mut vec.values, item);
    }

    // Removes an item of type T from a GenericVector
    public fun removeItem<T>(vec: &mut GenericVector<T>): T {
        vector::pop_back<T>(&mut vec.values)
    }

    // Returns the size of a given GenericVector
    public fun getSize<T>(vec: &mut GenericVector<T>): u64 {
        vector::length<T>(&vec.values)
    }
}