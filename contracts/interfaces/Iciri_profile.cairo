%lang starknet

from starkware.cairo.common.uint256 import Uint256

// Dummy token is an ERC20 with a faucet
@contract_interface
namespace ICIRIPROFILE {
    func faucet() -> (success: felt) {
    }

    func get_profile_milestone(profile_id: Uint256) -> (milestone: Uint256) {
    }
   
    func get_donated_fund(address: felt, profile_id: Uint256) -> (fund: Uint256) {
    }

    func tokenOfOwnerByIndex(owner: felt, index: Uint256) -> (tokenId: Uint256) {
    }
}