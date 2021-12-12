// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import './network_id.dart';

///
/// Cardano Scan Blockchain Explorer url generator for common blockchain web pages.
/// Supports both mainnet and testnet networks.
///
class CardanoScanBlockchainExplorer {
  final String baseUrl;

  static const mainnetUrl = 'https://cardanoscan.io';
  static const testnetUrl = 'https://testnet.cardanoscan.io';

  CardanoScanBlockchainExplorer({this.baseUrl = mainnetUrl});

  factory CardanoScanBlockchainExplorer.fromNetwork(NetworkId networkId) =>
      CardanoScanBlockchainExplorer(
          baseUrl: networkId == NetworkId.mainnet ? mainnetUrl : testnetUrl);

  /// result example: https://cardanoscan.io/epoch/269
  String epicUrl({required int epicNumber}) => "$baseUrl/epoch/$epicNumber";

  /// result example: https://cardanoscan.io/block/5805954
  String blockUrl({required int blockNumber}) => "$baseUrl/block/$blockNumber";

  // result example: https://cardanoscan.io/transaction/811f7323ad7866cb4093ebbe7d98006f43303a0b7d8654391b571f3f9a952011
  String transactionUrl({required String transactionIdHex32}) =>
      "$baseUrl/transaction/$transactionIdHex32";

  /// result example: https://cardanoscan.io/address/addr1v95sf69jcfhnmknvffwmfvlvnccatqwfjcyh0nlfc6gh5scta2yzg
  String addressUrl({required String addressBech32}) =>
      "$baseUrl/address/$addressBech32";
}
