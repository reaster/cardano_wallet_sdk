// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:dio/dio.dart';
import 'package:blockfrost/blockfrost.dart';
import 'package:logging/logging.dart';
import '../network/network_id.dart';
import './blockchain_adapter.dart';
import './blockfrost/blockfrost_api_key_auth.dart';
import './blockfrost/blockfrost_blockchain_adapter.dart';

///
/// Provides a properly configured BlockchainAdapter for the requirested network.
/// Instances are cached and should be reused because they often cache
/// invariant blockchain data allowing for faster updates.
///
class BlockchainAdapterFactory {
  final Interceptor authInterceptor;
  final Networks network;
  final String projectId;
  Blockfrost? _blockfrost;
  BlockfrostBlockchainAdapter? _blockfrostAdapter;

  final logger = Logger('BlockchainAdapterFactory');

  BlockchainAdapterFactory(
      {required this.authInterceptor,
      required this.network,
      required this.projectId});

  /// creates an interceptor give a key
  static Interceptor interceptorFromKey({required String key}) =>
      BlockfrostApiKeyAuthInterceptor(projectId: key);

  factory BlockchainAdapterFactory.fromKey(
          {required String key, required Networks network}) =>
      BlockchainAdapterFactory(
          authInterceptor: interceptorFromKey(key: key),
          network: network,
          projectId: key);

  ///
  /// return cached BlockchainAdapter instance.
  ///
  BlockchainAdapter adapter() {
    if (_blockfrostAdapter == null) {
      final blockfrost =
          _cachedBlockfrost(network: network, authInterceptor: authInterceptor);
      _blockfrostAdapter = BlockfrostBlockchainAdapter(
          network: network, blockfrost: blockfrost, projectId: projectId);
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
      {required Networks network, required Interceptor authInterceptor}) {
    if (_blockfrost == null) {
      final url = BlockfrostBlockchainAdapter.urlFromNetwork(network);
      logger.info("new Blockfrost($url)");
      _blockfrost = Blockfrost(
        basePathOverride: url,
        interceptors: [authInterceptor],
      );
    }
    return _blockfrost!;
  }
}
