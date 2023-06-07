module hello_world::hello_world {




    struct Counter has key {
        value: u64,
    }


    public entry fun create(account: signer, value: u64) {
        let counter = Counter {
            value
        };

        move_to(&account, counter);
    }
}
