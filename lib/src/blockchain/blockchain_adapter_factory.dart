// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:blockfrost/blockfrost.dart';
import 'package:cardano_wallet_sdk/src/blockchain/blockchain_adapter.dart';
import 'package:cardano_wallet_sdk/src/blockchain/blockfrost/blockfrost_api_key_auth.dart';
import 'package:cardano_wallet_sdk/src/blockchain/blockfrost/blockfrost_blockchain_adapter.dart';
import 'package:cardano_wallet_sdk/src/network/network_id.dart';
import 'package:dio/dio.dart';

///
/// Provides a properly configured BlockchainAdapter for the requirested network.
/// Instances are cached and should be reused because they often cache
/// invariant blockchain data allowing for faster updates.
///
class BlockchainAdapterFactory {
  final Interceptor authInterceptor;
  final NetworkId networkId;
  Blockfrost? _blockfrost;
  BlockfrostBlockchainAdapter? _blockfrostAdapter;

  BlockchainAdapterFactory(
      {required this.authInterceptor, required this.networkId});

  /// creates an interceptor give a key
  static Interceptor interceptorFromKey({required String key}) =>
      BlockfrostApiKeyAuthInterceptor(projectId: key);

  factory BlockchainAdapterFactory.fromKey(
          {required String key, required NetworkId networkId}) =>
      BlockchainAdapterFactory(
          authInterceptor: interceptorFromKey(key: key), networkId: networkId);

  ///
  /// return cached BlockchainAdapter instance.
  ///
  BlockchainAdapter adapter() {
    if (_blockfrostAdapter == null) {
      final blockfrost = _cachedBlockfrost(
          networkId: networkId, authInterceptor: authInterceptor);
      _blockfrostAdapter = BlockfrostBlockchainAdapter(
          networkId: networkId, blockfrost: blockfrost);
    }
    return _blockfrostAdapter!;
  }

  /// clear cached instances
  void clear() {
    _blockfrostAdapter = null;
    _blockfrost = null;
  }

  /// provides a cahced Blockfrost instance.
  Blockfrost _cachedBlockfrost(
      {required NetworkId networkId, required Interceptor authInterceptor}) {
    if (_blockfrost == null) {
      final url = BlockfrostBlockchainAdapter.urlFromNetwork(networkId);
      print("new Blockfrost($url)");
      _blockfrost = Blockfrost(
        basePathOverride: url,
        interceptors: [authInterceptor],
      );
    }
    return _blockfrost!;
  }
}
