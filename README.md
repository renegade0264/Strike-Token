# Strike-Token

A Web app that tracks bowling scores and has a built in reward system in cryptocurrency and a minting platform to buy the crypto.

## Overview

This is an Internet Computer (ICP) smart contract written in Motoko that provides:

- **Bowling Score Tracking**: Track games, players, frames, and scores
- **Player Statistics**: Calculate averages, track spares, strikes, and achievements
- **Team Management**: Create teams, manage memberships, and track team stats
- **Token Economics**: STK token system with multiple pools and rewards
- **Minting Platform**: Purchase STK tokens with ICP
- **Wallet Management**: Manage ICP and STK balances
- **Social Features**: In-game chat and user profiles
- **Access Control**: Role-based permissions system

## Project Structure

```
Strike-Token/
├── renegade.mo                  # Main actor/canister code
├── dfx.json                     # DFX configuration
├── authorization/
│   └── access-control.mo        # Role-based access control module
├── blob-storage/
│   ├── Mixin.mo                 # Blob storage mixin
│   └── registry.mo              # File reference registry
└── http-outcalls/
    └── outcall.mo               # HTTP outcall module for price feeds
```

## Token Pools

The STK token has a total supply of 1,000,000 tokens distributed across:

- **Treasury Reserves**: 400,000 STK
- **Minting Platform**: 200,000 STK
- **In-Game Rewards**: 150,000 STK
- **Admin Team Wallet**: 150,000 STK
- **NFT Staking Rewards**: 100,000 STK

## Development

To build and deploy this project, you'll need:

1. Install the [DFINITY Canister SDK](https://internetcomputer.org/docs/current/developer-docs/setup/install)
2. Start the local replica: `dfx start --background`
3. Deploy the canister: `dfx deploy`

## License

[Add your license here]
