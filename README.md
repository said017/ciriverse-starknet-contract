# 🌌 Ciriverse Cairo Smart Contracts 🌌   

_NFTs Based Engagement Platform!_

**Ciriverse Protocol Diagram**

![ Ciriverse Protocol Diagram](https://i.ibb.co/TWycQZz/ciri-diagram-protocol.png)

- - -
# What Problems are Ciriverse Try to Solve?
## limited Currency Options
Usually it's complicated and only accepting fiat currency to support creators/fans. We provide crypto payment as an options for creators/artists.

## NO Digital Product & Interaction from EXISTING Solutions
We provide many potential integration and future features (NFTs, DAOs) to enable creators/artist building their communities.

## Not Open and Centralized Existing Solutions.
We make payment, NFT engagement and interaction between creators/artists more transparent and open by putting everything on-chain.
- - -
# 🌠 Our Solutions 🌠
Ciriverse, a place where you can grow and maintain your audience as Content Creators, Artists and Streamers. Providing platform to interacting better with your fans such as Engagement NFTs, Content Goals and NFTs Community gating.
- - -
Consist of 4 Main Contracts :

1. `ciri_profile.cairo` for NFTs based Creator Graph, main contracts to hold users and NFTs features gating.
2. `Ciri_ERC721.cairo` for ERC721 Collectibles to mint from creators, can be gated by milestone from Creator Profile.
3. `ciri_vote.cairo` for Polling/Interaction based on Milestone setted by creator on profile contract above, vote using ERC20 Ciri Token.
4. `Ciri_ERC20.cairo` for ERC20 Ciri Token, generated/minted by donation to creator (10% Eth donation x 1000). Used for interacting with polls created by Creator

Try to run using Nile:

```shell
nile compile
nile deploy <contract_name> <args>
```

- - -
# Ciriverse Walkthrough
The app is live at [here](https://www.ciriverse.xyz) and here is the [demo video](https://www.youtube.com/watch?v=5MtAVihVe3k). Walktrough available for 2 perspectives:
- Creator's
- Fan's

## Creator's.
First creator create NFTs profile, providing nickname and profile picture (optional), Then creator can setup collectible that can be minted by their fans, and polling for interacting with fans (deciding which game to play, what art to create etc.) then he setup milestone (optional) for deciding the minimal value donated from fans so they can participate in voting or buy creators NFTs. And every interaction in Ciriverse can be seen in streamer/content creator streaming setups (OBS Studio etc.) by integrating the ciriverse overlay links.

Ciriverse Creator Summary:
1. Create Profile
2. Manage Collectible NFTs
3. Check the donated ETH
4. Setup Polling for interaction
5. Setup Milestone for Interaction Gating
6. Withdraw donated ETH

## Fan's 
The most anticipated path for fans to interact with Ciriverse is from Streamers overlay links. Fans see content creator links and interact with it, go to creator's Ciriverse page, in there fans can donate ETH, Mint collectibles NFT and interact with available pollings using CIRI Token (if elligible and passed defined milestone value). Fans also can Mint CIRI Token that they elligible to Mint (Based on Calculation 10% donated ETH x 1000).  All interactions will be shown in streamers live streams.

Ciriverse Fans Summary:
1. Explore all ciriverse creators
2. View the creator profile
3. Donate ETH to the creator
4. Mint Creator Collectible NFTs
5. Mint CIRI Token
6. Interact with Polling

- - -

Related Repos :
- [Front-end](https://github.com/said017/cairo-fe-ciri)
- [Notification Server](https://github.com/said017/ciriverse-stark-notification)
- [Apibara Indexer (Work On Progress)](https://github.com/said017/ciri-event-indexer-ts)

Testnet Contracts :

- [Creator Profile](https://testnet.starkscan.co/contract/0x022da370305a2281f811c7c9ff4d9ec75f8acf5e0b15adbc589bcc99a6b2eca7)
- [Collectible NFTs Contract](https://testnet.starkscan.co/contract/0x06e7d4f14ec221b02d82477101d4d53094b543f550a51a641855d2c9d32626d5)
- [Voting Contract](https://testnet.starkscan.co/contract/0x04bf2dba38a4c358184a6c3070b349512041a8564e124698e1c8dae4989bde16)
- [Ciri Token](https://testnet.starkscan.co/contract/0x053b40ff949ebdda717f68f2a5c90121387c4a1caa4f9a5343933d1ba61b59a7)

Aspect NFTs Marketplace links :

- [Profile NFTs](https://testnet.aspect.co/collection/0x022da370305a2281f811c7c9ff4d9ec75f8acf5e0b15adbc589bcc99a6b2eca7)
- [Collectible NFTs](https://testnet.aspect.co/collection/0x06e7d4f14ec221b02d82477101d4d53094b543f550a51a641855d2c9d32626d5)

