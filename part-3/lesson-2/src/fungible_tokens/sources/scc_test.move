#[test_only]
module fungible_tokens::SCC_Test {
    use fungible_tokens::SCC::{Self, SCC};
    use sui::coin::{Coin, TreasuryCap, Self};
    use sui::test_scenario::{Self, next_tx, ctx};

    #[test]
    fun mint_burn() {
        let addr1 = @0xA;
        let scenario = test_scenario::begin(addr1);
        {
            SCC::test_init(ctx(&mut scenario))
        };
        next_tx(&mut scenario, addr1);
        {
            let treasurycap = test_scenario::take_from_sender<TreasuryCap<SCC>>(&scenario);
            SCC::mint(&mut treasurycap, 100, addr1, test_scenario::ctx(&mut scenario));
            test_scenario::return_to_address<TreasuryCap<SCC>>(addr1, treasurycap);
        };


        next_tx(&mut scenario, addr1);
        {
            let coin = test_scenario::take_from_sender<Coin<SCC>>(&scenario);
            assert!(coin::value(&coin) == 100, 0);
            let treasurycap = test_scenario::take_from_sender<TreasuryCap<SCC>>(&scenario);
            SCC::burn(&mut treasurycap, coin);
            test_scenario::return_to_address<TreasuryCap<SCC>>(addr1, treasurycap);
        };

        test_scenario::end(scenario);
    }

}