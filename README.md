<p align="center">
    <a href="https://github.com/reaster/cardano_wallet_sdk/actions/workflows/test-package.yml">
    <img src="https://github.com/reaster/cardano_wallet_sdk/workflows/Dart%20CI/badge.svg" alt="CI status" /></a>
    <a href="https://github.com/reaster/cardano_wallet_sdk/stargazers">
    <img src="https://img.shields.io/github/stars/reaster/cardano_wallet_sdk.svg?style=flat&logo=github&colorB=blue&label=stars" alt="Stars count on GitHub" /></a>
    <a href="https://pub.dev/packages/cardano_wallet_sdk">
	<img src="https://img.shields.io/pub/v/cardano_wallet_sdk.svg?style=flat&logo=github&colorB=blue" alt="Latest Release on pub.dev" /></a>
    <a href="https://codecov.io/gh/reaster/cardano_wallet_sdk">
    <img src="https://codecov.io/gh/reaster/cardano_wallet_sdk/branch/main/graph/badge.svg?token=ZR5AO2WML0"/></a>
</p>

---

# cardano_wallet_sdk

SDK for building [Cardano](https://cardano.org) blockchain mobile apps in [Flutter](https://flutter.dev) using the [Dart](https://dart.dev) programming language.

<div align="center">
    <img style="margin:5px;" src="https://github.com/reaster/cardano_wallet_sdk/raw/main/example/flutter_example/screenshots/FlutterSDK_Drawer_iPadPro9_7-inch.png" width="200px"</img> 
    <img style="margin:5px;" src="https://github.com/reaster/cardano_wallet_sdk/raw/main/example/flutter_example/screenshots/FlutterSDK_ListWallets_iPodTouch7thGen.png" width="100px"</img> 
    <img style="margin:5px;" src="https://github.com/reaster/cardano_wallet_sdk/raw/main/example/flutter_example/screenshots/FlutterSDK_Sliders_MacOS.png" width="200px"</img> 
    <img style="margin:5px;" src="https://github.com/reaster/cardano_wallet_sdk/raw/main/example/flutter_example/screenshots/FlutterSDK_DarkMode_MacOS.png" width="200px"</img> 
</div>

## Status

This project started as a [Fund 5 Project Catalyst](https://cardano.ideascale.com/a/dtd/Cardano-Wallet-Flutter-SDK/352623-48088) proof-of-concept prototype with limited use-cases. The prototype SDK implements a light-weight client library using the [BlockFrost API](https://pub.dev/packages/blockfrost) service for blockchain access and supports loading wallet balances and submitting simple transactions. 

Currently this library is being refactored into a production quality Cardano SDK, supporting simple smart contracts, minting, staking, key management and other features needed to write dApps and other types of Cardano clients. This phase is scheduled to be completed in 2022 using a [Fund 7 grant](https://cardano.ideascale.com/a/dtd/Flutter-SDK/381288-48088).

This is an ambitious project and will require much ongoing maintenance, development and community support. If you'd like to see this project succeed, please support us by voting for the Flutter SDK in [Fund 8](https://cardano.ideascale.com/c/idea/400720)! This will go towards higher-level smart contract features, backend improvements, third-party dependency reductions, architectural improvements, documentation and tutorials.

If you'd like to can contribute directly, the Flutter SDK has a dedicated wallet:
```
  addr1qx90lkpwhpwu42jnw00w483krjyfvhhpgk97hdfw9nz3xqaqg6dycrrc4qw0l5fsvfgx95gnqmrfxhgrfy8afsxxje5qgplx9r
```

## Kick the Tires
To see the SDK in action, both a pure [Dart example](https://github.com/reaster/cardano_wallet_sdk/blob/main/example/dart_example.dart) and multi-platform [Flutter example](https://github.com/reaster/cardano_wallet_sdk/tree/main/example/flutter_example) are incuded in this distribution. You can also visit the live [Flutter Demonstration Wallet](https://flutter-cardano-wallet.web.app/) hosted on google cloud.

## Current ([Fund 5](https://cardano.ideascale.com/a/dtd/Cardano-Wallet-Flutter-SDK/352623-48088)) Features
* Create Wallets - Create and restore, both read-only and transactional wallets using staking addresses, mnemonics or private keys.
* Transaction History - List transactions, rewards and fees for both ADA and Native Tokens.
* Addresses - Generate and manage Shelley key pairs and addresses.
* Transactions - Build, sign and submit simple ADA payment transactions.
* Blockchain API - Cardano blockchain access via the [BlockFrost API package](https://github.com/reaster/blockfrost_api)
* Binary Encoding - Enough [CBOR](https://cbor.io) support is provided to submit simple payment transactions.

## Usage

Released versions and installation details can be found on [pub.dev](https://pub.dev/packages/cardano_wallet_sdk/install).

### Coding Style

Although Dart is an imperative language, the framework uses functional idioms whenever possible. In particular, 
the majority of the classes are immutible and rather than creating side effects by throwing 
exceptions, the Result class is used. The WalletBuilder's build method
provides a concrete example, returning either a wallet instance or error message if issues arise:
```dart
Result<Wallet, String> result = walletBuilder.build();
result.when(
    ok: (wallet) => print("Success: ${wallet.walletName}"),
    err: (message) => print("Error: $message"),
);
```

### Wallet Management

Create a wallet builder for the testnet using a [BlockFrost](https://github.com/reaster/blockfrost_api) key.
```dart
final walletBuilder = WalletBuilder()
    ..networkId = NetworkId.testnet
    ..testnetAdapterKey = blockfrostKey;
```

Create a read-only wallet using a staking address.
```dart
var address = ShelleyAddress.fromBech32('stake_test1uqvwl7a...');
final walletBuilder = WalletBuilder()
    ..networkId = NetworkId.testnet
    ..testnetAdapterKey = blockfrostKey
    ..stakeAddress = address;
Result<ReadOnlyWallet, String> result = await walletBuilder.readOnlyBuildAndSync();
result.when(
    ok: (wallet) => print("${wallet.walletName}: ${wallet.balance}"),
    err: (message) => print("Error: $message"),
);
```

Restore existing wallet using 24 word mnemonic.
```dart
List<String> mnemonic = 'rude stadium move gallery receive just...'.split(' ');
final walletBuilder = WalletBuilder()
    ..networkId = NetworkId.testnet
    ..testnetAdapterKey = blockfrostKey
    ..mnemonic = mnemonic;
Result<Wallet, String> result = await walletBuilder.buildAndSync();
if (result.isOk()) {
    var wallet = result.unwrap();
    print("${wallet.walletName}: ${wallet.balance}");
}
```

Update existing wallet.
```dart
final walletBuilder = WalletBuilder()
    ..networkId = NetworkId.testnet
    ..testnetAdapterKey = blockfrostKey
    ..mnemonic = mnemonic;
Result<Wallet, String> result = walletBuilder.build();
Wallet wallet = result.unwrap();
Coin oldBalance = wallet.balance;
var result2 = await wallet.update();
result2.when(
    ok: (_) => print("old:$oldBalance lovelace, new: ${wallet.balance} lovelace"),
    err: (message) => print("Error: $message"),
);
```

Create a new 24 word mnemonic.
```dart
List<String> mnemonic = WalletBuilder.generateNewMnemonic();
print("mnemonic: ${mnemonic.join(' ')}");
```

### Wallet Details

List transaction history.
```dart
wallet.transactions.forEach((tx) => print(tx));
```

List addresses.
```dart
wallet.addresses.forEach((addr) => print(addr.toBech32()));
```

List currency balances.
```dart
final formatter = AdaFormattter.compactCurrency();
wallet.currencies.forEach((assetId, balance) {
    final isAda = assetId == lovelaceHex;
    print("$assetId: ${isAda ? formatter.format(balance) : balance}");
});
```

List staking rewards.
```dart
wallet.stakeAccounts.forEach((acct) {
    acct.rewards.forEach((reward) {
        print("epoch: ${reward.epoch}, ${reward.amount} ADA");
    });
});
```

### Wallet Keys and Addresses 


Access root private and public key pair.
```dart
Bip32KeyPair pair = wallet.rootKeyPair;
print("${pair.signingKey}, ${pair.verifyKey}");
```

Access staking address.
```dart
print(wallet.stakingAddress));
```

First unused change address.
```dart
print(wallet.firstUnusedChangeAddress));
```

First unused spend address.
```dart
print(wallet.firstUnusedSpendAddress));
```

### Submit Transactions

Send 3 ADA to Bob.
```dart
var bobsAddress = ShelleyAddress.fromBech32('addr1qyy6...');
final Result<ShelleyTransaction, String> result = await wallet.sendAda(
    toAddress: bobsAddress,
    lovelace: 3 * 1000000,
);
if (result.isOk()) {
    final tx = result.unwrap();
    print("ADA sent. Fee: ${tx.body.fee} lovelace");
}
```


### Planned Features
* Smart Contracts - 2022: Consisting of examples and supporting code.
* Native Token/NFT - 2022: Provide minting and burning support.
* Staking - 2022: Provide stake pool ranking and stake delegation support.
* Secure Storage - 2022: Encrypted storage solution for private keys and passwords.
* Alternate Addresses - 2022: Support enterprise, pointer and legacy addresses.
* Multi-signature - 2023: Support multi-party signatures.
* Blockchain Adapter - 2023: Abstraction layer to allow multiple blockchain gateways (i.e. Blockfrost, GraphQL, Ogmios and 
Mithril).

### Running Integration Tests
Several of the integration tests (suffixed with '_itest.dart') require a BlockFrost key to run. Installation steps are as follows:
* git clone git@github.com:reaster/cardano_wallet_sdk.git
* register for a free [BlockFrost](https://blockfrost.io/) testnet policy-id key.
* paste the policy-id key into a text file named: blockfrost_project_id.txt in the parent directory of this project.

```
echo "your-project-id" > ../blockfrost_project_id.txt
```
Now you can include the integration tests:
```
dart test -P itest
```

***
Copyright 2021 Richard Easterling\
SPDX-License-Identifier: Apache-2.0