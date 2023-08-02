module nft_in_sui::artwork {
    use sui::url::{Self, Url};

    use sui::object::{Self, ID, UID};
    use sui::event;

    use sui::tx_context::{sender, Self, TxContext};

    use std::string::{utf8, String};
    use sui::transfer;

    use sui::package;
    use sui::display;

    struct ArtworkNFT has key, store {
        id: UID,
        name: String,
        description: String,
        url: Url,
        creator: address
    }

    struct ARTWORK has drop {}

    fun init(otw: ARTWORK, ctx: &mut TxContext) {
        let keys = vector[
            utf8(b"name"),
            utf8(b"image_url"),
            utf8(b"description"),
            utf8(b"project_url"),
            utf8(b"creator"),
        ];

        let values = vector[
            utf8(b"{name}"),
            utf8(b"{url}"),
            utf8(b"{description}"),
            utf8(b"https://www.movebit.xyz/"),
            utf8(b"{creator}")
        ];

        let publisher = package::claim(otw, ctx);
        let display = display::new_with_fields<ArtworkNFT>(
            &publisher, keys, values, ctx
        );

        display::update_version(&mut display);
        let nft = ArtworkNFT {
            id: object::new(ctx),
            name: utf8(b"My ArtworkNFT"),
            description: utf8(b"A NFT on Sui"),
            creator: sender(ctx),
            url: url::new_unsafe_from_bytes(b"https://wallpaperaccess.com/full/2648080.jpg"),

        };
        transfer::public_transfer(nft, sender(ctx));
        transfer::public_transfer(publisher, sender(ctx));
        transfer::public_transfer(display, sender(ctx));
    }


    // ===== Events =====

    struct ArtworkMinted has copy, drop {
        object_id: ID,
        creator: address,
        name: String,
    }

    // ===== Public view functions =====
    /// Get the NFT's `name`
    public fun name(nft: &ArtworkNFT): &String {
        &nft.name
    }

    /// Get the NFT's `description`
    public fun description(nft: &ArtworkNFT): &String {
        &nft.description
    }

    /// Get the NFT's `creator`
    public fun creator(nft: &ArtworkNFT): &address {
        &nft.creator
    }


    /// Get the NFT's `url`
    public fun url(nft: &ArtworkNFT): &Url {
        &nft.url
    }

    // ===== Entrypoints =====
    public entry fun mint_to_sender(
        name: vector<u8>,
        description: vector<u8>,
        url: vector<u8>,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
         let nft = ArtworkNFT {
            id: object::new(ctx),
            name: utf8(name),
            description: utf8(description),
            creator: sender(ctx),
            url: url::new_unsafe_from_bytes(url),

        };

        event::emit(ArtworkMinted {
            object_id: object::id(&nft),
            creator: sender,
            name: nft.name,
        });

        transfer::public_transfer(nft, sender);
    }

    /// Transfer `nft` to `recipient`
    public entry fun transfer(
        nft: ArtworkNFT, recipient: address, _: &mut TxContext
    ) {
        transfer::public_transfer(nft, recipient)
    }

    #[test_only]
    use sui::test_scenario;

    #[test]
    public fun test() {
        let test_addr = @0x3;
        let test_addr_mint = @0x4;
        let scenario = test_scenario::begin(test_addr);
        let test = &mut scenario;
        let witness = ARTWORK{};
    
        test_scenario::next_tx(test, test_addr);
        {
            init(witness, test_scenario::ctx(test));
        };

        test_scenario::next_tx(test, test_addr);
        {
            let nft = test_scenario::take_from_address<ArtworkNFT>(test, test_addr);

            assert!(description(&nft) == &utf8(b"A NFT on Sui"), 0);
            assert!(name(&nft) == &utf8(b"My ArtworkNFT"), 0);
            assert!(creator(&nft) == &test_addr, 0);
            assert!(url(&nft) == &url::new_unsafe_from_bytes(b"https://wallpaperaccess.com/full/2648080.jpg"), 0);
            

            test_scenario::return_to_sender(test, nft);
        };

        test_scenario::next_tx(test, test_addr_mint);
        {
           mint_to_sender(
            b"My ArtworkNFT",
            b"A NFT on Sui", 
            b"https://wallpaperaccess.com/full/2648080.jpg",
            test_scenario::ctx(test));
        };

        test_scenario::next_tx(test, test_addr_mint);
        {
           let nft = test_scenario::take_from_address<ArtworkNFT>(test, test_addr_mint);

            assert!(description(&nft) == &utf8(b"A NFT on Sui"), 0);
            assert!(name(&nft) == &utf8(b"My ArtworkNFT"), 0);
            assert!(creator(&nft) == &test_addr_mint, 0);
            assert!(url(&nft) == &url::new_unsafe_from_bytes(b"https://wallpaperaccess.com/full/2648080.jpg"), 0);
            
            test_scenario::return_to_sender(test, nft);
        };

        test_scenario::end(scenario);
    }

    
}