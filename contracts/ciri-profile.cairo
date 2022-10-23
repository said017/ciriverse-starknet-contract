// Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_not_zero, assert_nn, split_felt, assert_not_equal, assert_le
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from openzeppelin.security.safemath.library import SafeUint256
from starkware.cairo.common.cairo_keccak.keccak import keccak_uint256s, keccak_felts, finalize_keccak
from starkware.cairo.common.alloc import alloc
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.introspection.erc165.library import ERC165

from base.ERC721Ciri import ERC721Ciri
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
}(name : felt, symbol : felt, owner : felt, token_uri_len: felt, token_uri: felt*) {
    ERC721Ciri.initialize(name, symbol, owner, token_uri_len, token_uri);
    let profile_cnt : Uint256 = felt_to_uint256(0);
    profile_counter.write(profile_cnt);
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

// // Returns the current balance.
// @view
// func get_balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
//     let (res) = balance.read();
//     return (res,);
// }

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

// @view
// func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//     interface_id: felt
// ) -> (success: felt) {
//     let success = ERC721Ciri.supportsInterface(interface_id);
//     return (success=success);
// }

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
