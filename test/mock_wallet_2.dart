// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:blockfrost/blockfrost.dart';
import 'package:dio/dio.dart';
import 'package:built_value/json_object.dart';
import 'package:built_collection/built_collection.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:built_value/serializer.dart';
import 'mock_wallet_2.mocks.dart';

// wallet 2

final Serializers serializers = standardSerializers;

const stakeAddr2 =
    'stake_test1uz425a6u2me7xav82g3frk2nmxhdujtfhmf5l275dr4a5jc3urkeg';

const addr1 =
    'addr_test1qputeu63ld6c0cd526w90ry2r9upc5ac8y3zetcg85xs5l924fm4c4hnud6cw53zj8v48kdwmeykn0knf74ag68tmf9sutu8kq';
const addr2 =
    'addr_test1qrektsyevyxxqpytjwnwxvmvrj8xgzv4qsuzf57qkp432ma24fm4c4hnud6cw53zj8v48kdwmeykn0knf74ag68tmf9sk7kesv';
const addr3 =
    'addr_test1qpcdsfzewqkl3w5kxk553hts5lvw9tdjda9nzt069gqmyud24fm4c4hnud6cw53zj8v48kdwmeykn0knf74ag68tmf9s89kyst';

const tx1 = 'ffcbd47773a37289bc64b976d3a0b823594cce330c2f425437e5419437c589db';
const tx2 = '8afcf3999633a58c9ce5e22578b59ef5bb7c5dddacfbaf504ee05f5f5ad0d581';
const tx3 = '339581327a0da0b3397adf41c56fd56b4737f5afd4c9bb8c41744cc85e221538';
const tx4 = 'dd45074a89c51562cf68174e94db93d800c4cfa9e5c474f9d906a5aaf7c5b953';

const blk1 = '56f61aba101c755d7b5db12d3e9aa127ac7b0693bc02e581371571b4ebe21c1e';
const blk2 = '572543b794a8ea0de53a95b01a991e4debc2b7b3439214acac0c1ce66d7f3c46';
const blk3 = 'b2e9922268a831b4f71162498c256152abbd451fe8e4ae6c5005dd5f96841280';
const blk4 = 'dca1741ebe0f8a1ad30f3f3d22e63fef0a16634e0b822221b312f93f4811b12a';
const blk0 = 'c203a1fd6ab384c271f6197c6807315c9385161bdc2c50ac3ac67c2c19239f79';

const asset1 = '6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7';

final accountContent = Response(
    requestOptions: RequestOptions(path: ''),
    statusCode: 200,
    data: serializers.fromJson(
      AccountContent.serializer,
      '["active",false,"controlled_amount","199228617","rewards_sum","0","withdrawals_sum","0","reserves_sum","0","treasury_sum","0","withdrawable_amount","0"]',
      // '["active",true,"active_epoch",135,"controlled_amount","398515694","rewards_sum","690831","withdrawals_sum","0","reserves_sum","0","treasury_sum","0","withdrawable_amount","690831","pool_id","pool14pdhhugxlqp9vta49pyfu5e2d5s82zmtukcy9x5ylukpkekqk8l"]',
    )!);

Response<TxContent> txContent(String txId) {
  String json = '';
  switch (txId) {
    case tx1:
      json =
          '["block","$blk1","block_height",2606771,"slot",27385838,"index",2,"output_amount",[["unit","lovelace","quantity","999831199"]],"fees","168801","deposit","0","size",289,"invalid_hereafter","27392991","utxo_count",3,"withdrawal_count",0,"mir_cert_count",0,"delegation_count",0,"stake_cert_count",0,"pool_update_count",0,"pool_retire_count",0,"asset_mint_or_burn_count",0]';
      break;
    case tx2:
      json =
          '["block","$blk2","block_height",2608000,"slot",27422621,"index",1,"output_amount",[["unit","lovelace","quantity","299324796"]],"fees","168801","deposit","0","size",289,"invalid_hereafter","27429804","utxo_count",3,"withdrawal_count",0,"mir_cert_count",0,"delegation_count",0,"stake_cert_count",0,"pool_update_count",0,"pool_retire_count",0,"asset_mint_or_burn_count",0]';
      break;
    case tx3:
      json =
          '["block","$blk3","block_height",2704226,"slot",30311384,"index",1,"output_amount",[["unit","lovelace","quantity","101228617"],["unit","6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7","quantity","1"],["unit","6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7","quantity","1"]],"fees","178789","deposit","0","size",496,"invalid_hereafter","30318566","utxo_count",4,"withdrawal_count",0,"mir_cert_count",0,"delegation_count",0,"stake_cert_count",0,"pool_update_count",0,"pool_retire_count",0,"asset_mint_or_burn_count",0]';
      break;
    case tx4:
      json =
          '["block","$blk4","block_height",2704219,"slot",30311175,"index",0,"output_amount",[["unit","lovelace","quantity","4960335032"],["unit","6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7","quantity","2"],["unit","6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7","quantity","948"]],"fees","172585","deposit","0","size",365,"invalid_hereafter","30318341","utxo_count",3,"withdrawal_count",0,"mir_cert_count",0,"delegation_count",0,"stake_cert_count",0,"pool_update_count",0,"pool_retire_count",0,"asset_mint_or_burn_count",0]';
      break;
    default:
      throw Exception('unknown txId: $txId');
  }
  final content = serializers.fromJson(TxContent.serializer, json)!;
  final result = Response(
      requestOptions: RequestOptions(path: ''), statusCode: 200, data: content);
  return result;
}

Response<BlockContent> blockContent(String block) {
  String json = '';
  switch (block) {
    case blk0:
      json =
          '["time",1633610391,"height",2973207,"hash","$blk0","slot",39241175,"epoch",161,"epoch_slot",58775,"slot_leader","pool1weu4vlg9t8knma7t2j5y3w2k3vzdr9mtnynd2jhfalwn76nwh48","size",4,"tx_count",0,"output","1864160557","fees","521715","block_vrf","vrf_vk1mzhz5k03lahvx0gdlqtplkyasgzn8w2cpf8y8a8f76nzskptzzhqdqyyq3","previous_block","94242efb63fd7d49d9080600e5b1b1ac8e7970a0168b099a275b9dcd6b0b2e06","confirmations",0]';
      break;
    case blk1:
      json =
          '["time",1621755054,"height",2606771,"hash","$blk1","slot",27385838,"epoch",133,"epoch_slot",299438,"slot_leader","pool1ed6d9unxud3dx3xh0xa2c6xscxqxvn786cs5d65zp4ymxzgfmr3","size",1240,"tx_count",3,"output","1864160557","fees","521715","block_vrf","vrf_vk1c76s4nzdchtkw8kwjj26655h95qaj3zfd8q8az3dexjkdkxeg8aqh8g5q3","previous_block","bc099e7a2c1ff98d25a14505ae283b7ef0a41eab8ebd083f4e812e460596105a","next_block","0c90ebe14c8dd51bc5534dce6581ae29a44f6190e36923e0ce3e244baa300870","confirmations",147402]';
      break;
    case blk2:
      json =
          '["time",1621791837,"height",2608000,"hash","$blk2","slot",27422621,"epoch",133,"epoch_slot",336221,"slot_leader","pool18yslg3q320jex6gsmetukxvzm7a20qd90wsll9anlkrfua38flr","size",1241,"tx_count",3,"output","878727447","fees","521759","block_vrf","vrf_vk1sleujze3zraykllkafvrxggcmpts3hp6zxrpazdkdzp9g07kkehsnmy8ka","previous_block","2543d65bd017ca954a1fd5bf5f3c712e92be9903eaf743b1a3a0488ace92d7f0","next_block","fc0213330f879136967b77a56c2694810ec4cf58925e9e6cfafdd61aa53690c7","confirmations",146173]';
      break;
    case blk3:
      json =
          '["time",1624680600,"height",2704226,"hash","$blk3","slot",30311384,"epoch",140,"epoch_slot",200984,"slot_leader","pool1ek7tv04ccm5mhg04r9qz4pcxf8lfm55lax0k67unp3nksukvfuy","size",788,"tx_count",2,"output","9594204730088","fees","347590","block_vrf","vrf_vk1a3h24z97a0g3jmdcf9fwj5xmfa90gschzmsswxuy87m0y6gjl6xqv2s0c7","previous_block","fd8379e069191bbaf537331dd20058df949a9160bb7428ec2113b883ac0afa8b","next_block","58e9f81121fd12570f092e8166fd4dd74391831c3787745a35bf94644bc3eeda","confirmations",49947]';
      break;
    case blk4:
      json =
          '["time",1624680391,"height",2704219,"hash","$blk4","slot",30311175,"epoch",140,"epoch_slot",200775,"slot_leader","pool1uxws0e2d8kg2hncjc0szkwrpd0wajx0gn7unympa2myucjdm6dz","size",366,"tx_count",1,"output","4960335032","fees","172585","block_vrf","vrf_vk1mnc45cv7qxzrwv795jaxaxjaf4q42vl50dwh7r6h59f625nn9fuq6k6esc","previous_block","2fcff256944da22852f1d1de12f622826485281bb8ab47b269d28c94d2719d57","next_block","43900d07f86515c1f4519fecc12fda1da55ea71e7c3586ae7658405f70a2ed65","confirmations",49486]';
      break;
    default:
      throw Exception('unknown block: $block');
  }
  return Response(
      requestOptions: RequestOptions(path: ''),
      statusCode: 200,
      data: serializers.fromJson(BlockContent.serializer, json));
}
// final Response<BlockContent> blockContent = Response(
//     requestOptions: RequestOptions(path: ''),
//     statusCode: 200,
//     data: serializers.fromJson(BlockContent.serializer,
//         '["time",1624680391,"height",2704219,"hash","dca1741ebe0f8a1ad30f3f3d22e63fef0a16634e0b822221b312f93f4811b12a","slot",30311175,"epoch",140,"epoch_slot",200775,"slot_leader","pool1uxws0e2d8kg2hncjc0szkwrpd0wajx0gn7unympa2myucjdm6dz","size",366,"tx_count",1,"output","4960335032","fees","172585","block_vrf","vrf_vk1mnc45cv7qxzrwv795jaxaxjaf4q42vl50dwh7r6h59f625nn9fuq6k6esc","previous_block","2fcff256944da22852f1d1de12f622826485281bb8ab47b269d28c94d2719d57","next_block","43900d07f86515c1f4519fecc12fda1da55ea71e7c3586ae7658405f70a2ed65","confirmations",49486]')!);

// final Response<TxContentUtxo> txContentUtxo =
//     Response(requestOptions: RequestOptions(path: ''), statusCode: 200, data: serializers.fromJson(TxContentUtxo.serializer, '["inputs",[["address","addr_test1qzu5kd7wqjhgjkdy557d8fu3gq5ktjmjwah0n9y285unuxqxu2hyfhlkwuxupa9d5085eunq2qywy7hvmvej456flknsd434uu","amount",[["unit","lovelace","quantity","4960507617"],["unit","6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7","quantity","950"]]]],"outputs",[["address","addr_test1qrektsyevyxxqpytjwnwxvmvrj8xgzv4qsuzf57qkp432ma24fm4c4hnud6cw53zj8v48kdwmeykn0knf74ag68tmf9sk7kesv","amount",[["unit","lovelace","quantity","1407406"],["unit","6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7","quantity","2"]]],["address","addr_test1qqcgrr08ycu63a5qe6sjgr8narpv2czfm3y3td9njq9hfxcxu2hyfhlkwuxupa9d5085eunq2qywy7hvmvej456flknsvvlyct","amount",[["unit","lovelace","quantity","4958927626"],["unit","6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7","quantity","948"]]]]]')!);

Response<TxContentUtxo> txContentUtxo(String txId) {
  String json = '';
  switch (txId) {
    case tx1:
      json =
          '["inputs",[["address","addr_test1qzxs6rwvj65sgylxh27y6ljdys8vr22z46s27k3m7fsaqcpxngwdkqgqcvjtzmz624d6efz67ysf3597k24uyzqg5ctsh478e0","amount",[["unit","lovelace","quantity","1000000000"]], "tx_hash", "9c78707104020738c01f17e9d04d465aa6d41806617efa74abec303b50b37152", "output_index", 0]],"outputs",[["address","addr_test1qputeu63ld6c0cd526w90ry2r9upc5ac8y3zetcg85xs5l924fm4c4hnud6cw53zj8v48kdwmeykn0knf74ag68tmf9sutu8kq","amount",[["unit","lovelace","quantity","100000000"]]],["address","addr_test1qp680xknwamupzcuf9jwngrr6k69vzuwyjs87z583k74gafxngwdkqgqcvjtzmz624d6efz67ysf3597k24uyzqg5ctsx5kkgg","amount",[["unit","lovelace","quantity","899831199"]]]]]';
      break;
    case tx2:
      json =
          '["inputs",[["address","addr_test1qrk57pwnv502vtrz4uhnym0ajefnrcz8p63f982n0fhlhh3xngwdkqgqcvjtzmz624d6efz67ysf3597k24uyzqg5cts577csf","amount",[["unit","lovelace","quantity","299493597"]], "tx_hash", "d11241823c72eaccc50303f865c9b6a5fff5828d87ef9da430f22a049acb04d1", "output_index", 1]],"outputs",[["address","addr_test1qputeu63ld6c0cd526w90ry2r9upc5ac8y3zetcg85xs5l924fm4c4hnud6cw53zj8v48kdwmeykn0knf74ag68tmf9sutu8kq","amount",[["unit","lovelace","quantity","100000000"]]],["address","addr_test1qqltwrdj339cx6l98ze8zveldczmrg0cr0u7k7f6gyadae3xngwdkqgqcvjtzmz624d6efz67ysf3597k24uyzqg5ctsh243r9","amount",[["unit","lovelace","quantity","199324796"]]]]]';
      break;
    case tx3:
      json =
          '["inputs",[["address","addr_test1qputeu63ld6c0cd526w90ry2r9upc5ac8y3zetcg85xs5l924fm4c4hnud6cw53zj8v48kdwmeykn0knf74ag68tmf9sutu8kq","amount",[["unit","lovelace","quantity","100000000"]], "tx_hash", "8afcf3999633a58c9ce5e22578b59ef5bb7c5dddacfbaf504ee05f5f5ad0d581","output_index", 0],["address","addr_test1qrektsyevyxxqpytjwnwxvmvrj8xgzv4qsuzf57qkp432ma24fm4c4hnud6cw53zj8v48kdwmeykn0knf74ag68tmf9sk7kesv","amount",[["unit","lovelace","quantity","1407406"],["unit","6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7","quantity","2"]], "tx_hash", "dd45074a89c51562cf68174e94db93d800c4cfa9e5c474f9d906a5aaf7c5b953", "output_index", 0]],"outputs",[["address","addr_test1qpyrm5j80cwcgc0mypy4cq7547ylkun7hsx5amnhep55nm3xngwdkqgqcvjtzmz624d6efz67ysf3597k24uyzqg5cts95gflm","amount",[["unit","lovelace","quantity","2000000"],["unit","6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7","quantity","1"]]],["address","addr_test1qpcdsfzewqkl3w5kxk553hts5lvw9tdjda9nzt069gqmyud24fm4c4hnud6cw53zj8v48kdwmeykn0knf74ag68tmf9s89kyst","amount",[["unit","lovelace","quantity","99228617"],["unit","6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7","quantity","1"]]]]]';
      break;
    case tx4:
      json =
          '["inputs",[["address","addr_test1qzu5kd7wqjhgjkdy557d8fu3gq5ktjmjwah0n9y285unuxqxu2hyfhlkwuxupa9d5085eunq2qywy7hvmvej456flknsd434uu","amount",[["unit","lovelace","quantity","4960507617"],["unit","6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7","quantity","950"]], "tx_hash", "fb4a0898c580443b757782fd5393a82bcd43b5d7bc514228d0edca331b33795f", "output_index", 1]],"outputs",[["address","addr_test1qrektsyevyxxqpytjwnwxvmvrj8xgzv4qsuzf57qkp432ma24fm4c4hnud6cw53zj8v48kdwmeykn0knf74ag68tmf9sk7kesv","amount",[["unit","lovelace","quantity","1407406"],["unit","6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7","quantity","2"]]],["address","addr_test1qqcgrr08ycu63a5qe6sjgr8narpv2czfm3y3td9njq9hfxcxu2hyfhlkwuxupa9d5085eunq2qywy7hvmvej456flknsvvlyct","amount",[["unit","lovelace","quantity","4958927626"],["unit","6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7","quantity","948"]]]]]';
      break;
    default:
      throw Exception('unknown txId: $txId');
  }
  try {
    final content = serializers.fromJson(TxContentUtxo.serializer, json)!;
    final result = Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        data: content);
    return result;
  } catch (e) {
    print("ERROR parsing TxContentUtxo(txId: $txId): $e");
    rethrow;
  }
}

final Response<Asset> asset = Response(
    requestOptions: RequestOptions(path: ''),
    statusCode: 200,
    data: serializers.fromJson(Asset.serializer,
        '["policy_id","6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7","fingerprint","asset1cvmyrfrc7lpht2hcjwr9lulzyyjv27uxh3kcz0","quantity","100042","initial_mint_tx_hash","abfda1ba36b9ee541516fda311319f7bdb3e3928776c2982d2f027f3e8fa54c7","mint_or_burn_count",1,"metadata",["name","Testcoin","description","Testcoin crypto powered by Cardano testnet.","ticker","TEST","url","https://developers.cardano.org/"]]')!);

/*
blockfrost.getCardanoAssetsApi().assetsAssetGet(asset: 6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7) -> ["policy_id","6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7","asset_name",null,"fingerprint","asset1cvmyrfrc7lpht2hcjwr9lulzyyjv27uxh3kcz0","quantity","100042","initial_mint_tx_hash","abfda1ba36b9ee541516fda311319f7bdb3e3928776c2982d2f027f3e8fa54c7","mint_or_burn_count",1,"onchain_metadata",null,"metadata",["name","Testcoin","description","Testcoin crypto powered by Cardano testnet.","ticker","TEST","url","https://developers.cardano.org/","logo",null,"decimals",null]]

blockfrost.getCardanoTransactionsApi().txsHashUtxosGet(hash:ffcbd47773a37289bc64b976d3a0b823594cce330c2f425437e5419437c589db) -> ["inputs",[["address","addr_test1qzxs6rwvj65sgylxh27y6ljdys8vr22z46s27k3m7fsaqcpxngwdkqgqcvjtzmz624d6efz67ysf3597k24uyzqg5ctsh478e0","amount",[["unit","lovelace","quantity","1000000000"]]]],"outputs",[["address","addr_test1qputeu63ld6c0cd526w90ry2r9upc5ac8y3zetcg85xs5l924fm4c4hnud6cw53zj8v48kdwmeykn0knf74ag68tmf9sutu8kq","amount",[["unit","lovelace","quantity","100000000"]]],["address","addr_test1qp680xknwamupzcuf9jwngrr6k69vzuwyjs87z583k74gafxngwdkqgqcvjtzmz624d6efz67ysf3597k24uyzqg5ctsx5kkgg","amount",[["unit","lovelace","quantity","899831199"]]]]]
blockfrost.getCardanoTransactionsApi().txsHashUtxosGet(hash:8afcf3999633a58c9ce5e22578b59ef5bb7c5dddacfbaf504ee05f5f5ad0d581) -> ["inputs",[["address","addr_test1qrk57pwnv502vtrz4uhnym0ajefnrcz8p63f982n0fhlhh3xngwdkqgqcvjtzmz624d6efz67ysf3597k24uyzqg5cts577csf","amount",[["unit","lovelace","quantity","299493597"]]]],"outputs",[["address","addr_test1qputeu63ld6c0cd526w90ry2r9upc5ac8y3zetcg85xs5l924fm4c4hnud6cw53zj8v48kdwmeykn0knf74ag68tmf9sutu8kq","amount",[["unit","lovelace","quantity","100000000"]]],["address","addr_test1qqltwrdj339cx6l98ze8zveldczmrg0cr0u7k7f6gyadae3xngwdkqgqcvjtzmz624d6efz67ysf3597k24uyzqg5ctsh243r9","amount",[["unit","lovelace","quantity","199324796"]]]]]
blockfrost.getCardanoTransactionsApi().txsHashUtxosGet(hash:339581327a0da0b3397adf41c56fd56b4737f5afd4c9bb8c41744cc85e221538) -> ["inputs",[["address","addr_test1qputeu63ld6c0cd526w90ry2r9upc5ac8y3zetcg85xs5l924fm4c4hnud6cw53zj8v48kdwmeykn0knf74ag68tmf9sutu8kq","amount",[["unit","lovelace","quantity","100000000"]]],["address","addr_test1qrektsyevyxxqpytjwnwxvmvrj8xgzv4qsuzf57qkp432ma24fm4c4hnud6cw53zj8v48kdwmeykn0knf74ag68tmf9sk7kesv","amount",[["unit","lovelace","quantity","1407406"],["unit","6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7","quantity","2"]]]],"outputs",[["address","addr_test1qpyrm5j80cwcgc0mypy4cq7547ylkun7hsx5amnhep55nm3xngwdkqgqcvjtzmz624d6efz67ysf3597k24uyzqg5cts95gflm","amount",[["unit","lovelace","quantity","2000000"],["unit","6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7","quantity","1"]]],["address","addr_test1qpcdsfzewqkl3w5kxk553hts5lvw9tdjda9nzt069gqmyud24fm4c4hnud6cw53zj8v48kdwmeykn0knf74ag68tmf9s89kyst","amount",[["unit","lovelace","quantity","99228617"],["unit","6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7","quantity","1"]]]]]
blockfrost.getCardanoTransactionsApi().txsHashUtxosGet(hash:dd45074a89c51562cf68174e94db93d800c4cfa9e5c474f9d906a5aaf7c5b953) -> ["inputs",[["address","addr_test1qzu5kd7wqjhgjkdy557d8fu3gq5ktjmjwah0n9y285unuxqxu2hyfhlkwuxupa9d5085eunq2qywy7hvmvej456flknsd434uu","amount",[["unit","lovelace","quantity","4960507617"],["unit","6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7","quantity","950"]]]],"outputs",[["address","addr_test1qrektsyevyxxqpytjwnwxvmvrj8xgzv4qsuzf57qkp432ma24fm4c4hnud6cw53zj8v48kdwmeykn0knf74ag68tmf9sk7kesv","amount",[["unit","lovelace","quantity","1407406"],["unit","6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7","quantity","2"]]],["address","addr_test1qqcgrr08ycu63a5qe6sjgr8narpv2czfm3y3td9njq9hfxcxu2hyfhlkwuxupa9d5085eunq2qywy7hvmvej456flknsvvlyct","amount",[["unit","lovelace","quantity","4958927626"],["unit","6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7","quantity","948"]]]]]
*/
///
/// Mock BlockFrost data for Wallet 2
///
@GenerateMocks([
  Blockfrost,
  Dio,
  CardanoAccountsApi,
  CardanoAddressesApi,
  CardanoAssetsApi,
  CardanoBlocksApi,
  CardanoMetadataApi,
  CardanoTransactionsApi
])
Blockfrost buildMockBlockfrostWallet2() {
  var cardanoAccountsApi = MockCardanoAccountsApi();
  var cardanoAddressesApi = MockCardanoAddressesApi();
  var cardanoTransactionsApi = MockCardanoTransactionsApi();
  var cardanoBlocksApi = MockCardanoBlocksApi();
  var cardanoAssetsApi = MockCardanoAssetsApi();

  var blockfrost = MockBlockfrost();
  when(blockfrost.getCardanoAccountsApi()).thenReturn(cardanoAccountsApi);
  when(blockfrost.getCardanoAddressesApi()).thenReturn(cardanoAddressesApi);
  when(blockfrost.getCardanoTransactionsApi())
      .thenReturn(cardanoTransactionsApi);
  when(blockfrost.getCardanoBlocksApi()).thenReturn(cardanoBlocksApi);
  when(blockfrost.getCardanoAssetsApi()).thenReturn(cardanoAssetsApi);

  //addresses
  when(cardanoAccountsApi.accountsStakeAddressGet(stakeAddress: stakeAddr2))
      .thenAnswer((_) async => accountContent);
  final addresses2 = (ListBuilder<JsonObject>()
        ..add(MapJsonObject({'address': addr1}))
        ..add(MapJsonObject({'address': addr2}))
        ..add(MapJsonObject({'address': addr3})))
      .build();

  //addresses transactions
  when(cardanoAccountsApi.accountsStakeAddressAddressesGet(
          stakeAddress: stakeAddr2, count: anyNamed('count')))
      .thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: addresses2));
  when(cardanoAddressesApi.addressesAddressTxsGet(address: addr1)).thenAnswer(
      (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: BuiltList.of([tx1, tx2, tx3])));
  when(cardanoAddressesApi.addressesAddressTxsGet(address: addr2)).thenAnswer(
      (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: BuiltList.of([tx4, tx3])));
  when(cardanoAddressesApi.addressesAddressTxsGet(address: addr3)).thenAnswer(
      (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: BuiltList.of([tx3])));

  //transaction content
  when(cardanoTransactionsApi.txsHashGet(hash: tx1))
      .thenAnswer((_) async => txContent(tx1));
  when(cardanoTransactionsApi.txsHashGet(hash: tx2))
      .thenAnswer((_) async => txContent(tx2));
  when(cardanoTransactionsApi.txsHashGet(hash: tx3))
      .thenAnswer((_) async => txContent(tx3));
  when(cardanoTransactionsApi.txsHashGet(hash: tx4))
      .thenAnswer((_) async => txContent(tx4));

  //transaction  blocks
  when(cardanoBlocksApi.blocksHashOrNumberGet(hashOrNumber: blk1))
      .thenAnswer((_) async => blockContent(blk1));
  when(cardanoBlocksApi.blocksHashOrNumberGet(hashOrNumber: blk2))
      .thenAnswer((_) async => blockContent(blk2));
  when(cardanoBlocksApi.blocksHashOrNumberGet(hashOrNumber: blk3))
      .thenAnswer((_) async => blockContent(blk3));
  when(cardanoBlocksApi.blocksHashOrNumberGet(hashOrNumber: blk4))
      .thenAnswer((_) async => blockContent(blk4));

  when(cardanoBlocksApi.blocksLatestGet())
      .thenAnswer((_) async => blockContent(blk0));

  //transactions UTx0s
  when(cardanoTransactionsApi.txsHashUtxosGet(hash: tx1))
      .thenAnswer((_) async => txContentUtxo(tx1));
  when(cardanoTransactionsApi.txsHashUtxosGet(hash: tx2))
      .thenAnswer((_) async => txContentUtxo(tx2));
  when(cardanoTransactionsApi.txsHashUtxosGet(hash: tx3))
      .thenAnswer((_) async => txContentUtxo(tx3));
  when(cardanoTransactionsApi.txsHashUtxosGet(hash: tx4))
      .thenAnswer((_) async => txContentUtxo(tx4));

  when(cardanoTransactionsApi.txSubmitPost(
          contentType: 'application/cbor',
          data: anyNamed('data'),
          headers: anyNamed('headers')))
      .thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: 'success'));

  //native assets
  when(cardanoAssetsApi.assetsAssetGet(asset: asset1))
      .thenAnswer((_) async => asset);

  //when(cardanoTransactionsApi.txsHashGet(hash: tx1)).thenAnswer((realInvocation) => null)

  return blockfrost;
}
