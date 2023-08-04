
module subscribe::subscribe {
    use sui::coin::{Coin, Self};
    use sui::tx_context::{TxContext, Self};
    use sui::transfer;
    use sui::table::{Table, Self};
    use sui::clock::{Clock, Self};
    use sui::sui::{SUI};
    use sui::object::{UID, Self};
    use sui::event;


    struct GlobalConfig has key, store {
        id: UID,
        admin: address,
        subscribe_id: u64,
        subscribe_store: Table<u64, Subscribe>,
    }

    struct SubscribeCreateEvent has copy, drop {
        id: u64,
        sender: address,        
        recipient: address,     
        interval: u64,          
        rate_per_interval: u64, 
        start_time: u64,        
        stop_time: u64,         
        create_at: u64,         
    }

    struct WithdrawEvent has copy, drop {
        id: u64,
        recipient: address,     
        value: u64,         
    }


    struct Subscribe has store {
        id: u64,
        sender: address,        
        recipient: address,     
        interval: u64,          
        rate_per_interval: u64, 
        start_time: u64,        
        stop_time: u64,         
        create_at: u64,         
        deposit_amount: u64,    
        withdrawn_amount: u64,  
        remaining_amount: u64,  
        last_withdraw_time: u64,
        closed: bool,           
        reverse: Coin<SUI>
    }

    struct TimeEvent has copy, drop {
        timestamp_ms: u64
    }
    
    public fun timestamp(clock: &Clock) {
        event::emit(TimeEvent {
            timestamp_ms: clock::timestamp_ms(clock)
        })
    }


    fun init(ctx: &mut TxContext) {
        let owner_addr = tx_context::sender(ctx);

        transfer::public_share_object(GlobalConfig {
            id: object::new(ctx),
            subscribe_id: 1,
            admin: owner_addr,
            subscribe_store: table::new<u64, Subscribe>(ctx),
        });
    }

    struct SubscribeDetail has copy, drop {
        id: u64,
        sender: address,        
        recipient: address,     
        interval: u64,          
        rate_per_interval: u64, 
        start_time: u64,        
        stop_time: u64,         
        create_at: u64,  
        reverse: u64
    }

    public fun subscribe_detail(global: &mut GlobalConfig, id: u64) {
        let subscribe = table::borrow_mut(&mut global.subscribe_store, id);
        event::emit(SubscribeDetail {
            id: subscribe.id,
            sender: subscribe.sender,        
            recipient: subscribe.recipient,     
            interval: subscribe.interval,          
            rate_per_interval: subscribe.rate_per_interval, 
            start_time: subscribe.start_time,        
            stop_time: subscribe.stop_time,         
            create_at: subscribe.create_at,  
            reverse: coin::value(&subscribe.reverse)
        })
    }

    /// create a subscribe
    public entry fun subscribe(
        global: &mut GlobalConfig,
        clock: &Clock,
        recipient: address,
        deposit_coin: &mut Coin<SUI>,
        deposit_amount: u64,
        start_time: u64,
        stop_time: u64,
        interval: u64,
        ctx: &mut TxContext
    ) {
        let sender_address = tx_context::sender(ctx);
        let current_time = clock::timestamp_ms(clock);
        assert!(stop_time >= start_time && stop_time >= current_time, 0);

        let subscribe_id = global.subscribe_id;
        global.subscribe_id = global.subscribe_id + 1;

        let duration = (stop_time - start_time) / interval;
        let rate_per_interval: u64 = deposit_amount * 1000 / duration;
        assert!(interval * duration + start_time == stop_time, 0);


        let subscribe = Subscribe {
            id: 1,
            sender: sender_address,
            recipient,
            interval,
            rate_per_interval,
            start_time,
            stop_time,
            last_withdraw_time: start_time,
            create_at: current_time,
            deposit_amount,
            withdrawn_amount: 0u64,
            remaining_amount: 0u64,
            closed: false,
            reverse: coin::zero<SUI>(ctx)
        };

        event::emit(SubscribeCreateEvent {
            id: 1,
            sender: sender_address,
            recipient,
            interval,
            rate_per_interval,
            start_time,
            stop_time,
            create_at: current_time,
        });
        
        subscribe.remaining_amount = deposit_amount;
        coin::join<SUI>(&mut subscribe.reverse, coin::split(deposit_coin, deposit_amount, ctx));

        table::add(&mut global.subscribe_store, subscribe_id, subscribe);
    }


    /// recipient withdraw the coin from subscribe
    public fun withdraw(
        global: &mut GlobalConfig, 
        clock: &Clock, 
        subscribe_id: u64, 
        ctx: &mut TxContext
    ): Coin<SUI> {
        let receive_addr = tx_context::sender(ctx);
        let current_time = clock::timestamp_ms(clock);
        assert!(table::contains(&global.subscribe_store, subscribe_id), 0);

        let subscribe = table::borrow_mut(&mut global.subscribe_store, subscribe_id);
        assert!(subscribe.recipient == receive_addr, 0);
        assert!(current_time > subscribe.start_time, 0);
        assert!(subscribe.remaining_amount > 0, 0);

        withdraw_(subscribe, current_time, ctx)
    }

    public entry fun withdraw_and_trasfer(
        global: &mut GlobalConfig, 
        clock: &Clock, 
        subscribe_id: u64, 
        ctx: &mut TxContext
    ) {
        transfer::public_transfer(withdraw(global, clock, subscribe_id, ctx), tx_context::sender(ctx)); 
    }

    /// extend user's subscribe
    public entry fun extend(
        global: &mut GlobalConfig,
        deposit_coin: Coin<SUI>,
        new_stop_time: u64,
        subscribe_id: u64,
        ctx: &mut TxContext
    ){
        let sender_address = tx_context::sender(ctx);

        let subscribe = table::borrow_mut(&mut global.subscribe_store, subscribe_id);
        assert!(subscribe.sender == sender_address, 0);
        assert!(new_stop_time > subscribe.stop_time, 0);

        let duration = (new_stop_time - subscribe.stop_time) / subscribe.interval;
        let deposit_amount = duration * subscribe.rate_per_interval / 1000;
        assert!(subscribe.interval * duration + subscribe.stop_time == new_stop_time, 0);

        coin::join(&mut subscribe.reverse, deposit_coin);

        subscribe.stop_time = new_stop_time;
        subscribe.remaining_amount = subscribe.remaining_amount + deposit_amount;
        subscribe.deposit_amount = subscribe.deposit_amount + deposit_amount;
    }

    // close subscribe and return money
    public fun close(
        global: &mut GlobalConfig,
        clock: &Clock,
        subscribe_id: u64,
        ctx: &mut TxContext
    ): (Coin<SUI>, Coin<SUI>) {
        let sender_address = tx_context::sender(ctx);
        let current_time = clock::timestamp_ms(clock);

        let subscribe = table::remove(&mut global.subscribe_store, subscribe_id);
        assert!(current_time < subscribe.stop_time, 0);
        assert!(subscribe.sender == sender_address, 0);

        let return_coin = withdraw_(&mut subscribe, current_time, ctx);

        subscribe.remaining_amount = 0;

        let Subscribe {
            id: _,
            sender: _,        
            recipient: _,     
            interval: _,          
            rate_per_interval: _, 
            start_time: _,        
            stop_time: _,         
            last_withdraw_time: _,
            create_at: _,         
            deposit_amount: _,    
            withdrawn_amount: _,  
            remaining_amount: _,  
            closed: _,           
            reverse: reverse
         } = subscribe;

        (reverse, return_coin)
    }

    fun withdraw_( 
        subscribe: &mut Subscribe,
        current_time: u64,
        ctx: &mut TxContext
        ): Coin<SUI> {
        let delta = if(current_time < subscribe.last_withdraw_time){
            0u64
        }else {
            (current_time - subscribe.last_withdraw_time) / subscribe.interval
        };
        if (delta == 0) {
            return coin::zero<SUI>(ctx)
        };

        let (withdraw_amount, withdraw_time) = if (current_time < subscribe.stop_time) {
            (subscribe.rate_per_interval * delta / 1000, subscribe.last_withdraw_time + delta * subscribe.interval)
        } else {
            (subscribe.remaining_amount, subscribe.stop_time)
        };

        assert!(withdraw_amount <= subscribe.remaining_amount && withdraw_amount <= coin::value(&subscribe.reverse), 0);
        subscribe.withdrawn_amount = subscribe.withdrawn_amount + withdraw_amount;
        subscribe.remaining_amount = subscribe.remaining_amount - withdraw_amount;
        subscribe.last_withdraw_time = withdraw_time;

        let coin = coin::split(&mut subscribe.reverse, withdraw_amount, ctx);
        event::emit(WithdrawEvent {
            id: subscribe.id,
            recipient: tx_context::sender(ctx),
            value: coin::value(&coin)
        });

        coin
    }


    #[test_only]
    use sui::test_scenario::{Self, ctx};
    #[test_only]
    use std::debug::print;

    #[test]
    public fun subscribe_test() {
        let test_addr = @0x3;
        let receive_addr = @0x4;

        let scenario = test_scenario::begin(test_addr);
        let test = &mut scenario;
        let clock = clock::create_for_testing(ctx(test));
    
        test_scenario::next_tx(test, test_addr);
        {
            init(test_scenario::ctx(test));
        };
        
        test_scenario::next_tx(test, test_addr);
        {
            let global = test_scenario::take_shared<GlobalConfig>(test);

            let c1 = coin::mint_for_testing(1000, ctx(test));
            let c2 = coin::mint_for_testing(1000, ctx(test));
            let c3 = coin::mint_for_testing(1000, ctx(test));

            subscribe(
                &mut global, 
                &clock, 
                receive_addr, 
                &mut c1,
                1000,
            0,
                100,
                10,
                ctx(test)
                );
            
            subscribe(
                &mut global, 
                &clock, 
                receive_addr, 
                &mut c2,
                1000,
                100,
                200,
                10,
                ctx(test)
                );

            subscribe(
                &mut global, 
                &clock, 
                receive_addr, 
                &mut c3,
                1000,
                200,
                300,
                10,
                ctx(test)
                );

            coin::burn_for_testing(c1);
            coin::burn_for_testing(c2);
            coin::burn_for_testing(c3);
            test_scenario::return_shared<GlobalConfig>(global);
        };
        test_scenario::next_tx(test, receive_addr);
        {
            let global = test_scenario::take_shared<GlobalConfig>(test);

            clock::set_for_testing(&mut clock, 40);
            let coin1 = withdraw(&mut global, &clock, 1, ctx(test));
            print(&coin1);
            assert!(coin::value(&coin1) == 400, 0);

            clock::set_for_testing(&mut clock, 80);
            let coin2 = withdraw(&mut global, &clock, 1, ctx(test));
            assert!(coin::value(&coin2) == 400, 0);

            clock::set_for_testing(&mut clock, 100);
            let coin3 = withdraw(&mut global, &clock, 1, ctx(test));
            assert!(coin::value(&coin3) == 200, 0);

            coin::burn_for_testing(coin1);
            coin::burn_for_testing(coin2);
            coin::burn_for_testing(coin3);
            test_scenario::return_shared<GlobalConfig>(global);
        };

        // test close 
        test_scenario::next_tx(test, receive_addr);
        {
            let global = test_scenario::take_shared<GlobalConfig>(test);

            clock::set_for_testing(&mut clock, 150);
            let coin = withdraw(&mut global, &clock, 2, ctx(test));
            assert!(coin::value(&coin) == 500, 0);
          
            coin::burn_for_testing(coin);
            test_scenario::return_shared<GlobalConfig>(global);
        };
        test_scenario::next_tx(test, test_addr);
        {
            let global = test_scenario::take_shared<GlobalConfig>(test);
            clock::set_for_testing(&mut clock, 170);
            let (sender_coin, receiver_coin) = close(&mut global, &clock, 2, ctx(test));

            assert!(coin::value(&sender_coin) == 300, 0);
            assert!(coin::value(&receiver_coin) == 200, 0);
          
            coin::burn_for_testing(sender_coin);
            coin::burn_for_testing(receiver_coin);
            test_scenario::return_shared<GlobalConfig>(global);
        };

        // test extend
        test_scenario::next_tx(test, test_addr);
        {
            let global = test_scenario::take_shared<GlobalConfig>(test);

            extend(
                &mut global, 
                coin::mint_for_testing(500, ctx(test)), 
                350, 
                3, 
                ctx(test)
            );
           
            test_scenario::return_shared<GlobalConfig>(global);
        };

        test_scenario::next_tx(test, receive_addr);
        {
            let global = test_scenario::take_shared<GlobalConfig>(test);

            clock::set_for_testing(&mut clock,330);
            let coin1 = withdraw(&mut global, &clock, 3, ctx(test));
            assert!(coin::value(&coin1) == 1300, 0);

            coin::burn_for_testing(coin1);
            test_scenario::return_shared<GlobalConfig>(global);
        };


        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }
    
}
