import 'package:cardano_wallet_sdk/src/address/shelley_address.dart';
import 'package:cardano_wallet_sdk/src/network/cardano_network.dart';
import 'package:cardano_wallet_sdk/src/transaction/transaction.dart';
import 'package:cardano_wallet_sdk/src/util/ada_time.dart';
import 'package:blockfrost/blockfrost.dart';
import 'package:cardano_wallet_sdk/src/util/blockfrost_api_key_auth.dart';
import 'package:cardano_wallet_sdk/src/wallet/public_wallet.dart';
import 'package:dio/dio.dart';
import 'package:built_value/json_object.dart';
import 'package:built_collection/built_collection.dart';
import 'package:oxidized/oxidized.dart';
import 'package:cardano_wallet_sdk/src/asset/asset.dart';

///
/// Creates wallets from keys.
///
/// Wallets arc cached and can be lookedup from their stakingAddress.
///
///
abstract class WalletFactory {
  ///create Cardano wallet given a stakeAddress, networkId and optional wallet name.
  Future<Result<PublicWallet, String>> createPublicWallet({required NetworkId networkId, required String stakeAddress, String? name});

  ///update existing wallet
  Future<Result<bool, String>> updatePublicWallet({required PublicWalletImpl wallet});

  ///lookup cached wallet by stakingAddress
  PublicWallet? byStakeAddress(String stakingAddress);

  ///lookup CardanoNetwork metadata given NetworkId.
  Map<NetworkId, CardanoNetwork> get networkMap;
}

///
/// generate a Shelley, read-only wallet using a stakingAddress to find the public addresses associated with this wallet.
///
class ShelleyWalletFactory implements WalletFactory {
  final Interceptor authInterceptor;
  Map<String, PublicWalletImpl> _walletCache = {};
  Map<NetworkId, CardanoNetwork> _networkMap =
      Map.fromEntries(NetworkId.values.map((id) => CardanoNetwork.network(id)).map((n) => MapEntry(n.networkId, n)));
  Map<NetworkId, Blockfrost> _blockfrostCache = {};
  Map<NetworkId, BlockfrostWalletAdapter> _adapterCache = {};
  int _walletIndex = 0;

  ShelleyWalletFactory({required this.authInterceptor});

  factory ShelleyWalletFactory.fromKey({required String key}) =>
      ShelleyWalletFactory(authInterceptor: BlockfrostApiKeyAuthInterceptor(projectId: key));

  @override
  Future<Result<PublicWallet, String>> createPublicWallet(
      {required NetworkId networkId, required String stakeAddress, String? name}) async {
    PublicWalletImpl? wallet = _walletCache[stakeAddress];
    if (wallet != null) {
      return Err("wallet already exists: '${wallet.name}'");
    }
    final String walletName = name ?? "Wallet #${++_walletIndex}";
    wallet = PublicWalletImpl(networkId: networkId, stakingAddress: stakeAddress, name: walletName);
    final result = await updatePublicWallet(wallet: wallet);
    if (result.isErr()) {
      return Err(result.unwrapErr());
    }
    _walletCache[stakeAddress] = wallet;
    return Ok(wallet);
  }

  @override
  Future<Result<bool, String>> updatePublicWallet({required PublicWalletImpl wallet}) async {
    bool changed = false;
    final adapter = _adapter(wallet.networkId);
    final result = await adapter.updatePublicWallet(stakingAddress: wallet.stakingAddress);
    result.when(
      ok: (update) {
        changed = wallet.refresh(
            balance: update.balance, transactions: update.transactions, usedAddresses: update.addresses, assets: update.assets);
      },
      err: (err) => Err(result.unwrapErr()),
    );
    return Ok(changed);
  }

  @override
  PublicWallet? byStakeAddress(String stakingAddress) => _walletCache[stakingAddress];

  WalletServiceAdapter _adapter(NetworkId networkId) {
    BlockfrostWalletAdapter? adapter = _adapterCache[networkId];
    if (adapter == null) {
      adapter = BlockfrostWalletAdapter(networkId: networkId, cardanoNetwork: _networkMap[networkId]!, blockfrost: _blockfrost(networkId));
      _adapterCache[networkId] = adapter;
    }
    return adapter;
  }

  Blockfrost _blockfrost(NetworkId networkId) {
    Blockfrost? blockfrost = _blockfrostCache[networkId];
    if (blockfrost == null) {
      blockfrost = Blockfrost(
        basePathOverride: _networkMap[networkId]!.blockfrostUrl,
        interceptors: [authInterceptor],
      );
      _blockfrostCache[networkId] = blockfrost;
    }
    return blockfrost;
  }

  @override
  Map<NetworkId, CardanoNetwork> get networkMap => _networkMap;
}

///
/// data object allowing existing or new wallet to be updated
///
class WalletUpdate {
  final int balance;
  final List<Transaction> transactions;
  final List<ShelleyAddress> addresses;
  final Map<String, CurrencyAsset> assets;
  WalletUpdate({required this.balance, required this.transactions, required this.addresses, required this.assets});
}

///
/// Binds a data API to wallet model
///
abstract class WalletServiceAdapter {
  Future<Result<WalletUpdate, String>> updatePublicWallet({required String stakingAddress});
}

///
/// Loads BlockFrost data into this wallet model
///
/// Caches transactions, blocks, acount data and assets.
///
class BlockfrostWalletAdapter implements WalletServiceAdapter {
  final NetworkId networkId;
  final CardanoNetwork cardanoNetwork;
  final Blockfrost blockfrost;
  Map<String, Transaction> _transactionCache = {};
  Map<String, Block> _blockCache = {};
  Map<String, AccountContent> _accountContentCache = {};
  Map<String, CurrencyAsset> _assetCache = {lovelaceHex: lovelacePseudoAsset};

  BlockfrostWalletAdapter({required this.networkId, required this.cardanoNetwork, required this.blockfrost});

  @override
  Future<Result<WalletUpdate, String>> updatePublicWallet(
      {required String stakingAddress, TemperalSortOrder sortOrder = TemperalSortOrder.descending}) async {
    final content = await _loadAccountContent(stakeAddress: stakingAddress);
    final controlledAmount = content.isOk() ? int.tryParse(content.unwrap().controlledAmount) ?? 0 : 0;
    final addresses = await _addresses(stakeAddress: stakingAddress);
    if (addresses.isErr()) {
      return Err(addresses.unwrapErr());
    }
    List<Transaction> transactions = [];
    Set<String> duplicateTxHashes = {}; //track and skip duplicates
    for (var address in addresses.unwrap()) {
      final trans = await _transactions(address: address.toBech32(), duplicateTxHashes: duplicateTxHashes);
      if (trans.isErr()) {
        return Err(trans.unwrapErr());
      }
      transactions.addAll(trans.unwrap());
    }
    transactions.sort((d1, d2) => sortOrder == TemperalSortOrder.descending ? d2.time.compareTo(d1.time) : d1.time.compareTo(d2.time));
    Set<String> allAssetIds = transactions.map((t) => t.assetIds).fold(<String>{}, (result, entry) => result..addAll(entry));
    //print("policyIDs: ${policyIDs.join(',')}");
    Map<String, CurrencyAsset> assets = {};
    for (var assetId in allAssetIds) {
      final asset = await _loadAsset(assetId: assetId);
      if (asset.isOk()) {
        assets[assetId] = asset.unwrap();
      }
      if (asset.isErr()) {
        return Err(asset.unwrapErr());
      }
    }
    return Ok(WalletUpdate(balance: controlledAmount, transactions: transactions, addresses: addresses.unwrap(), assets: assets));
  }

  Future<Result<List<ShelleyAddress>, String>> _addresses({
    required String stakeAddress,
    TransactionQueryType type = TransactionQueryType.used,
  }) async {
    Response<BuiltList<JsonObject>> result =
        await blockfrost.getCardanoAccountsApi().accountsStakeAddressAddressesGet(stakeAddress: stakeAddress, count: 50);
    List<ShelleyAddress> addresses = [];
    if (result.statusCode != 200 || result.data == null) {
      return Err("${result.statusCode}: ${result.statusMessage}");
    }

    result.data!.forEach((jsonObject) {
      String? address = jsonObject.isMap ? jsonObject.asMap['address'] : null;
      if (address != null) {
        final shelley = ShelleyAddress.fromBech32(address);
        addresses.add(shelley);
        print("address: $address, shelley: $shelley");
      }
    });
    return Ok(addresses);
  }

  Future<Result<List<Transaction>, String>> _transactions({
    required String address,
    //required Set<String> addressSet,
    required Set<String> duplicateTxHashes,
  }) async {
    List<String> txHashes = await _transactionsHashes(address: address);
    List<Transaction> transactions = [];
    for (var txHash in txHashes) {
      if (duplicateTxHashes.contains(txHash)) continue; //skip already processed transactions
      final result = await _loadTransaction(txHash: txHash);
      duplicateTxHashes.add(txHash);
      if (result.isOk()) {
        transactions.add(result.unwrap());
      } else {
        return Err(result.unwrapErr());
      }
    }
    return Ok(transactions);
  }

  List<TransactionIO> _buildIputs(BuiltList<TxContentUtxoInputs> list) {
    List<TransactionIO> results = [];
    for (var input in list) {
      List<TransactionAmount> amounts = [];
      for (var io in input.amount) {
        final quantity = int.tryParse(io.quantity) ?? 0;
        final unit = io.unit == 'lovelace' ? lovelaceHex : io.unit; //translate 'lovelace' to assetId representation
        amounts.add(TransactionAmount(unit: unit, quantity: quantity));
      }
      results.add(TransactionIO(address: input.address, amounts: amounts));
    }
    return results;
  }

  List<TransactionIO> _buildOutputs(BuiltList<TxContentUtxoOutputs> list) {
    List<TransactionIO> results = [];
    for (var input in list) {
      List<TransactionAmount> amounts = [];
      for (var io in input.amount) {
        final quantity = int.tryParse(io.quantity) ?? 0;
        final unit = io.unit == 'lovelace' ? lovelaceHex : io.unit; //translate 'lovelace' to assetId representation
        amounts.add(TransactionAmount(unit: unit, quantity: quantity));
      }
      results.add(TransactionIO(address: input.address, amounts: amounts));
    }
    return results;
  }

  Future<List<String>> _transactionsHashes({required String address}) async {
    Response<BuiltList<String>> result = await blockfrost.getCardanoAddressesApi().addressesAddressTxsGet(address: address);
    final isData = result.statusCode == 200 && result.data != null && result.data!.isNotEmpty;
    final List<String> list = isData ? result.data!.map((tx) => tx).toList() : [];
    print("blockfrost.getCardanoAddressesApi().addressesAddressTxsGet(address:$address) -> ${list.join(',')}");
    return list;
  }

  Future<Result<Transaction, String>> _loadTransaction({required String txHash}) async {
    final cachedTx = _transactionCache[txHash];
    if (cachedTx != null) {
      return Ok(cachedTx);
    }
    Response<TxContent> txContent = await blockfrost.getCardanoTransactionsApi().txsHashGet(hash: txHash);
    if (txContent.statusCode != 200 || txContent.data == null) {
      return Err("${txContent.statusCode}: ${txContent.statusMessage}");
    }
    print(
        "blockfrost.getCardanoTransactionsApi().txsHashGet(hash:$txHash) -> ${serializers.toJson(TxContent.serializer, txContent.data!)}");
    final block = await _loadBlock(hashOrNumber: txContent.data!.block);
    if (block.isErr()) {
      return Err(block.unwrapErr());
    }

    Response<TxContentUtxo> txUtxo = await blockfrost.getCardanoTransactionsApi().txsHashUtxosGet(hash: txHash);
    if (txUtxo.statusCode != 200 || txUtxo.data == null) {
      return Err("${txUtxo.statusCode}: ${txUtxo.statusMessage}");
    }
    print(
        "blockfrost.getCardanoTransactionsApi().txsHashUtxosGet(hash:$txHash) -> ${serializers.toJson(TxContentUtxo.serializer, txUtxo.data!)}");
    final time = block.unwrap().time;
    //final deposit = int.tryParse(txContent.data?.deposit ?? '0') ?? 0;
    final fees = int.tryParse(txContent.data?.fees ?? '0') ?? 0;
    //final withdrawalCount = txContent.data!.withdrawalCount;
    final addrInputs = txUtxo.data!.inputs;
    List<TransactionIO> inputs = _buildIputs(addrInputs);
    final addrOutputs = txUtxo.data!.outputs;
    List<TransactionIO> outputs = _buildOutputs(addrOutputs);
    //print("deposit: $deposit, fees: $fees, withdrawalCount: $withdrawalCount inputs: ${inputs.length}, outputs: ${outputs.length}");
    //BuiltList<TxContentOutputAmount> amounts = txContent.data!.outputAmount;
    //Map<String, int> currencies = _currencyNets(inputs: inputs, outputs: outputs, addressSet: addressSet);
    //int lovelace = currencies[lovelaceHex] ?? 0;
    final trans = TransactionImpl(
      txId: txHash,
      status: TransactionStatus.confirmed,
      //type: lovelace >= 0 ? TransactionType.deposit : TransactionType.withdrawal,
      fees: fees,
      inputs: inputs,
      outputs: outputs,
      //currencies: currencies,
      time: time,
    );
    _transactionCache[txHash] = trans;
    return Ok(trans);
  }

  Future<Result<CurrencyAsset, String>> _loadAsset({required String assetId}) async {
    final cachedAsset = _assetCache[assetId];
    if (cachedAsset != null) {
      return Ok(cachedAsset);
    }
    try {
      final result = await blockfrost.getCardanoAssetsApi().assetsAssetGet(asset: assetId);
      if (result.statusCode != 200 || result.data == null) {
        return Err("${result.statusCode}: ${result.statusMessage}");
      }
      final Asset a = result.data!;
      print("blockfrost.getCardanoAssetsApi().assetsAssetGet(asset: $assetId) -> ${serializers.toJson(Asset.serializer, a)}");
      final AssetMetadata? m = a.metadata;
      final metadata = m == null
          ? null
          : CurrencyAssetMetadata(
              name: m.name, description: m.description, ticker: m.ticker, url: m.url, logo: m.logo, decimals: m.decimals ?? 0);
      final asset = CurrencyAsset(
          policyId: a.policyId,
          assetName: a.assetName ?? '',
          fingerprint: a.fingerprint,
          quantity: a.quantity,
          initialMintTxHash: a.initialMintTxHash,
          metadata: metadata);
      _assetCache[assetId] = asset;
      return Ok(asset);
    } catch (e) {
      print("assetsAssetGet(asset:$assetId) -> ${e.toString()}");
      return Err(e.toString());
    }
  }

  Future<Result<AccountContent, String>> _loadAccountContent({required String stakeAddress}) async {
    final cachedAccountContent = _accountContentCache[stakeAddress];
    if (cachedAccountContent != null) {
      return Ok(cachedAccountContent);
    }
    final result = await blockfrost.getCardanoAccountsApi().accountsStakeAddressGet(stakeAddress: stakeAddress);
    if (result.statusCode != 200 || result.data == null) {
      return Err("${result.statusCode}: ${result.statusMessage}");
    }
    _accountContentCache[stakeAddress] = result.data!;
    print(
        "blockfrost.getCardanoAccountsApi().accountsStakeAddressGet(stakeAddress:) -> ${serializers.toJson(AccountContent.serializer, result.data!)}");
    return Ok(result.data!);
  }

  Future<Result<Block, String>> _loadBlock({required String hashOrNumber}) async {
    final cachedBlock = _blockCache[hashOrNumber];
    if (cachedBlock != null) {
      return Ok(cachedBlock);
    }
    Response<BlockContent> result = await blockfrost.getCardanoBlocksApi().blocksHashOrNumberGet(hashOrNumber: hashOrNumber);
    final isData = result.statusCode == 200 && result.data != null;
    if (isData) {
      print(
          "blockfrost.getCardanoBlocksApi().blocksHashOrNumberGet(hashOrNumber: $hashOrNumber) -> ${serializers.toJson(BlockContent.serializer, result.data!)}");
      final block = Block(hash: result.data!.hash, height: result.data!.height, time: adaDateTime.encode(result.data!.time));
      _blockCache[hashOrNumber] = block;
      return Ok(block);
    }
    return Err("${result.statusCode}: ${result.statusMessage}");
  }

  void clearCaches() {
    _transactionCache.clear();
    _blockCache.clear();
    _accountContentCache.clear();
  }
}

// void main() async {
//   final wallet1 = 'stake_test1uqnf58xmqyqvxf93d3d92kav53d0zgyc6zlt927zpqy2v9cyvwl7a';
//   final walletFactory = ShelleyWalletFactory(networkId: NetworkId.testnet, authInterceptor: MyApiKeyAuthInterceptor());
//   final testnetWallet = await walletFactory.create(stakeAddress: wallet1);
//   for (var addr in testnetWallet.addresses()) {
//     print(addr.toBech32());
//   }
// }
