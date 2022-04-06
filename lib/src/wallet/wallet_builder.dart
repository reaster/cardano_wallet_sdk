// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:bip32_ed25519/bip32_ed25519.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32_ed25519/api.dart';
import 'package:oxidized/oxidized.dart';
import 'package:dio/dio.dart';
import '../address/hd_wallet.dart';
import '../address/shelley_address.dart';
import '../blockchain/blockchain_adapter.dart';
import '../blockchain/blockchain_adapter_factory.dart';
import '../blockchain/blockfrost/blockfrost_blockchain_adapter.dart';
import '../network/network_id.dart';
import '../transaction/coin_selection.dart';
import './impl/read_only_wallet_impl.dart';
import './impl/wallet_impl.dart';
import './read_only_wallet.dart';
import './wallet.dart';

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
  BlockchainAdapter? _blockchainAdapter;
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
  set blockchainAdapter(BlockchainAdapter adapter) =>
      _blockchainAdapter = adapter;

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

  /// Reset wallet-specific properties. Preserves that NetworkId and BlockchainAdapter.
  void reset() {
    _stakeAddress = null;
    _walletName = null;
    _rootSigningKey = null;
    _hdWallet = null;
    _mnemonic = null;
  }

  /// Create a read-only wallet matching the supplied properties. Resets the builder.
  Result<ReadOnlyWallet, String> readOnlyBuild() {
    if (_stakeAddress == null) {
      return Err("Read-only wallet creation requires a staking address");
    }
    _walletName ??= "Wallet #${_walletNameIndex++}";
    if (_blockchainAdapter != null) {
      if (_blockchainAdapter! is BlockfrostBlockchainAdapter) {
        _networkId =
            (_blockchainAdapter as BlockfrostBlockchainAdapter).networkId;
      }
    } else {
      _networkId ??= NetworkId.mainnet;
      final adapterResult = _lookupOrCreateBlockchainAdapter(
        networkId: _networkId!,
        key: _networkId! == NetworkId.mainnet
            ? _mainnetAdapterKey
            : _testnetAdapterKey,
      );
      if (adapterResult.isErr()) return Err(adapterResult.unwrapErr());
      _blockchainAdapter = adapterResult.unwrap();
    }

    final wallet = ReadOnlyWalletImpl(
      blockchainAdapter: _blockchainAdapter!,
      stakeAddress: _stakeAddress!,
      walletName: _walletName!,
    );
    reset();
    return Ok(wallet);
  }

  /// Create a read-only wallet and syncronize it's transactions with the blockchain.
  /// Resets the builder.
  Future<Result<ReadOnlyWallet, String>> readOnlyBuildAndSync() async {
    final walletResult = readOnlyBuild();
    if (walletResult.isErr()) return Err(walletResult.unwrapErr());
    final wallet = walletResult.unwrap();
    final updateResult = await wallet.update();
    if (updateResult.isErr()) return Err(updateResult.unwrapErr());
    return Ok(wallet);
  }

  /// Create a transactional wallet matching the supplied properties.
  /// Resets the builder.
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
    _walletName ??= "Wallet #${_walletNameIndex++}";
    if (_blockchainAdapter != null) {
      if (_blockchainAdapter! is BlockfrostBlockchainAdapter) {
        _networkId =
            (_blockchainAdapter as BlockfrostBlockchainAdapter).networkId;
      }
    } else {
      _networkId ??= NetworkId.mainnet;
      final adapterResult = _lookupOrCreateBlockchainAdapter(
        networkId: _networkId!,
        key: _networkId! == NetworkId.mainnet
            ? _mainnetAdapterKey
            : _testnetAdapterKey,
      );
      if (adapterResult.isErr()) return Err(adapterResult.unwrapErr());
      _blockchainAdapter = adapterResult.unwrap();
    }
    final stakeKeyPair = _hdWallet!.deriveAddressKeys(role: stakingRole);
    final stakeAddress = _hdWallet!.toRewardAddress(
        spend: stakeKeyPair.verifyKey!, networkId: _networkId!);
    final addressKeyPair = _hdWallet!.deriveAddressKeys(account: accountIndex);
    //printKey(addressKeyPair);
    final wallet = WalletImpl(
      blockchainAdapter: _blockchainAdapter!,
      stakeAddress: stakeAddress,
      addressKeyPair: addressKeyPair,
      walletName: _walletName!,
      hdWallet: _hdWallet!,
      coinSelectionFunction: _coinSelectionFunction,
    );
    reset();
    return Ok(wallet);
  }

  /// Create a transactinoal wallet and syncronize it's transactions with the blockchain.
  /// Resets the builder.
  Future<Result<Wallet, String>> buildAndSync() async {
    final walletResult = build();
    if (walletResult.isErr()) return Err(walletResult.unwrapErr());
    final wallet = walletResult.unwrap();
    final updateResult = await wallet.update();
    if (updateResult.isErr()) return Err(updateResult.unwrapErr());
    return Ok(wallet);
  }

  /// Generate a unique 24-word mnumonic phrase which can be used to create a
  /// new wallet.
  static List<String> generateNewMnemonic() =>
      (bip39.generateMnemonic(strength: 256)).split(' ');

  static final Map<NetworkId, BlockchainAdapterFactory>
      _blockchainAdapterFactoryCache = {};
  static final Map<NetworkId, BlockchainAdapter> _blockchainAdapterCache = {};

  static Result<BlockchainAdapter, String> _lookupOrCreateBlockchainAdapter(
      {required NetworkId networkId, String? key}) {
    BlockchainAdapter? adapter = _blockchainAdapterCache[networkId];
    if (adapter != null) return Ok(adapter);
    BlockchainAdapterFactory? factory =
        _blockchainAdapterFactoryCache[networkId];
    if (factory == null) {
      if (key == null) {
        return Err(
            "no BlockFrost key supplied for ${networkId.toString()} network");
      }
      Interceptor authInterceptor =
          BlockchainAdapterFactory.interceptorFromKey(key: key);
      factory = BlockchainAdapterFactory(
          authInterceptor: authInterceptor,
          networkId: networkId,
          projectId: key);
      _blockchainAdapterFactoryCache[networkId] = factory;
    }
    adapter = factory.adapter();
    _blockchainAdapterCache[networkId] = adapter;
    return Ok(adapter);
  }
}
