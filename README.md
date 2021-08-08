# cardano_wallet_sdk

SDK for building Cardano blockchain mobile apps in Flutter.

## About

This project is a Cardano blockchain on-ramp for Flutter/Dart mobile app developers.  Currently a work in progress as a Fund5
[Project Catalyst](https://cardano.ideascale.com/a/dtd/Cardano-Wallet-Flutter-SDK/352623-48088) proposal.

It powers a live [Flutter Demonstration Wallet](https://flutter-cardano-wallet.web.app/) hosted on google cloud.

### Current Features
* pricing service powered by [Coin Gecko](https://www.coingecko.com/)
* Cardano blockchain access via a seperate [BlockFrost API package](https://github.com/reaster/blockfrost_api)
* public wallet creation via a stakeAddress
* track native tokens and their transactions
* track staking and rewards (partial: most recent pool only)
* CBOR binary encoding

### Features In Active Development
* create, submit or track transactions and their fees
* sign and validate messages
* manage private and public keys
* list, create, update or remove wallets

### Planned Features
* staking
* native tokens
* token exchange
* smart contracts

### Usage
In the same parent directory place the following assets:
* git clone git@github.com:reaster/cardano_wallet_sdk.git
* register for a free [blockfrost](https://blockfrost.io/) policy-id key.
* paste the policy-id key into a text file named: blockfrost_project_id.txt

The unit tests should now pass.