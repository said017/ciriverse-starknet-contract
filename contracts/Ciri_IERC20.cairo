%lang starknet

from starkware.cairo.common.uint256 import Uint256

// Dummy token is an ERC20 with a faucet
@contract_interface
namespace ICIRIERC20 {
    func faucet() -> (success: felt) {
    }

    func name() -> (name: felt) {
    }

    func symbol() -> (symbol: felt) {
    }

    func decimals() -> (decimals: felt) {
    }

    func totalSupply() -> (totalSupply: Uint256) {
    }

    func balanceOf(account: felt) -> (balance: Uint256) {
    }

    func allowance(owner: felt, spender: felt) -> (remaining: Uint256) {
    }

    func transfer(recipient: felt, amount: Uint256) -> (success: felt) {
    }

    func transferFrom(sender: felt, recipient: felt, amount: Uint256) -> (success: felt) {
    }

    func approve(spender: felt, amount: Uint256) -> (success: felt) {
    }

    func mint(to: felt, amount: Uint256) {
    }

    func burn_tokens(recipient: felt, amount_ask: Uint256) -> (amount_burn: Uint256) {
    }   
}