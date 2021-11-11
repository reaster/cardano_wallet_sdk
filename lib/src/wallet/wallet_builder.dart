// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/src/address/hd_wallet.dart';
import 'package:cardano_wallet_sdk/src/address/shelley_address.dart';
import 'package:cardano_wallet_sdk/src/blockchain/blockchain_adapter.dart';
import 'package:cardano_wallet_sdk/src/blockchain/blockchain_adapter_factory.dart';
import 'package:cardano_wallet_sdk/src/blockchain/blockfrost/blockfrost_blockchain_adapter.dart';
import 'package:cardano_wallet_sdk/src/network/network_id.dart';
import 'package:cardano_wallet_sdk/src/transaction/coin_selection.dart';
import 'package:cardano_wallet_sdk/src/wallet/impl/read_only_wallet_impl.dart';
import 'package:cardano_wallet_sdk/src/wallet/impl/wallet_impl.dart';
import 'package:cardano_wallet_sdk/src/wallet/read_only_wallet.dart';
import 'package:cardano_wallet_sdk/src/wallet/wallet.dart';
import 'package:bip32_ed25519/bip32_ed25519.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32_ed25519/api.dart';
import 'package:oxidized/oxidized.dart';
import 'package:dio/dio.dart';

///
/// This builder creates both read-only and transactional wallets from provided
/// properties. Generated from a staking addresses, read-only wallets can show
/// a balance and recieve funds, but can't sign or send payment transactions.
/// Transactional wallets require a cryptographic private/signing key and can
/// sign and send payment transactions. Alternatively, private keys can be
/// generated from a 24-word mnemonic phrase. A BlockchainAdapter is used to
/// communicate with the blockchain, it defaults to BlockfrostBlockchainAdapter
/// for which an authorization adapter key must be provided for the target
/// network. Each wallet type has a sync-varient build method that will load
/// it's transactions and calculate the current balance before returning.
/// Finally, all wallets must choose to run on either the mainnet or testnet.
///
class WalletBuilder {
  NetworkId? _networkId;
  String? _walletName;
  BlockchainAdapter? _adapter;
  String? _testnetAdapterKey;
  String? _mainnetAdapterKey;
  ShelleyAddress? _stakeAddress;
  List<String>? _mnemonic;
  Bip32SigningKey? _rootSigningKey;
  int accountIndex = defaultAccountIndex;
  HdWallet? _hdWallet;
  CoinSelectionAlgorithm _coinSelectionFunction = largestFirst;

  static int _walletNameIndex = 1;

  /// Set the staking address needed for creating read-only wallets.
  set stakeAddress(ShelleyAddress stakeAddress) => _stakeAddress = stakeAddress;

  /// Set the testnet authorization key required to access a given blockchain adapter like blockfrost.
  set testnetAdapterKey(String? testnetAdapterKey) =>
      _testnetAdapterKey = testnetAdapterKey;

  /// Set the mainnet authorization key required to access a given blockchain adapter like blockfrost.
  set mainnetAdapterKey(String? mainnetAdapterKey) =>
      _mainnetAdapterKey = mainnetAdapterKey;

  /// Set a pre-configured adapter used for accessing the blockchain.
  set adapter(BlockchainAdapter adapter) => _adapter = adapter;

  /// Set optional wallet name, like the owner or purpose of the wallet.
  set walletName(String? walletName) => _walletName = walletName;

  /// Set the NetworkId of the blockchain, either testnet or mainnet.
  set networkId(NetworkId? networkId) => _networkId = networkId;

  /// Set a preconfigured HdWallet wallet instance.
  set hdWallet(HdWallet hdWallet) => _hdWallet = hdWallet;

  /// Set the root private or signing key for this wallet.
  set rootSigningKey(Bip32SigningKey? rootSigningKey) =>
      _rootSigningKey = rootSigningKey;

  // set seed(Uint8List seed) => _seed = seed;

  /// Set the 24-word mnemonic used to create or restore a wallet.
  set mnemonic(List<String> mnemonic) => _mnemonic = mnemonic;

  /// Set the prefered CoinSelectionAlgorithm, defaults to largestFirst.
  set coinSelectionAlgorithm(CoinSelectionAlgorithm coinSelectionAlgorithm) =>
      _coinSelectionFunction = coinSelectionAlgorithm;

  /// Create a read-only wallet matching the supplied properties.
  Result<ReadOnlyWallet, String> readOnlyBuild() {
    if (_stakeAddress == null)
      return Err("Read-only wallet creation requires a staking address");
    if (_walletName == null) {
      _walletName = "Wallet #${_walletNameIndex++}";
    }
    if (_adapter != null) {
      if (_adapter! is BlockfrostBlockchainAdapter) {
        _networkId = (_adapter as BlockfrostBlockchainAdapter).networkId;
      }
    } else {
      if (_networkId == null) _networkId = NetworkId.mainnet;
      final adapterResult = _lookupOrCreateBlockchainAdapter(
        networkId: _networkId!,
        key: _networkId! == NetworkId.mainnet
            ? _mainnetAdapterKey
            : _testnetAdapterKey,
      );
      if (adapterResult.isErr()) return Err(adapterResult.unwrapErr());
      _adapter = adapterResult.unwrap();
    }

    final wallet = ReadOnlyWalletImpl(
      blockchainAdapter: _adapter!,
      stakeAddress: _stakeAddress!,
      walletName: _walletName!,
    );
    return Ok(wallet);
  }

  /// Create a read-only wallet and syncronize it's transactions with the blockchain.
  Future<Result<ReadOnlyWallet, String>> readOnlyBuildAndSync() async {
    final walletResult = readOnlyBuild();
    if (walletResult.isErr()) return Err(walletResult.unwrapErr());
    final wallet = walletResult.unwrap();
    final updateResult = await wallet.update();
    if (updateResult.isErr()) return Err(updateResult.unwrapErr());
    return Ok(wallet);
  }

  /// Create a transactional wallet matching the supplied properties.
  Result<Wallet, String> build() {
    if (_hdWallet != null) {
      _rootSigningKey = _hdWallet!.rootSigningKey;
    } else {
      if (_mnemonic != null) {
        _hdWallet = HdWallet.fromMnemonic(_mnemonic!.join(' '));
        _rootSigningKey = _hdWallet!.rootSigningKey;
      } else if (_rootSigningKey != null) {
        _hdWallet = HdWallet(rootSigningKey: _rootSigningKey!);
      } else {
        return Err("wallet creation requires a 'rootPrivateKey' or 'mnemonic'");
      }
    }
    if (_walletName == null) {
      _walletName = "Wallet #${_walletNameIndex++}";
    }
    if (_adapter != null) {
      if (_adapter! is BlockfrostBlockchainAdapter) {
        _networkId = (_adapter as BlockfrostBlockchainAdapter).networkId;
      }
    } else {
      if (_networkId == null) _networkId = NetworkId.mainnet;
      final adapterResult = _lookupOrCreateBlockchainAdapter(
        networkId: _networkId!,
        key: _networkId! == NetworkId.mainnet
            ? _mainnetAdapterKey
            : _testnetAdapterKey,
      );
      if (adapterResult.isErr()) return Err(adapterResult.unwrapErr());
      _adapter = adapterResult.unwrap();
    }
    final stakeKeyPair = _hdWallet!.deriveAddressKeys(role: stakingRole);
    final stakeAddress = _hdWallet!.toRewardAddress(
        spend: stakeKeyPair.verifyKey!, networkId: _networkId!);
    final addressKeyPair = _hdWallet!.deriveAddressKeys(account: accountIndex);
    //printKey(addressKeyPair);
    final wallet = WalletImpl(
      blockchainAdapter: _adapter!,
      stakeAddress: stakeAddress,
      addressKeyPair: addressKeyPair,
      walletName: _walletName!,
      hdWallet: _hdWallet!,
      coinSelectionFunction: _coinSelectionFunction,
    );
    return Ok(wallet);
  }

  /// Create a transactinoal wallet and syncronize it's transactions with the blockchain.
  Future<Result<Wallet, String>> buildAndSync() async {
    final walletResult = build();
    if (walletResult.isErr()) return Err(walletResult.unwrapErr());
    final wallet = walletResult.unwrap();
    final updateResult = await wallet.update();
    if (updateResult.isErr()) return Err(updateResult.unwrapErr());
    return Ok(wallet);
  }

  ///generate mnumonic words to be used by new wallet.
  List<String> generateNewMnemonic() =>
      (bip39.generateMnemonic(strength: 256)).split(' ');

  static Map<NetworkId, BlockchainAdapterFactory>
      _blockchainAdapterFactoryCache = {};
  static Map<NetworkId, BlockchainAdapter> _blockchainAdapterCache = {};

  static Result<BlockchainAdapter, String> _lookupOrCreateBlockchainAdapter(
      {required NetworkId networkId, String? key}) {
    BlockchainAdapter? adapter = _blockchainAdapterCache[networkId];
    if (adapter != null) return Ok(adapter);
    BlockchainAdapterFactory? factory =
        _blockchainAdapterFactoryCache[networkId];
    if (factory == null) {
      if (key == null)
        return Err(
            "no BlockFrost key supplied for ${networkId.toString()} network");
      Interceptor authInterceptor =
          BlockchainAdapterFactory.interceptorFromKey(key: key);
      factory = BlockchainAdapterFactory(
          authInterceptor: authInterceptor, networkId: networkId);
      _blockchainAdapterFactoryCache[networkId] = factory;
    }
    adapter = factory.adapter();
    _blockchainAdapterCache[networkId] = adapter;
    return Ok(adapter);
  }
}
