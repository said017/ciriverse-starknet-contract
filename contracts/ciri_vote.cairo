// Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_nn, split_felt, assert_not_equal, assert_le, unsigned_div_rem, assert_le_felt
from starkware.starknet.common.syscalls import (
    get_block_number,
    get_block_timestamp,
)
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import (
    Uint256,
    assert_uint256_le,
    uint256_le,
    // uint256_unsigned_div_rem,
    // uint256_sub,
    // uint256_mul,
    // uint256_add,
)
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from CIRI_IERC721 import CIRI_IERC721
from Iciri_profile import ICIRIPROFILE
from CIRI_IERC20 import ICIRIERC20

// ///////////////////
// STRUCTS
// ///////////////////

struct Proposal {
    deadline: felt,
    option1: felt,
    option2: felt,
    votesOpt1: felt,
    votesOpt2: felt,
    executed: felt,
    result: felt,
    // uri_len: felt,
    // uri: felt*,
}

func felt_to_uint256{range_check_ptr}(x) -> Uint256 {
    let split = split_felt(x);
    return (Uint256(low=split.low, high=split.high));
}

func uint256_to_address_felt(x : Uint256) -> felt {
    return (x.low + x.high * 2 ** 128);
}

// mapping of profile_id to proposals.
@storage_var
func proposals(profile_id: Uint256, index: felt) -> (structProposal: Proposal) {
}

// mapping of profile_id to proposal_index.
@storage_var
func proposal_index(profile_id: Uint256) -> (index: felt) {
}

// ciri-profile address.
@storage_var
func ciri_address_storage() -> (address: felt) {
}

// ciri-token address.
@storage_var
func token_address_storage() -> (address: felt) {
}

@constructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(ciri_address: felt, token_address: felt) {
    ciri_address_storage.write(ciri_address);
    token_address_storage.write(token_address);
    return();
}

// create proposal.
@external
func create_proposal{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    profile_id: Uint256, option1: felt, option2: felt, time_to_lock: felt
) {
    let caller: felt = get_caller_address();
    let _ciri_address: felt = ciri_address_storage.read();
    // check if caller owned the profile_id
    let ownerOf: felt = CIRI_IERC721.ownerOf(_ciri_address, profile_id);
    with_attr error_message("You are not owner of this profile_id") {
        assert ownerOf = caller;
    }
    // read index first
    let _proposal_index: felt = proposal_index.read(profile_id); 
    let (block_timestamp) = get_block_timestamp();
    // deadline: felt,
    // option1: felt,
    // option2: felt,
    // votesOpt1: felt,
    // votesOpt2: felt,
    // executed: felt,
    // result: felt,
    proposals.write(profile_id, _proposal_index, Proposal(deadline=block_timestamp + time_to_lock, option1=option1, option2=option2, votesOpt1=0, votesOpt2=0, executed=0, result=0));   
    let _proposal_index_new : felt = _proposal_index + 1;
    proposal_index.write(profile_id, _proposal_index_new);   
    return ();
}

// vote proposal.
@external
func vote_proposal{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    profile_id: Uint256, index: felt, vote: felt, amount: Uint256
) {
    alloc_locals;
    let caller: felt = get_caller_address();
    let proposal : Proposal = proposals.read(profile_id, index);
    let (block_timestamp) = get_block_timestamp();
    let _ciri_address: felt = ciri_address_storage.read();
    // first check if vote still ongoing
    with_attr error_message("Proposal not active anymore") {
        assert_le(block_timestamp, proposal.deadline);
    }

    // then check if elligible to vote by checking the milestone
    let creator_milestone: Uint256 = ICIRIPROFILE.get_profile_milestone(_ciri_address, profile_id);
    let donators_milestone: Uint256 = ICIRIPROFILE.get_donated_fund(_ciri_address, caller, profile_id);

    with_attr error_message("Donators haven't reach milestone") {
        assert_uint256_le(creator_milestone, donators_milestone);
    }

    // check his ciri coin balance
    let (_token_address) = token_address_storage.read();

    let _balance : Uint256 = ICIRIERC20.balanceOf(_token_address, caller);

    with_attr error_message("Balance not enough") {
        assert_uint256_le(amount, _balance);
    }
    // convert amount to vote count
    let _vote : felt = uint256_to_address_felt(amount);

    // update the vote

    if (vote == 0) {
        let _updated_vote : felt =  proposal.votesOpt1 + _vote;
        proposals.write(profile_id, index, Proposal(deadline=proposal.deadline, option1=proposal.option1, option2=proposal.option2, votesOpt1=_updated_vote, votesOpt2=proposal.votesOpt2, executed=proposal.executed, result=proposal.result)); 
        tempvar syscall_ptr = syscall_ptr;
    } else {
        let _updated_vote : felt =  proposal.votesOpt2 + _vote;
        proposals.write(profile_id, index, Proposal(deadline=proposal.deadline, option1=proposal.option1, option2=proposal.option2, votesOpt1=proposal.votesOpt1, votesOpt2=_updated_vote, executed=proposal.executed, result=proposal.result)); 
        tempvar syscall_ptr = syscall_ptr;
    }

    // burn the ciri
    ICIRIERC20.burn_tokens(_token_address, caller, amount); 
    return ();
}

// execute proposal
@external
func execute_proposal{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    profile_id: Uint256, index: felt
) {
    alloc_locals;
    let caller: felt = get_caller_address();
    let proposal : Proposal = proposals.read(profile_id, index);
    let (block_timestamp) = get_block_timestamp();
    let _ciri_address: felt = ciri_address_storage.read();
    // first scheck if proposal inactive

    // then execute it
    let opt1 : Uint256 = felt_to_uint256(proposal.votesOpt1);
    let opt2 : Uint256 = felt_to_uint256(proposal.votesOpt2);
    let res : felt = uint256_le(opt2,opt1);
    if (res == 1) {
        proposals.write(profile_id, index, Proposal(deadline=proposal.deadline, option1=proposal.option1, option2=proposal.option2, votesOpt1=proposal.votesOpt1, votesOpt2=proposal.votesOpt2, executed=1, result=proposal.option1));         
    } else {
        proposals.write(profile_id, index, Proposal(deadline=proposal.deadline, option1=proposal.option1, option2=proposal.option2, votesOpt1=proposal.votesOpt1, votesOpt2=proposal.votesOpt2, executed=1, result=proposal.option2));         
    }
    return ();
}

// Returns proposal at index
@view
func get_proposal{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(profile_id: Uint256, index: felt) -> (proposal : Proposal) {
    let proposal : Proposal = proposals.read(profile_id, index);
    return (proposal=proposal);
}

// Returns proposal count
@view
func get_num_proposal{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(profile_id: Uint256, index: felt) -> (proposal_count : felt) {
    let proposal_count  : felt = proposal_index.read(profile_id);
    return (proposal_count=proposal_count);
}