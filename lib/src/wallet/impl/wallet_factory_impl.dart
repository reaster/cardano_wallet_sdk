import 'package:cardano_wallet_sdk/src/address/shelley_address.dart';
import 'package:cardano_wallet_sdk/src/blockchain/blockchain_adapter_factory.dart';
import 'package:cardano_wallet_sdk/src/network/network_id.dart';
import 'package:blockfrost/blockfrost.dart';
import 'package:cardano_wallet_sdk/src/blockchain/blockfrost/blockfrost_api_key_auth.dart';
import 'package:cardano_wallet_sdk/src/blockchain/blockchain_adapter.dart';
import 'package:cardano_wallet_sdk/src/blockchain/blockfrost/blockfrost_blockchain_adapter.dart';
import 'package:cardano_wallet_sdk/src/wallet/impl/read_only_wallet_impl.dart';
import 'package:cardano_wallet_sdk/src/wallet/read_only_wallet.dart';
import 'package:cardano_wallet_sdk/src/wallet/wallet_factory.dart';
import 'package:dio/dio.dart';
import 'package:oxidized/oxidized.dart';

///
/// Shelley wallet factory provides various ways to create read-only or fully trasactional wallets.
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
  Future<Result<ReadOnlyWallet, String>> createReadOnlyWallet(
      {required ShelleyAddress stakeAddress, String? walletName}) async {
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
    try {
      final result = await updateWallet(wallet: wallet);
      if (result.isErr()) {
        return Err(result.unwrapErr());
      }
    } catch (e) {
      print(e);
      return Err(e.toString());
    }
    _walletCache[stakeAddress.toBech32()] = wallet;
    return Ok(wallet);
  }

  @override
  Future<Result<bool, String>> updateWallet({required ReadOnlyWalletImpl wallet}) async {
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
}
