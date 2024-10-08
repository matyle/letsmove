/// Module: hello_nft
module hello_nft::hello_nft {
    use std::string::{String,utf8};
    use sui::table::{Self,Table};
    use sui::package;
    use sui::display;
    use sui::event;


    const MAX_SUPPLY:u64 = 10;
    const ENotEnoughSupply:u64= 0;
    const EDontMintAgain:u64 = 1;

    public struct HELLO_NFT has drop{}

    public struct HelloNft has key,store{
        id:UID,
        nft_id:u64,
        name:String,
        image_url:String,
        creator:address,
        recipient:address,
    }

    public struct MintRecord has key {
        id: UID,
        record:Table<address,u64>,
    }

    public struct NFTMinted has copy,drop{
        object_id:ID,
        creator:address,
        name:String,
    }

    fun init(otw:HELLO_NFT,ctx:&mut TxContext){
        let publisher = package::claim(otw,ctx);

        let keys = vector[
            utf8(b"name"),
            utf8(b"description"),
            utf8(b"image_url"),
            utf8(b"creator"),
        ];

        let values = vector[
            utf8(b"{name} ${nft_id}"),
            utf8(b"A HEELO NFT "),
            utf8(b"https://pub-c7c3a09e8d7b4cd3bff5014134cfa3a0.r2.dev/20240813145008.png"),
            utf8(b"matyle"),
        ];

        let mint_record = MintRecord{
            id:object::new(ctx),
            record:table::new<address,u64>(ctx),
        };

        let mut _display = display::new_with_fields<HelloNft>(&publisher,keys,values,ctx);
        display::update_version(&mut _display);
        transfer::public_transfer(publisher,ctx.sender());
        transfer::public_transfer(_display,ctx.sender());
        transfer::share_object(mint_record);
    }

    // sui call 中对应 4个参数
    public entry fun mint(mint_record:&mut MintRecord,name:String,image_url:String,recipient: address,ctx:&mut TxContext){
        assert!(!table::contains(&mint_record.record,recipient),EDontMintAgain);
        let nft_id = table::length(&mint_record.record)+1;
        assert!(nft_id <= MAX_SUPPLY,ENotEnoughSupply);
        table::add(&mut mint_record.record,recipient,nft_id);
        let nft: HelloNft = HelloNft{
            id:object::new(ctx),
            name,
            image_url,
            nft_id,
            recipient,
            creator:ctx.sender(),
        };
        event::emit(NFTMinted{
            object_id:object::id(&nft),
            name,
            creator:ctx.sender(),
        });
        transfer::public_transfer(nft,recipient);
    }

    public entry fun burn(mint_record:&mut MintRecord,nft:HelloNft){
        table::remove(&mut mint_record.record,nft.recipient);
        let HelloNft{id,recipient:_,name:_,nft_id:_,creator:_,image_url:_}=nft;
        object::delete(id);
    }

  
}
