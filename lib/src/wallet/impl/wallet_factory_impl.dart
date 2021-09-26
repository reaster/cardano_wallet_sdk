import 'package:cardano_wallet_sdk/src/address/shelley_address.dart';
import 'package:cardano_wallet_sdk/src/network/cardano_network.dart';
import 'package:blockfrost/blockfrost.dart';
import 'package:cardano_wallet_sdk/src/util/blockfrost_api_key_auth.dart';
import 'package:cardano_wallet_sdk/src/wallet/impl/blockfrost_wallet_adapter.dart';
import 'package:cardano_wallet_sdk/src/wallet/impl/read_only_wallet_impl.dart';
import 'package:cardano_wallet_sdk/src/wallet/read_only_wallet.dart';
import 'package:cardano_wallet_sdk/src/wallet/wallet_factory.dart';
import 'package:dio/dio.dart';
import 'package:oxidized/oxidized.dart';

///
/// generate a Shelley, read-only wallet using a stakingAddress to find the public addresses associated with this wallet.
///
class ShelleyWalletFactory implements WalletFactory {
  final Interceptor authInterceptor;
  Map<String, ReadOnlyWalletImpl> _walletCache = {};
  Map<NetworkId, CardanoNetwork> _networkMap =
      Map.fromEntries(NetworkId.values.map((id) => CardanoNetwork.network(id)).map((n) => MapEntry(n.networkId, n)));
  Map<NetworkId, Blockfrost> _blockfrostCache = {};
  Map<NetworkId, BlockfrostWalletAdapter> _adapterCache = {};
  int _walletIndex = 0;

  ShelleyWalletFactory({required this.authInterceptor});

  factory ShelleyWalletFactory.fromKey({required String key}) =>
      ShelleyWalletFactory(authInterceptor: BlockfrostApiKeyAuthInterceptor(projectId: key));

  @override
  Future<Result<ReadOnlyWallet, String>> createReadOnlyWallet(
      {required ShelleyAddress stakeAddress, String? walletName}) async {
    ReadOnlyWalletImpl? wallet = _walletCache[stakeAddress];
    if (wallet != null) {
      return Err("wallet already exists: '${wallet.walletName}'");
    }
    final String name = walletName ?? "Wallet #${++_walletIndex}";
    wallet = ReadOnlyWalletImpl(stakeAddress: stakeAddress, walletName: name);
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
    final adapter = _adapter(wallet.networkId);
    final result = await adapter.updateWallet(stakeAddress: wallet.stakeAddress);
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

  WalletServiceAdapter _adapter(NetworkId networkId) {
    BlockfrostWalletAdapter? adapter = _adapterCache[networkId];
    if (adapter == null) {
      adapter = BlockfrostWalletAdapter(
          networkId: networkId, cardanoNetwork: _networkMap[networkId]!, blockfrost: _blockfrost(networkId));
      _adapterCache[networkId] = adapter;
    }
    return adapter;
  }

  Blockfrost _blockfrost(NetworkId networkId) {
    Blockfrost? blockfrost = _blockfrostCache[networkId];
    if (blockfrost == null) {
      final url = _networkMap[networkId]!.blockfrostUrl;
      print("new Blockfrost($url)");
      blockfrost = Blockfrost(
        basePathOverride: url,
        interceptors: [authInterceptor],
      );
      _blockfrostCache[networkId] = blockfrost;
    }
    return blockfrost;
  }

  @override
  Map<NetworkId, CardanoNetwork> get networkMap => _networkMap;
}
