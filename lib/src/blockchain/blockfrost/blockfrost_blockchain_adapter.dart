// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/src/address/shelley_address.dart';
import 'package:cardano_wallet_sdk/src/network/network_id.dart';
import 'package:cardano_wallet_sdk/src/stake/stake_account.dart';
import 'package:cardano_wallet_sdk/src/stake/stake_pool.dart';
import 'package:cardano_wallet_sdk/src/stake/stake_pool_metadata.dart';
import 'package:cardano_wallet_sdk/src/transaction/transaction.dart';
import 'package:cardano_wallet_sdk/src/util/ada_time.dart';
import 'package:cardano_wallet_sdk/src/asset/asset.dart';
import 'package:cardano_wallet_sdk/src/blockchain/blockfrost/dio_call.dart';
import 'package:cardano_wallet_sdk/src/blockchain/blockchain_adapter.dart';
import 'package:cardano_wallet_sdk/src/util/ada_types.dart';
import 'package:cardano_wallet_sdk/src/wallet/impl/wallet_update.dart';
import 'package:cardano_wallet_sdk/src/wallet/read_only_wallet.dart';
import 'package:blockfrost/blockfrost.dart';
import 'package:dio/dio.dart';
import 'package:built_value/json_object.dart';
import 'package:built_collection/built_collection.dart';
import 'package:oxidized/oxidized.dart';

///
/// Loads BlockFrost data into this wallet model
///
/// Caches transactions, blocks, acount data and assets.
///
class BlockfrostBlockchainAdapter implements BlockchainAdapter {
  static const mainnetUrl = 'https://cardano-mainnet.blockfrost.io/api/v0';
  static const testnetUrl = 'https://cardano-testnet.blockfrost.io/api/v0';

  static const txContentType = 'application/cbor';

  /// return base URL for blockfrost service given the network type.
  static String urlFromNetwork(NetworkId networkId) => networkId == NetworkId.mainnet ? mainnetUrl : testnetUrl;

  final NetworkId networkId;
  //final CardanoNetwork cardanoNetwork;
  final Blockfrost blockfrost;
  Map<String, RawTransaction> _transactionCache = {};
  Map<String, Block> _blockCache = {};
  Map<String, AccountContent> _accountContentCache = {};
  Map<String, CurrencyAsset> _assetCache = {lovelaceHex: lovelacePseudoAsset};

  BlockfrostBlockchainAdapter({required this.networkId, required this.blockfrost});

  @override
  Future<Result<Block, String>> latestBlock() async {
    final blockResult = await dioCall<BlockContent>(
      request: () => blockfrost.getCardanoBlocksApi().blocksLatestGet(),
      onSuccess: (data) => print(
          "blockfrost.getCardanoBlocksApi().blocksLatestGet() -> ${serializers.toJson(BlockContent.serializer, data)}"),
      errorSubject: 'latest block',
    );
    if (blockResult.isErr()) return Err(blockResult.unwrapErr());
    final b = blockResult.unwrap();
    var dateTime = DateTime.fromMillisecondsSinceEpoch(b.time * 1000, isUtc: true);
    final block =
        Block(time: dateTime, hash: b.hash, slot: b.slot ?? 0, epoch: b.epoch ?? 0, epochSlot: b.epochSlot ?? 0);
    return Ok(block);
  }

  Future<Result<String, String>> submitTransaction(List<int> cborTransaction) async {
    final result = await dioCall<String>(
      request: () =>
          blockfrost.getCardanoTransactionsApi().txSubmitPost(contentType: txContentType, data: cborTransaction),
      onSuccess: (data) =>
          print("blockfrost.getCardanoTransactionsApi().txSubmitPost(contentType: 'application/cbor'); -> ${data}"),
      errorSubject: 'submit cbor transaction: ',
    );
    if (result.isErr()) return Err(result.unwrapErr());
    return Ok(result.unwrap());
  }

  @override
  Future<Result<WalletUpdate, String>> updateWallet({
    required ShelleyAddress stakeAddress,
    TemperalSortOrder sortOrder = TemperalSortOrder.descending,
  }) async {
    final content = await _loadAccountContent(stakeAddress: stakeAddress.toBech32());
    if (content.isErr()) {
      return Err(content.unwrapErr());
    }
    final account = content.unwrap();
    final controlledAmount = content.isOk() ? int.tryParse(content.unwrap().controlledAmount) ?? 0 : 0;
    final addressesResult = await _addresses(stakeAddress: stakeAddress.toBech32());
    if (addressesResult.isErr()) {
      return Err(addressesResult.unwrapErr());
    }
    final addresses = addressesResult.unwrap();
    List<StakeAccount> stakeAccounts = []; //TODO should be a list, just show current staked pool for now
    if (account.poolId != null && account.active) {
      final stakeAccountResponse = await _stakeAccount(poolId: account.poolId!, stakeAddress: stakeAddress.toBech32());
      if (stakeAccountResponse.isErr()) {
        return Err(stakeAccountResponse.unwrapErr());
      }
      stakeAccounts = stakeAccountResponse.unwrap();
    }
    List<RawTransactionImpl> transactionList = [];
    Set<String> duplicateTxHashes = {}; //track and skip duplicates
    //final Set<String> addressSet = addresses.map((a) => a.toBech32()).toSet();
    for (var address in addresses) {
      final trans = await _transactions(address: address.toBech32(), duplicateTxHashes: duplicateTxHashes);
      if (trans.isErr()) {
        return Err(trans.unwrapErr());
      }
      trans.unwrap().forEach((tx) {
        transactionList.add(tx as RawTransactionImpl);
      });
    }
    //set transaction status
    transactionList = markSpentTransactions(transactionList);

    //sort
    transactionList.sort((d1, d2) =>
        sortOrder == TemperalSortOrder.descending ? d2.time.compareTo(d1.time) : d1.time.compareTo(d2.time));
    Set<String> allAssetIds =
        transactionList.map((t) => t.assetIds).fold(<String>{}, (result, entry) => result..addAll(entry));
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
    return Ok(WalletUpdate(
        balance: controlledAmount,
        transactions: transactionList,
        addresses: addresses,
        assets: assets,
        stakeAccounts: stakeAccounts));
  }

  List<RawTransactionImpl> markSpentTransactions(List<RawTransactionImpl> transactions) {
    final Set<String> txIdSet = transactions.map((tx) => tx.txId).toSet();
    Set<String> spentTransactinos = {};
    for (final tx in transactions) {
      for (final input in tx.inputs) {
        if (txIdSet.contains(input.txHash)) {
          spentTransactinos.add(input.txHash);
        }
      }
    }
    return transactions
        .map((tx) => spentTransactinos.contains(tx.txId) ? tx.toStatus(TransactionStatus.spent) : tx)
        .toList();
  }

  // bool _isSpent(RawTransaction tx, Map<String, RawTransaction> txIdLookup) =>
  //     tx.inputs.any((input) => txIdLookup.containsKey(input.txHash));

  // bool _isSpent2(RawTransaction tx, Map<String, RawTransaction> txIdLookup) {
  //   for (final input in tx.inputs) {
  //     if (txIdLookup.containsKey(input.txHash)) {
  //       return true;
  //     }
  //   }
  //   return false;
  // }

  Future<Result<List<StakeAccount>, String>> _stakeAccount(
      {required String poolId, required String stakeAddress}) async {
    StakePool stakePool;
    final Response<Pool> poolResponse = await blockfrost.getCardanoPoolsApi().poolsPoolIdGet(poolId: poolId);
    if (poolResponse.statusCode == 200 && poolResponse.data != null) {
      final p = poolResponse.data!;
      stakePool = StakePool(
        activeSize: p.activeSize,
        vrfKey: p.vrfKey,
        blocksMinted: p.blocksMinted,
        declaredPledge: p.declaredPledge,
        liveDelegators: p.liveDelegators,
        livePledge: p.livePledge,
        liveSize: p.liveSize,
        liveSaturation: p.liveSaturation,
        liveStake: p.liveStake,
        rewardAccount: p.rewardAccount,
        fixedCost: p.fixedCost,
        marginCost: p.marginCost,
        activeStake: p.activeStake,
        retirement: p.retirement.map((e) => e).toList(),
        owners: p.owners.map((e) => e).toList(),
        registration: p.registration.map((e) => e).toList(),
      );
    } else {
      return poolResponse.statusMessage != null
          ? Err("${poolResponse.statusMessage}, code: ${poolResponse.statusCode}")
          : Err('problem loading stake pool: ${poolId}');
    }
    StakePoolMetadata stakePoolMetadata;
    final Response<AnyOfpoolMetadataobject> metadataResponse =
        await blockfrost.getCardanoPoolsApi().poolsPoolIdMetadataGet(poolId: poolId); //TODO replace with dioCall
    if (metadataResponse.statusCode == 200 && metadataResponse.data != null) {
      final m = metadataResponse.data!;
      stakePoolMetadata = StakePoolMetadata(
        name: m.name,
        hash: m.hash,
        url: m.url,
        ticker: m.ticker,
        description: m.description,
        homepage: m.homepage,
      );
    } else {
      return metadataResponse.statusMessage != null
          ? Err("${metadataResponse.statusMessage}, code: ${metadataResponse.statusCode}")
          : Err('problem loading stake pool metadata: ${poolId}');
    }
    List<StakeReward> rewards = [];
    final Response<BuiltList<JsonObject>> rewardResponse = await blockfrost
        .getCardanoAccountsApi()
        .accountsStakeAddressRewardsGet(stakeAddress: stakeAddress, count: 100); //TODO replace with dioCall
    if (rewardResponse.statusCode == 200 && rewardResponse.data != null) {
      rewardResponse.data!.forEach((reward) {
        if (reward.isMap) {
          final map = reward.asMap;
          rewards.add(
              StakeReward(epoch: map['epoch'], amount: int.tryParse(map['amount']) ?? 0, poolId: map['pool_id'] ?? ''));
          print("amount: ${map['amount']}, epoch: ${map['epoch']}, pool_id: ${map['pool_id']}");
        }
      });
    } else {
      return rewardResponse.statusMessage != null
          ? Err("${rewardResponse.statusMessage}, code: ${rewardResponse.statusCode}")
          : Err('problem loading staking rewards: ${stakeAddress}');
    }
    StakeAccount stakeAccount;
    final Response<AccountContent> accountResponse = await blockfrost
        .getCardanoAccountsApi()
        .accountsStakeAddressGet(stakeAddress: stakeAddress); //TODO replace with dioCall
    if (accountResponse.statusCode == 200 && accountResponse.data != null) {
      final a = accountResponse.data!;
      stakeAccount = StakeAccount(
        active: a.active,
        activeEpoch: a.activeEpoch,
        controlledAmount: int.tryParse(a.controlledAmount) ?? 0,
        reservesSum: int.tryParse(a.reservesSum) ?? 0,
        withdrawableAmount: int.tryParse(a.withdrawableAmount) ?? 0,
        rewardsSum: int.tryParse(a.reservesSum) ?? 0,
        treasurySum: int.tryParse(a.treasurySum) ?? 0,
        poolId: a.poolId,
        withdrawalsSum: int.tryParse(a.withdrawableAmount) ?? 0,
        stakePool: stakePool,
        poolMetadata: stakePoolMetadata,
        rewards: rewards,
      );
    } else {
      return accountResponse.statusMessage != null
          ? Err("${accountResponse.statusMessage}, code: ${accountResponse.statusCode}")
          : Err('problem loading staking account: ${stakeAddress}');
    }
    return Ok([stakeAccount]);
  }

  Future<Result<List<ShelleyAddress>, String>> _addresses({
    required String stakeAddress,
    TransactionQueryType type = TransactionQueryType.used,
  }) async {
    Response<BuiltList<JsonObject>> result = await blockfrost
        .getCardanoAccountsApi()
        .accountsStakeAddressAddressesGet(stakeAddress: stakeAddress, count: 50);
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

  Future<Result<List<RawTransaction>, String>> _transactions({
    required String address,
    //required Set<String> addressSet,
    required Set<String> duplicateTxHashes,
  }) async {
    List<String> txHashes = await _transactionsHashes(address: address);
    List<RawTransaction> transactions = [];
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

  List<TransactionInput> _buildIputs(BuiltList<TxContentUtxoInputs> list) {
    List<TransactionInput> results = [];
    for (var input in list) {
      List<TransactionAmount> amounts = [];
      for (var io in input.amount) {
        final quantity = int.tryParse(io.quantity) ?? 0;
        final unit = io.unit == 'lovelace' ? lovelaceHex : io.unit; //translate 'lovelace' to assetId representation
        amounts.add(TransactionAmount(unit: unit, quantity: quantity));
      }
      results.add(TransactionInput(
        address: ShelleyAddress.fromBech32(input.address),
        amounts: amounts,
        txHash: input.txHash,
        outputIndex: input.outputIndex,
      ));
    }
    return results;
  }

  List<TransactionOutput> _buildOutputs(BuiltList<TxContentUtxoOutputs> list) {
    List<TransactionOutput> results = [];
    for (var input in list) {
      List<TransactionAmount> amounts = [];
      for (var io in input.amount) {
        final quantity = int.tryParse(io.quantity) ?? 0;
        final unit = io.unit == 'lovelace' ? lovelaceHex : io.unit; //translate 'lovelace' to assetId representation
        amounts.add(TransactionAmount(unit: unit, quantity: quantity));
      }
      results.add(TransactionOutput(
        address: ShelleyAddress.fromBech32(input.address),
        amounts: amounts,
      ));
    }
    return results;
  }

  Future<List<String>> _transactionsHashes({required String address}) async {
    Response<BuiltList<String>> result =
        await blockfrost.getCardanoAddressesApi().addressesAddressTxsGet(address: address); //TODO replace with dioCall
    final isData = result.statusCode == 200 && result.data != null && result.data!.isNotEmpty;
    final List<String> list = isData ? result.data!.map((tx) => tx).toList() : [];
    print("blockfrost.getCardanoAddressesApi().addressesAddressTxsGet(address:$address) -> ${list.join(',')}");
    return list;
  }

  Future<Result<RawTransaction, String>> _loadTransaction({required String txHash}) async {
    final cachedTx = _transactionCache[txHash];
    if (cachedTx != null) {
      return Ok(cachedTx);
    }
    final txContentResult = await dioCall<TxContent>(
      request: () => blockfrost.getCardanoTransactionsApi().txsHashGet(hash: txHash),
      onSuccess: (data) => print(
          "blockfrost.getCardanoTransactionsApi().txsHashGet(hash:$txHash) -> ${serializers.toJson(TxContent.serializer, data)}"),
      errorSubject: 'transaction content',
    );
    if (txContentResult.isErr()) return Err(txContentResult.unwrapErr());
    final txContent = txContentResult.unwrap();
    // Response<TxContent> txContent = await blockfrost.getCardanoTransactionsApi().txsHashGet(hash: txHash);
    // if (txContent.statusCode != 200 || txContent.data == null) {
    //   return Err("${txContent.statusCode}: ${txContent.statusMessage}");
    // }
    // print(
    //     "blockfrost.getCardanoTransactionsApi().txsHashGet(hash:$txHash) -> ${serializers.toJson(TxContent.serializer, txContent.data!)}");
    final block = await _loadBlock(hashOrNumber: txContent.block);
    if (block.isErr()) {
      return Err(block.unwrapErr());
    }
    final txContentUtxoResult = await dioCall<TxContentUtxo>(
      request: () => blockfrost.getCardanoTransactionsApi().txsHashUtxosGet(hash: txHash),
      onSuccess: (data) => print(
          "blockfrost.getCardanoTransactionsApi().txsHashUtxosGet(hash:$txHash) -> ${serializers.toJson(TxContentUtxo.serializer, data)}"),
      errorSubject: 'UTXO',
    );
    if (txContentUtxoResult.isErr()) return Err(txContentUtxoResult.unwrapErr());

    // Response<TxContentUtxo> txUtxo = await blockfrost.getCardanoTransactionsApi().txsHashUtxosGet(hash: txHash);
    // if (txUtxo.statusCode != 200 || txUtxo.data == null) {
    //   return Err("${txUtxo.statusCode}: ${txUtxo.statusMessage}");
    // }
    // print(
    //     "blockfrost.getCardanoTransactionsApi().txsHashUtxosGet(hash:$txHash) -> ${serializers.toJson(TxContentUtxo.serializer, txUtxo.data!)}");
    final time = block.unwrap().time;
    //final deposit = int.tryParse(txContent.data?.deposit ?? '0') ?? 0;
    final fees = int.tryParse(txContentResult.unwrap().fees) ?? 0;
    //final withdrawalCount = txContent.data!.withdrawalCount;
    final addrInputs = txContentUtxoResult.unwrap().inputs;
    List<TransactionInput> inputs = _buildIputs(addrInputs);
    final addrOutputs = txContentUtxoResult.unwrap().outputs;
    List<TransactionOutput> outputs = _buildOutputs(addrOutputs);
    //print("deposit: $deposit, fees: $fees, withdrawalCount: $withdrawalCount inputs: ${inputs.length}, outputs: ${outputs.length}");
    //BuiltList<TxContentOutputAmount> amounts = txContent.data!.outputAmount;
    //Map<String, int> currencies = _currencyNets(inputs: inputs, outputs: outputs, addressSet: addressSet);
    //int lovelace = currencies[lovelaceHex] ?? 0;
    final trans = RawTransactionImpl(
      txId: txHash,
      blockHash: txContent.block,
      blockIndex: txContent.index,
      status: TransactionStatus.unspent,
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
      final result = await blockfrost.getCardanoAssetsApi().assetsAssetGet(asset: assetId); //TODO replace with dioCall
      if (result.statusCode != 200 || result.data == null) {
        return Err("${result.statusCode}: ${result.statusMessage}");
      }
      final Asset a = result.data!;
      print(
          "blockfrost.getCardanoAssetsApi().assetsAssetGet(asset: $assetId) -> ${serializers.toJson(Asset.serializer, a)}");
      final AssetMetadata? m = a.metadata;
      final metadata = m == null
          ? null
          : CurrencyAssetMetadata(
              name: m.name,
              description: m.description,
              ticker: m.ticker,
              url: m.url,
              logo: m.logo,
              decimals: m.decimals ?? 0);
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

  // Future<Result<AccountContent, String>> _loadAccountContent({required String stakeAddress}) async {
  //   final cachedAccountContent = _accountContentCache[stakeAddress];
  //   if (cachedAccountContent != null) {
  //     return Ok(cachedAccountContent);
  //   }
  //   try {
  //     final result = await blockfrost.getCardanoAccountsApi().accountsStakeAddressGet(stakeAddress: stakeAddress);
  //     if (result.statusCode != 200 || result.data == null) {
  //       return Err("${result.statusCode}: ${result.statusMessage}");
  //     }
  //     _accountContentCache[stakeAddress] = result.data!;
  //     print(
  //         "blockfrost.getCardanoAccountsApi().accountsStakeAddressGet(stakeAddress:) -> ${serializers.toJson(AccountContent.serializer, result.data!)}");
  //     return Ok(result.data!);
  //   } on DioError catch (dioError) {
  //     return Err(translateErrorMessage(dioError: dioError, subject: 'address'));
  //   } catch (e) {
  //     return Err("error loading wallet: '${e.toString}'");
  //   }
  // }

  Future<Result<AccountContent, String>> _loadAccountContent({required String stakeAddress}) async {
    final cachedAccountContent = _accountContentCache[stakeAddress];
    if (cachedAccountContent != null) {
      return Ok(cachedAccountContent);
    }
    return dioCall<AccountContent>(
      request: () => blockfrost.getCardanoAccountsApi().accountsStakeAddressGet(stakeAddress: stakeAddress),
      onSuccess: (data) {
        _accountContentCache[stakeAddress] = data;
        print(
            "blockfrost.getCardanoAccountsApi().accountsStakeAddressGet(stakeAddress:) -> ${serializers.toJson(AccountContent.serializer, data)}");
      },
      errorSubject: 'address',
    );
  }

  Future<Result<Block, String>> _loadBlock({required String hashOrNumber}) async {
    final cachedBlock = _blockCache[hashOrNumber];
    if (cachedBlock != null) {
      return Ok(cachedBlock);
    }
    Response<BlockContent> result = await blockfrost
        .getCardanoBlocksApi()
        .blocksHashOrNumberGet(hashOrNumber: hashOrNumber); //TODO replace with dioCall
    final isData = result.statusCode == 200 && result.data != null;
    if (isData) {
      final b = result.data!;
      print(
          "blockfrost.getCardanoBlocksApi().blocksHashOrNumberGet(hashOrNumber: $hashOrNumber) -> ${serializers.toJson(BlockContent.serializer, b)}");
      final block = Block(
          hash: b.hash,
          height: b.height,
          time: adaDateTime.encode(b.time),
          slot: b.slot ?? 0,
          epoch: b.epoch ?? 0,
          epochSlot: b.epochSlot ?? 0);
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

  ///BlockchainCache
  @override
  AccountContent? cachedAccountContent(Bech32Address stakeAddress) => _accountContentCache[stakeAddress];

  ///BlockchainCache
  @override
  Block? cachedBlock(BlockHashHex blockId) => _blockCache[blockId];

  ///BlockchainCache
  @override
  CurrencyAsset? cachedCurrencyAsset(String assetId) => _assetCache[assetId];

  ///BlockchainCache
  @override
  RawTransaction? cachedTransaction(TxIdHex txId) => _transactionCache[txId];
}


// void main() async {
//   final wallet1 = 'stake_test1uqnf58xmqyqvxf93d3d92kav53d0zgyc6zlt927zpqy2v9cyvwl7a';
//   final walletFactory = ShelleyWalletFactory(networkId: NetworkId.testnet, authInterceptor: MyApiKeyAuthInterceptor());
//   final testnetWallet = await walletFactory.create(stakeAddress: wallet1);
//   for (var addr in testnetWallet.addresses()) {
//     print(addr.toBech32());
//   }
// }
