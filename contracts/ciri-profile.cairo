// Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_le,
    uint256_unsigned_div_rem,
    uint256_sub,
    uint256_mul,
    uint256_add,
)
from starkware.cairo.common.math import assert_not_zero, assert_nn, split_felt, assert_not_equal, assert_le, unsigned_div_rem, assert_le_felt
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from openzeppelin.security.safemath.library import SafeUint256
from starkware.cairo.common.cairo_keccak.keccak import keccak_uint256s, keccak_felts, finalize_keccak
from starkware.cairo.common.alloc import alloc
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.introspection.erc165.library import ERC165

from base.ERC721Ciri import ERC721Ciri
from CIRI_IERC20 import ICIRIERC20
from CIRI_IERC721 import CIRI_IERC721
from openzeppelin.token.erc721.library import ERC721


// ///////////////////
// STRUCTS
// ///////////////////

// creator struct
struct Creator {
    profile_id: Uint256,
    creator_nickname: felt,
    pic: felt,
    funds: Uint256,
    milestone: Uint256,
}

struct Collectible {
    profile_id: Uint256,
    price_to_mint: Uint256,
    gated: felt,
    minted: felt,
    token_id: Uint256,
    // uri_len: felt,
    // uri: felt*,
}

// milestone struct 
// struct Milestone {
//     milestone_id: felt,
//     milestone_price: Uint256,
//     erc20_address: felt,
// }

// MilestonePerDonator struct, to track fund, status of eligible to mint, and minted status (this could be only mapping)
// struct MilestonePerDonator {
//     fund: Uint256,
// }

// ///////////////////
// EVENTS
// ///////////////////

@event
func user_created(account: felt, name: felt, pic: felt) {
}

@event
func donate_sent(creator_address: felt, donator_address: felt, fund: Uint256) {
}

// ///////////////////
// HELPERS
// ///////////////////

func felt_to_uint256{range_check_ptr}(x) -> Uint256 {
    let split = split_felt(x);
    return (Uint256(low=split.low, high=split.high));
}

func uint256_to_address_felt(x : Uint256) -> felt {
    return (x.low + x.high * 2 ** 128);
}

// ///////////////////
// STORAGE VARIABLES
// ///////////////////

// mapping for creators address to its profile
// @storage_var
// func creators_profile(creator_address: felt) -> (creatorStruct: Creator) {
// }

// mapping for creators address to its milestone
@storage_var
func creators_milestone(id: Uint256) -> (milestone_fund: Uint256) {
}

// mapping for donators to mapping of its supported creators and donated funds
@storage_var
func donators_milestone(donator_address: felt, id: Uint256) -> (funds_donated: Uint256) {
}

// mapping for each creators to its donators count
@storage_var
func donators_count(id: Uint256) -> (count: felt) {
}

// creator id creators
@storage_var
func creators_by_id(id: Uint256) -> (creatorStruct: Creator) {
}

// creator collectible id creators
@storage_var
func collectibles_by_id(id: Uint256, index: felt) -> (collectibleStruct: Collectible) {
}

// creator collectible id creators index
@storage_var
func collectibles_by_id_index(id: Uint256) -> (index: felt) {
}

@storage_var
func collectible_token_uri(token_id : Uint256, index : felt, idx: felt) -> (uri : felt){
}

@storage_var
func collectible_token_uri_len(token_id : Uint256, index : felt) -> (res : felt){
}

// profile counter
@storage_var
func profile_counter() -> (number: Uint256) {
}

// profile id by nickname hash
@storage_var
func profile_id_by_nh_storage(nickname : felt) -> (profile_id : Uint256) {
}

// token to mint
// Keeps track of addresses who claimed tokens, and how much
@storage_var
func token_to_minted(account_address: felt) -> (amount: Uint256) {
}

// goerli token address
@storage_var
func goerli_token_address() -> (account_address: felt) {
}

// ciri token address
@storage_var
func ciri_token_address() -> (account_address: felt) {
}

// ciri token address
@storage_var
func collectible_address() -> (account_address: felt) {
}

// ///////////////////
// CONSTRUCTOR
// ///////////////////

// reference inputs :
// name : felt, symbol : felt, owner : felt, token_uri_len: felt, token_uri: felt*
@constructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(name : felt, symbol : felt, owner : felt, goerli_eth: felt, token_uri_len: felt, token_uri: felt*) {
    ERC721Ciri.initialize(name, symbol, owner, token_uri_len, token_uri);
    let profile_cnt : Uint256 = felt_to_uint256(0);
    profile_counter.write(profile_cnt);
    goerli_token_address.write(goerli_eth);
    return();
}

// // Increases the balance by the given amount.
// @external
// func increase_balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//     amount: felt
// ) {
//     let (res) = balance.read();
//     balance.write(res + amount);
//     return ();
// }

// create profile
@external
func create_profile{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
    bitwise_ptr : BitwiseBuiltin*
}(nickname: felt, pic: felt) -> (profile_id : Uint256) {
    alloc_locals;
    let caller: felt = get_caller_address();
    // // struct_array[0] = DataTypes.ProfileStruct(pub_count=publications_count, follow_module=vars.follow_module, follow_nft=0, handle=vars.handle, image_uri=vars.image_uri, follow_nft_uri=vars.follow_nft_uri);
    // let _creator : Creator = creators_profile.read(caller);
    // let _profile_counter: Uint256 = profile_counter.read();
    // // check if it exist or not
    // with_attr error_message("User address registered before") {
    //     assert _creator.creator_address = 0;
    // }   
    let _profile_counter: Uint256 = profile_counter.read();
    let nickname_hash : Uint256 = get_keccak_hash(nickname);
    let nickname_hash_felt : felt = uint256_to_address_felt(nickname_hash);
    let profile_id : Uint256 = SafeUint256.add(_profile_counter, Uint256(1, 0));
    with_attr error_message("Profile ID by Nickname Hash != 0. Such nickname is exists") {
        let profile_id_by_nick_hash : Uint256 = profile_id_by_nh_storage.read(nickname_hash_felt);
        let profile_id_felt : felt = uint256_to_address_felt(profile_id_by_nick_hash);
        assert_not_equal(profile_id_felt, 1);
        assert_le(profile_id_felt, 1);
        //assert_not_zero(profile_id_felt)
    }

    // add new record to profile_id_by_nh_storage storage

    ERC721Ciri.mint(caller, profile_id);
    
    profile_id_by_nh_storage.write(nickname_hash_felt, profile_id);    

    // start with zero
    let zero_value : Uint256 = felt_to_uint256(0);
    // ERC721Ciri.mint(caller, profile_id);
    // PublishingLogic.create_profile(create_profile_data, profile_id, 0);

    // creators_profile.write(caller, Creator(profile_id=profile_id, creator_address=caller, name=name, pic=pic, funds=funds));

    profile_counter.write(profile_id);

    // write also creators array
    creators_by_id.write(profile_id, Creator(profile_id=profile_id, creator_nickname=nickname, pic=pic, funds=zero_value, milestone=zero_value));

    return (profile_id=profile_id);
}

// create collectible
@external
func create_collectible{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
    bitwise_ptr : BitwiseBuiltin*
}(profile_id: Uint256, price_to_mint: Uint256, gated: felt, uri_len: felt, uri: felt*) -> (profile_id : Uint256) {
    alloc_locals;
    let caller: felt = get_caller_address();
    let ownerOf: felt = ERC721.owner_of(profile_id);
    with_attr error_message("Caller != owner of token") {
        assert ownerOf = caller;
    }
    let _collectible_index: felt = collectibles_by_id_index.read(profile_id);
    // write collectibles
    // profile_id: Uint256,
    // price_to_mint: Uint256,
    // gated: felt,
    // uri_len: felt,
    // uri: felt*,
    collectibles_by_id.write(profile_id, _collectible_index, Collectible(profile_id=profile_id,  price_to_mint=price_to_mint, gated=gated, minted=0, token_id=Uint256(0,0))); // , uri_len=uri_len, uri=uri
    _setCollectibleURI(profile_id, _collectible_index, uri_len, uri);
    collectible_token_uri_len.write(profile_id, _collectible_index, uri_len);

    _collectible_index = _collectible_index + 1;
    collectibles_by_id_index.write(profile_id, _collectible_index);
    return (profile_id=profile_id);
}

// mint collectible
@external
func mint_collectible{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
    bitwise_ptr : BitwiseBuiltin*
}(profile_id: Uint256, index: felt, price: Uint256) -> (profile_id : Uint256) {
    alloc_locals;
    let caller: felt = get_caller_address();
    let ownerOf: felt = ERC721.owner_of(profile_id);
    let _collectible_address: felt = collectible_address.read();
    let _token_uri_len : felt =  collectible_token_uri_len.read(profile_id, index);
    with_attr error_message("Owner can't mint Collectibles") {
        assert_not_equal(ownerOf, caller);
    }
    let _collectible : Collectible = collectibles_by_id.read(profile_id, index); 

    // check if already minted
    with_attr error_message("Collectible already minted") {
        assert _collectible.minted = 0;
    }  

    let (_milestone) = get_profile_milestone(profile_id);
    let (_reached) = donators_milestone.read(caller, profile_id);

    // check if already gated
    
    with_attr error_message("You have not reached milestone") {
        if (_collectible.gated == 1) {
            let _milestone_felt : felt = uint256_to_address_felt(_milestone);
            let _reached_felt : felt = uint256_to_address_felt(_reached);
            assert_le(_milestone_felt, _reached_felt);    
            // idk why it work but it works  
            tempvar range_check_ptr = range_check_ptr;  
            // assert_uint256_le(_milestone, _reached);
        } else {
            // idk why it work but it works  
            tempvar range_check_ptr = range_check_ptr;  
        }
    }  
    
   

    // check if price met
    with_attr error_message("Price not meet") {
        let price_to_mint_felt : felt = uint256_to_address_felt(_collectible.price_to_mint);
        let price_felt : felt = uint256_to_address_felt(price);
        assert price_felt = price_to_mint_felt;
    }  

    // get collectible uri len
    let (local _token_uri) = alloc();
   

    _getCollectibleURI(token_id=profile_id, index=index, token_uri_len=_token_uri_len, token_uri=_token_uri);
   

    // go mint
    let index_counter: Uint256 = CIRI_IERC721.mint(_collectible_address, caller,  _token_uri_len, _token_uri);

    // after mint, transfer the goerli to the creator
    let goerli_address: felt = goerli_token_address.read();
    ICIRIERC20.transferFrom(goerli_address, caller, ownerOf, price);

    // update Collectible to minted
    collectibles_by_id.write(profile_id, index, Collectible(profile_id=profile_id,  price_to_mint=_collectible.price_to_mint, gated=_collectible.gated, minted=1, token_id=index_counter));    

    return (profile_id=profile_id);
}

func _setCollectibleURI{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(token_id : Uint256, index: felt, token_uri_len : felt, token_uri : felt*){
    if (token_uri_len == 0) {
        return ();
    }
    collectible_token_uri.write(token_id=token_id, index=index, idx=token_uri_len, value=[token_uri]);
    _setCollectibleURI(token_id=token_id, index=index, token_uri_len=token_uri_len - 1, token_uri=token_uri + 1);
    return ();
}

func _getCollectibleURI{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}( token_id : Uint256, index: felt, token_uri_len : felt, token_uri : felt*){
    alloc_locals;
    if (token_uri_len == 0) {
        return ();
    }
    let (base) = collectible_token_uri.read(token_id, index=index, idx=token_uri_len);
    assert [token_uri] = base;
    _getCollectibleURI( token_id=token_id, index=index,
       token_uri_len=token_uri_len - 1, token_uri=token_uri + 1
    );
    return ();
}

// donate function
@external
func donate{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
    bitwise_ptr : BitwiseBuiltin*
}(_creator_id: Uint256, _amount: Uint256) -> (amount : Uint256) {
    alloc_locals;
    let caller: felt = get_caller_address();
    let goerli_address: felt = goerli_token_address.read();
    let contract_address: felt = get_contract_address();

    with_attr error_message("Not accepting 0 eth or below") {
        let _amount_felt : felt = uint256_to_address_felt(_amount);
        assert_nn(_amount_felt);
        assert_not_zero(_amount_felt);
    }

    // get value to mint CIRI token
    let (value_to_mint) = token_to_minted.read(caller);

    // get value so far donated to this id by this caller
    let (value_donated) = donators_milestone.read(donator_address=caller,id=_creator_id);

    // get funds of creator
    let creator : Creator = creators_by_id.read(_creator_id);
   
    let (to_mint, _) = uint256_unsigned_div_rem(_amount, Uint256(10,0));
    let (to_donate, _) = uint256_mul(to_mint, Uint256(9,0));

    // transfer amount from caller to this address (all amount transfered)
    ICIRIERC20.transferFrom(goerli_address, caller, contract_address, _amount);
    // set the withdraw to value+ 90% amount 
    let (amount_updated, carry) = uint256_add(value_donated, to_donate);
    donators_milestone.write(caller,_creator_id, amount_updated);
    // update creator funds funds + 90% amount
    let (funds_updated, carry) = uint256_add(creator.funds, to_donate);
    creators_by_id.write(_creator_id, Creator(profile_id=_creator_id, creator_nickname=creator.creator_nickname, pic=creator.pic, funds=funds_updated, milestone=creator.milestone)); 
    // token to mint value + 10% amount
    let (mint_updated, carry) = uint256_add(value_to_mint, to_mint);
    token_to_minted.write(caller, mint_updated);   

    return (amount=_amount);
}

// claim ciri token
@external
func claim{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
    bitwise_ptr : BitwiseBuiltin*
}() -> (amount : Uint256) {
    alloc_locals;
    let caller: felt = get_caller_address();
    let ciri_address: felt = ciri_token_address.read();

    // get value to mint CIRI token
    let (value_to_mint) = token_to_minted.read(caller);

    with_attr error_message("You don't have any token to claim") {
        let _amount_felt : felt = uint256_to_address_felt(value_to_mint);
        assert_nn(_amount_felt);
        assert_not_zero(_amount_felt);
    }

    // 1 ETH = 100 CIRI
    // amount update accordingly
    let (amount_ciri_mint, carry) = uint256_add(value_to_mint, Uint256(100,0));  

    // mint according to value
    ICIRIERC20.mint(ciri_address, caller, amount_ciri_mint);
    // reset token to minted
    token_to_minted.write(caller, Uint256(0,0));   

    return (amount=amount_ciri_mint);
}

// set milestone
@external
func set_creator_milestone{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
    bitwise_ptr : BitwiseBuiltin*
}(profile_id: Uint256, _milestone: felt) -> (update_milestone : Uint256) {
    alloc_locals;
    // need to check ownership once become NFTs
    let caller: felt = get_caller_address();
     let ownerOf: felt = ERC721.owner_of(profile_id);
    with_attr error_message("Caller != owner of token") {
        assert ownerOf = caller;
    }

    let milestone_uint256 : Uint256 = felt_to_uint256(_milestone);

    let creator : Creator = creators_by_id.read(profile_id);

    creators_by_id.write(profile_id, Creator(profile_id=profile_id, creator_nickname=creator.creator_nickname, pic=creator.pic, funds=creator.funds, milestone=milestone_uint256));

    return (update_milestone=milestone_uint256);
}

// transfer creator NFTs
@external
func transferFrom{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
}(_from: felt, to: felt, token_id: Uint256) {
    let ownerOf: felt = ERC721.owner_of(token_id);
    with_attr error_message("From != owner of token") {
        assert ownerOf = _from;
    }
    ERC721Ciri.transferFrom(_from, to, token_id);
    return();
}

@external
func safeTransferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _from: felt, to: felt, token_id: Uint256, data_len: felt, data: felt*
) {
    ERC721Ciri.safeTransferFrom(_from, to, token_id, data_len, data);
    return ();
}

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_owner: felt
) -> (new_owner: felt) {
    // Ownership check is handled by this function
    Ownable.transfer_ownership(new_owner);
    return (new_owner=new_owner);
}

@external
func setTokenURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    base_token_uri_len: felt, base_token_uri: felt*
) {
    Ownable.assert_only_owner();
    ERC721Ciri.setTokenURI(base_token_uri_len, base_token_uri);
    return ();
}

@external
func setGoerliAddress{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    goerli_address: felt
) {
    Ownable.assert_only_owner();
    goerli_token_address.write(goerli_address);
    return ();
}

@external
func setCiriAddress{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    ciri_address: felt
) {
    Ownable.assert_only_owner();
    ciri_token_address.write(ciri_address);
    return ();
}

// set approve
@external
func approve{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }(to: felt, token_id: Uint256) {
    ERC721Ciri.approve(to, token_id);
    return();
}

@external
func setApprovalForAll{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }(operator: felt, approved: felt) {
    ERC721Ciri.setApprovalForAll(operator, approved);
    return();
}

@view    
func get_profile_counter{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (number: Uint256) {
    let _number : Uint256 = profile_counter.read();
    return (number=_number);
}

@view    
func get_profile_milestone{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(profile_id: Uint256) -> (milestone: Uint256) {
    let creator : Creator = creators_by_id.read(profile_id);
    return (milestone=creator.milestone);
}

@view    
func get_donated_fund{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(address: felt, profile_id: Uint256) -> (fund: Uint256) {
    let (value_donated) = donators_milestone.read(donator_address=address,id=profile_id);
    return (fund=value_donated);
}

@view    
func get_token_to_mint{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(address: felt) -> (fund: Uint256) { 
    let (value_to_mint) = token_to_minted.read(address);
    return (fund=value_to_mint);
}

@view func get_profile_by_id{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
    }(profile_id : Uint256) -> (name : felt, pic : felt, funds : Uint256, creator_id : Uint256) {
    let creator : Creator = creators_by_id.read(profile_id);
    return (creator.creator_nickname, creator.pic, creator.funds, creator.profile_id);
}

@view
func tokenURI{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
    ) -> (token_uri_len : felt, token_uri : felt*) {
        let (token_uri_len, token_uri) = ERC721Ciri.tokenURI(token_id);
        return (token_uri_len=token_uri_len, token_uri=token_uri);
}


@view
func getOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    let (owner) = Ownable.owner();
    return (owner=owner);
}

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interface_id: felt
) -> (success: felt) {
    let success = ERC721Ciri.supportsInterface(interface_id);
    return (success);
}

@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    let (name) = ERC721Ciri.name();
    return (name,);
}

@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    let (symbol) = ERC721Ciri.symbol();
    return (symbol,);
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) -> (
    balance: Uint256
) {
    let (balance: Uint256) = ERC721Ciri.balanceOf(owner);
    return (balance,);
}

@view
func ownerOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (owner: felt) {
    let (owner: felt) = ERC721Ciri.ownerOf(token_id);
    return (owner,);
}

@view
func getApproved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (approved: felt) {
    let (approved: felt) = ERC721Ciri.getApproved(token_id);
    return (approved,);
}

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, operator: felt
) -> (is_approved: felt) {
    let (is_approved: felt) = ERC721Ciri.isApprovedForAll(owner, operator);
    return (is_approved,);
}

@view    
func get_collectible_at{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(profile_id: Uint256, index : felt) -> (collectible: Collectible) {
    let _collectible : Collectible = collectibles_by_id.read(profile_id, index);
    return (collectible=_collectible);
}

func get_keccak_hash{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
    bitwise_ptr : BitwiseBuiltin*
    }(value_to_hash : felt) -> (res: Uint256) {

    alloc_locals;

    let (local keccak_ptr_start) = alloc();
    let keccak_ptr = keccak_ptr_start;
    let (local arr : felt*) = alloc();
    assert arr[0] = value_to_hash;


    let hashed_value = keccak_felts{keccak_ptr=keccak_ptr}(1, arr);
    finalize_keccak(keccak_ptr_start=keccak_ptr_start, keccak_ptr_end=keccak_ptr);

    return hashed_value;
}
