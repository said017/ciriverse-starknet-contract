# Ciriverse Cairo Smart Contracts

**Ciriverse Protocol Diagram**

![ Ciriverse Protocol Diagram](https://i.ibb.co/TWycQZz/ciri-diagram-protocol.png)

Consist of 4 Contracts :

1. `ciri-profile.cairo` for NFTs based Creator Graph, main contracts to hold users and NFTs features gating.
2. `Ciri_ERC721.cairo` for ERC721 Collectibles to mint from creators, can be gated by milestone from Creator Profile.
3. `ciri_vote.cairo` for Polling/Interaction based on Milestone setted by creator on profile contract above, vote using ERC20 Ciri Token.
4. `Ciri_ERC20.cairo` for ERC20 Ciri Token, generated/minted by donation to creator (10% Eth donation x 1000). Used for interacting with polled created by Creator

Try to run using Nile:

```shell
nile compile
nile deploy <contract_name> <args>
```
Related Repos :
- [Front-end](https://github.com/said017/cairo-fe-ciri)
- [Notification Server](https://github.com/said017/ciriverse-stark-notification)

Testnet Contracts :

- [Creator Profile](https://testnet.starkscan.co/contract/0x03ea63dc43f089f652bec64f2a13427bf95b84fd214b85c2e2cda1ff91259117)
- [Collectible NFTs Contract](https://testnet.starkscan.co/contract/0x03ea63dc43f089f652bec64f2a13427bf95b84fd214b85c2e2cda1ff91259117)
- [Voting Contract](https://testnet.starkscan.co/contract/0x03ea63dc43f089f652bec64f2a13427bf95b84fd214b85c2e2cda1ff91259117)
- [Ciri Token](https://testnet.starkscan.co/contract/0x03ea63dc43f089f652bec64f2a13427bf95b84fd214b85c2e2cda1ff91259117)

