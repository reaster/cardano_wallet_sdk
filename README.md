# cardano_wallet_sdk

SDK for building [Cardano](https://cardano.org) blockchain mobile apps in [Flutter](https://flutter.dev) using the [Dart](https://dart.dev) programming language.

## Status

Currently it is a [Fund 5 Project Catalyst](https://cardano.ideascale.com/a/dtd/Cardano-Wallet-Flutter-SDK/352623-48088) proof-of-concept prototype with limited use-cases. It is a light-weight client library using a [BlockFrost API](https://pub.dev/packages/blockfrost) service for blockchain access and supports loading wallet balances and submiting simple transactions. 

Under a [Fund 6 proposal](https://cardano.ideascale.com/a/dtd/Cardano-Wallet-Flutter-SDK-Fund6/368970-48088) this library will be expanded into a fully-functional Cardano SDK, supporting smart contracts, minting, staking, key management, hardware wallets and other essential features needed to write dApps and other types of Cardano clients.

## Kick the Tires
To see the SDK in action, you can visit the live [Flutter Demonstration Wallet](https://flutter-cardano-wallet.web.app/) hosted on google cloud.

## Fund 5 Features
* Create Wallets - Create and restore both read-only and transactional wallets using staking addresses, mnemonics or a private keys.
* Transaction history - List transactions, rewards and fees for both ADA and Native Tokens.
* Generate and manage Shelley key pairs and addresses.
* Build, sign and submit simple ADA payment transactions.
* Cardano blockchain access via the [BlockFrost API package](https://github.com/reaster/blockfrost_api)
* Basic CBOR binary encoding

## Usage


### Wallet Management

Create a wallet factory for testnet or mainnet.
```
final walletFactory = ShelleyWalletFactory.fromKey(key: myPolicyId, networkId: testnet);
```

Create a read-only wallet using a staking address.
```
var address = ShelleyAddress.fromBech32('stake_test1uq...vwl7a');
var result = await walletFactory.createReadOnlyWallet(stakeAddress: address);
result.when(
    ok: (w) => print("${w.walletName}: ${w.balance}"),
    err: (err) => print("Error: ${err}"),
);
```

Restore existing wallet using 24 word mnemonic.
```
var mnemonic = 'rude stadium move...gallery receive just';
var result = await walletFactory.createWalletFromMnemonic(
    mnemonic: mnemonic.split(' ')
);
if (result.isOk()) {
    var w = result.unwrap();
    print("${w.walletName}: ${w.balance}"),
}
```

Update existing wallet.
```
var result = await walletFactory.createReadOnlyWallet(stakeAddress: stakeAddress, load: false);
ReadOnlyWallet wallet = result.unwrap();
Coin zeroBalance = wallet.balance;
await walletFactory.updateWallet(wallet: wallet);
result.when(
    ok: (w) => print("old:$zeroBalance ADA, new: ${w.balance} ADA"),
    err: (err) => print("Error: ${err}"),
);
```

Create a new 24 word mnemonic.
```
var mnemonic = walletFactory.generateMnemonic();
print("mnemonic: ${mnemonic.join(' ')}");
```

### Wallet Details

List transaction history.
```
wallet.transactions.forEach((tx) => print("$tx"));
```

List addresses.
```
wallet.addresses().forEach((addr) => print(addr.toBech32()));
```

List currency balances.
```
final formatter = AdaFormattter.compactCurrency();
wallet.currencies.forEach((assetId, balance) {
    final isAda = assetId == lovelaceHex;
    print("$assetId: ${isAda ? formatter.format(balance) : balance}");
});
```

List staking rewards.
```
wallet.stakeAccounts.forEach((acct) {
    acct.rewards.forEach((reward) {
        print("epoch: ${reward.epoch}, ${reward.amount} ADA");
    });
});
```

### Wallet Keys and Addresses 


Access root private and public key pair.
```
Bip32KeyPair pair = wallet.rootKeyPair;
print("${pair.signingKey}, ${pair.verifyKey}");
```

Access staking address.
```
print(wallet.stakingAddress));
```

First unused change address.
```
print(wallet.firstUnusedChangeAddress));
```

First unused spend address.
```
print(wallet.firstUnusedSpendAddress));
```

### Submit Transactions

Send ADA to address.
```
var to = ShelleyAddress.fromBech32('addr1qyy6...');
var result = await wallet.sendAda(toAddress: to, lovelace=:1000000)
if (result.isOk()) { print("ADA sent"); }
```


### Planned [Fund 6 Features](https://cardano.ideascale.com/a/dtd/Cardano-Wallet-Flutter-SDK-Fund6/368970-48088)
* Smart contracts - Consisting of examples and supporting code.
* Persistence - Caching blockchain data to speed state restoration.
* Native Token/NFT - Provide minting and burning support.
* Staking - Provid stake pool ranking and stake delegation support.
* Blockchain Adapter - Abstraction layer to allow multiple blockchain gateways (i.e. Blockfrost, GraphQL, Ogmios and Mithril).
* Secure storage - Encrypted storage solution for private keys and passwords.
* Multi-signature - Support multi-party signatures.
* Alternate Addresses - Support enterprise, pointer and legacy addresses.
* Hardware wallets - Support key storage and signing delegation.
* DApp Linking - Metamask-like Chrome browser extension.

### Running Tests
Many of the unit tests are actualy integration tests that require a blockfrost key to run. Installation steps are as follows:
* git clone git@github.com:reaster/cardano_wallet_sdk.git
* register for a free [blockfrost](https://blockfrost.io/) testnet policy-id key.
* paste the policy-id key into a text file named: blockfrost_project_id.txt in the parent directory of this project.

```
echo "your-project-id" > ../blockfrost_project_id.txt
```
The unit tests should now pass.