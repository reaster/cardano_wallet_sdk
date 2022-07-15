// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:bip32_ed25519/bip32_ed25519.dart';
// import 'package:cardano_wallet_sdk/src/crypto/mnemonic_english.dart';
import 'package:cardano_wallet_sdk/src/crypto/shelley_key_derivation.dart';
import '../crypto/icarus_key_derivation.dart';
import 'package:bip32_ed25519/api.dart';
import 'package:oxidized/oxidized.dart';
import 'package:dio/dio.dart';
import '../address/shelley_address.dart';
import '../blockchain/blockchain_adapter.dart';
import '../blockchain/blockchain_adapter_factory.dart';
// import '../crypto/mnemonic.dart';
import '../network/network_id.dart';
import '../transaction/coin_selection.dart';
import '../util/codec.dart';
import './impl/read_only_wallet_impl.dart';
import './impl/wallet_impl.dart';
import './read_only_wallet.dart';
import './wallet.dart';
import 'account.dart';

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
  Networks? _network;
  String? _walletName;
  BlockchainAdapter? _blockchainAdapter;
  String? _testnetAdapterKey;
  String? _mainnetAdapterKey;
  ShelleyAddress? _stakeAddress;
  List<String>? _mnemonic;
  String? _rootSigningKey;
  int accountIndex = 0;
  HdAccount? _hdAccount;
  CoinSelectionAlgorithm _coinSelectionFunction = largestFirst;
  //LoadMnemonicWordsFunction loadWordsFunction = loadEnglishMnemonicWords();

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
  set network(Networks? network) => _network = network;

  /// Set a preconfigured HdAccount instance.
  set hdAccount(HdAccount hdAccount) => _hdAccount = hdAccount;

  /// Set the root private or signing key for this wallet.
  set rootSigningKey(String? rootSigningKey) =>
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
    _hdAccount = null;
    _mnemonic = null;
  }

  /// Create a read-only wallet matching the supplied properties. Resets the builder.
  Result<ReadOnlyWallet, String> readOnlyBuild() {
    if (_stakeAddress == null) {
      return Err("Read-only wallet creation requires a staking address");
    }
    _walletName ??= "Wallet #${_walletNameIndex++}";
    if (_blockchainAdapter == null) {
      final adapterResult = _lookupOrCreateBlockchainAdapter(
        network: network,
        key: network == Networks.mainnet
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

  /// try to figure out which network is intended or use mainnet otherwise
  Networks get network {
    if (_network == null) {
      if (_hdAccount != null) {
        _network = _hdAccount!.network;
      } else if (_blockchainAdapter != null) {
        _network = _blockchainAdapter!.network;
      } else if (_testnetAdapterKey != null && _mainnetAdapterKey == null) {
        _network = Networks.testnet;
      } else if (_mainnetAdapterKey != null && _testnetAdapterKey == null) {
        _network = Networks.mainnet;
      } else if (_stakeAddress != null) {
        _network = _stakeAddress!.toBech32().startsWith('stake_test')
            ? Networks.testnet
            : Networks.mainnet;
      } else {
        _network = Networks.mainnet;
      }
    }
    return _network!;
  }

  /// Create a transactional wallet matching the supplied properties.
  /// Resets the builder.
  Result<Wallet, String> build() {
    if (_hdAccount == null) {
      if (_mnemonic != null) {
        _hdAccount = HdMaster.mnemonic(_mnemonic!, network: network)
            .account(accountIndex: accountIndex);
      } else if (_rootSigningKey != null) {
        if (_rootSigningKey!.startsWith('root_xsk')) {
          final derivation = ShelleyKeyDerivation.rootX(_rootSigningKey!);
          _hdAccount = HdMaster(derivation: derivation, network: network)
              .account(accountIndex: accountIndex);
        } else if (_rootSigningKey!.startsWith('acct_xsk')) {
          final accountSigningKey =
              Bip32SigningKey.decode(_rootSigningKey!, coder: acctXskCoder);
          _hdAccount = HdAccount(
              accountSigningKey: accountSigningKey,
              network: network,
              accountIndex: accountIndex);
        } else {
          return Err(
              "rootSigningKey must be a master (starting with 'root_xsk') or a account root (starting with 'acct_xsk') private extended key: $_rootSigningKey");
        }
      } else {
        return Err("wallet creation requires a 'rootPrivateKey' or 'mnemonic'");
      }
    }
    _walletName ??= "Wallet #${_walletNameIndex++}";
    if (_blockchainAdapter == null) {
      final adapterResult = _lookupOrCreateBlockchainAdapter(
        network: network,
        key: network == Networks.mainnet
            ? _mainnetAdapterKey
            : _testnetAdapterKey,
      );
      if (adapterResult.isErr()) return Err(adapterResult.unwrapErr());
      _blockchainAdapter = adapterResult.unwrap();
    }
    final wallet = WalletImpl(
      blockchainAdapter: _blockchainAdapter!,
      walletName: _walletName!,
      account: _hdAccount!,
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
  // static List<String> generateNewMnemonic() =>
  //     (bip39.generateNewMnemonic(strength: 256));

  static final Map<Networks, BlockchainAdapterFactory>
      _blockchainAdapterFactoryCache = {};
  static final Map<Networks, BlockchainAdapter> _blockchainAdapterCache = {};

  static Result<BlockchainAdapter, String> _lookupOrCreateBlockchainAdapter(
      {required Networks network, String? key}) {
    BlockchainAdapter? adapter = _blockchainAdapterCache[network];
    if (adapter != null) return Ok(adapter);
    BlockchainAdapterFactory? factory = _blockchainAdapterFactoryCache[network];
    if (factory == null) {
      if (key == null) {
        return Err(
            "no BlockFrost key supplied for ${network.toString()} network");
      }
      Interceptor authInterceptor =
          BlockchainAdapterFactory.interceptorFromKey(key: key);
      factory = BlockchainAdapterFactory(
          authInterceptor: authInterceptor, network: network, projectId: key);
      _blockchainAdapterFactoryCache[network] = factory;
    }
    adapter = factory.adapter();
    _blockchainAdapterCache[network] = adapter;
    return Ok(adapter);
  }
}
