import 'package:bip32_ed25519/src/bip32_ed25519/ed25519_bip32.dart';
import 'package:cardano_wallet_sdk/src/address/hd_wallet.dart';
import 'package:cardano_wallet_sdk/src/address/shelley_address.dart';
import 'package:cardano_wallet_sdk/src/blockchain/blockchain_adapter_factory.dart';
import 'package:cardano_wallet_sdk/src/network/network_id.dart';
import 'package:cardano_wallet_sdk/src/wallet/impl/read_only_wallet_impl.dart';
import 'package:cardano_wallet_sdk/src/wallet/impl/wallet_impl.dart';
import 'package:cardano_wallet_sdk/src/wallet/read_only_wallet.dart';
import 'package:cardano_wallet_sdk/src/wallet/wallet.dart';
import 'package:cardano_wallet_sdk/src/wallet/wallet_factory.dart';
import 'package:dio/dio.dart';
import 'package:oxidized/oxidized.dart';
import 'package:bip39/bip39.dart' as bip39;

///
/// Shelley wallet factory provides various ways to create read-only or transactional wallets.
///
class ShelleyWalletFactory extends BlockchainAdapterFactory implements WalletFactory {
  Map<String, ReadOnlyWalletImpl> _walletCache = {};
  // Map<NetworkId, CardanoNetwork> _networkMap =
  //     Map.fromEntries(NetworkId.values.map((id) => CardanoNetwork.network(id)).map((n) => MapEntry(n.networkId, n)));
  int _walletIndex = 0;

  ShelleyWalletFactory({required Interceptor authInterceptor, required NetworkId networkId})
      : super(authInterceptor: authInterceptor, networkId: networkId);

  /// creates an factory given a authorization key
  factory ShelleyWalletFactory.fromKey({required String key, required NetworkId networkId}) => ShelleyWalletFactory(
      authInterceptor: BlockchainAdapterFactory.interceptorFromKey(key: key), networkId: networkId);

  @override
  Future<Result<ReadOnlyWallet, String>> createReadOnlyWallet({
    required ShelleyAddress stakeAddress,
    String? walletName,
    bool load = true,
  }) async {
    ReadOnlyWalletImpl? wallet = _walletCache[stakeAddress];
    if (wallet != null) {
      return Err("wallet already exists: '${wallet.walletName}'");
    }
    final String name = walletName ?? "Wallet #${++_walletIndex}";
    wallet = ReadOnlyWalletImpl(
      blockchainAdapter: adapter(),
      stakeAddress: stakeAddress,
      walletName: name,
    );
    if (load) {
      try {
        final result = await updateWallet(wallet: wallet);
        if (result.isErr()) {
          return Err(result.unwrapErr());
        }
      } catch (e) {
        print(e);
        return Err(e.toString());
      }
    }
    _walletCache[stakeAddress.toBech32()] = wallet;
    return Ok(wallet);
  }

  @override
  Future<Result<bool, String>> updateWallet({required ReadOnlyWallet wallet}) async {
    bool changed = false;
    bool error = false;
    final blockchainAdapter = adapter();
    final result = await blockchainAdapter.updateWallet(stakeAddress: wallet.stakeAddress);
    result.when(
      ok: (update) {
        changed = wallet.refresh(
            balance: update.balance,
            transactions: update.transactions,
            usedAddresses: update.addresses,
            assets: update.assets,
            stakeAccounts: update.stakeAccounts);
      },
      err: (err) {
        error = true;
      },
    );
    return error ? Err(result.unwrapErr()) : Ok(changed);
  }

  @override
  ReadOnlyWallet? byStakeAddress(String stakeAddress) => _walletCache[stakeAddress];

  @override
  Future<Result<Wallet, String>> createWallet({
    required HdWallet hdWallet,
    String? walletName,
    bool load = true,
  }) async {
    // print("hdWallet.rootSigningKey: ${hdWallet.rootSigningKey.encode()}");
    // print("hdWallet.rootVerifyKey:  ${hdWallet.rootVerifyKey.encode()}");
    final stakeKeyPair = hdWallet.deriveAddressKeys(role: stakingRole);
    // final verifyKey = stakeKeyPair.verifyKey!;
    // print("stakeKeyPair: ${verifyKey.encode()}");
    // if (verifyKey.encode() !=
    //     'ed25519bip32_pk18qvnk9eppdf0qnl7csz5h7lwdhf4jhjhu6x8a6m7fmmgz94zu9pv5xkazdaavyeq0xv9lz7cpj3u4yz5q5p4wk3hksppsskdrkm6ucq3m3kde')
    //   return Err('verifyKey fail');
    final stakeAddress = hdWallet.toRewardAddress(spend: stakeKeyPair.verifyKey!, networkId: networkId);
    // final addr0KeyPair = hdWallet.deriveAddressKeys();
    // final stakeAddress = hdWallet.toRewardAddress(spend: addr0KeyPair.verifyKey!, networkId: networkId);
    ReadOnlyWalletImpl? wallet = _walletCache[stakeAddress];
    if (wallet != null) {
      if (wallet is WalletImpl) {
        return Err("wallet already exists: '${wallet.walletName}'");
      }
      if (walletName == null) {
        walletName = wallet.walletName;
      }
      _walletCache.remove(stakeAddress);
    }
    final String name = walletName ?? "Wallet #${++_walletIndex}";
    wallet = WalletImpl(
      blockchainAdapter: adapter(),
      stakeAddress: stakeAddress,
      walletName: name,
      hdWallet: hdWallet,
    );
    if (load) {
      try {
        final result = await updateWallet(wallet: wallet);
        if (result.isErr()) {
          return Err(result.unwrapErr());
        }
      } catch (e) {
        print(e);
        return Err(e.toString());
      }
    }
    _walletCache[stakeAddress.toBech32()] = wallet;
    return Ok(wallet);
  }

  @override
  Future<Result<Wallet, String>> createWalletFromMnemonic({
    required List<String> mnemonic,
    String? walletName,
    bool load = true,
  }) async {
    final hdWallet = HdWallet.fromMnemonic(mnemonic.join(' '));
    return createWallet(hdWallet: hdWallet, walletName: walletName, load: load);
  }

  @override
  Future<Result<Wallet, String>> createWalletFromPrivateKey({
    required Bip32SigningKey rootSigningKey,
    String? walletName,
    bool load = true,
  }) {
    final hdWallet = HdWallet(rootSigningKey: rootSigningKey);
    return createWallet(hdWallet: hdWallet, walletName: walletName, load: load);
  }

  @override
  List<String> generateNewMnemonic() => (bip39.generateMnemonic(strength: 256)).split(' ');
}
