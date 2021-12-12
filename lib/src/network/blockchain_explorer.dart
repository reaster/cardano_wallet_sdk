// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import './network_id.dart';

///
/// Cardano Blockchain Explorer url generator for common blockchain web pages.
/// Supports both mainnet and testnet networks and i18n language translations.
///
class CardanoBlockchainExplorer {
  final String baseUrl;
  final String lang;

  static const mainnetUrl = 'https://explorer.cardano.org/';
  static const testnetUrl = 'https://explorer.cardano-testnet.iohkdev.io/';

  CardanoBlockchainExplorer({this.baseUrl = mainnetUrl, this.lang = 'en'});

  factory CardanoBlockchainExplorer.fromNetwork(NetworkId networkId) =>
      CardanoBlockchainExplorer(
          baseUrl: networkId == NetworkId.mainnet ? mainnetUrl : testnetUrl);

  /// result example: https://explorer.cardano.org/en/epoch?number=268
  String epicUrl({required int epicNumber}) =>
      "$baseUrl/$lang/epoch?number=$epicNumber";

  /// result example: https://explorer.cardano.org/en/block?id=67f5e3c6094c7c3e5a3ec82d75b6cb0e5009f9bb3b7f8bd9eab6cd248b2f5f54
  String blockUrl({required String blockIdHex32}) =>
      "$baseUrl/$lang/block?id=$blockIdHex32";

  // result example: https://explorer.cardano.org/en/transaction?id=4602417d2786f6e315b320275a54432b935f770cf1b43811f676fd352645c158
  String transactionUrl({required String transactionIdHex32}) =>
      "$baseUrl/$lang/transaction?id=$transactionIdHex32";

  /// result example: https://explorer.cardano.org/en/address?address=addr1qyvadph9dewhm8nn0lm2telukv9egd3sxayzextnrr9ephyhky2d9jpqrr83rzvpyum7gty3slchf0u9lnczfqsh2n3q8ukd37
  String addressUrl({required String addressBech32}) =>
      "$baseUrl/$lang/address?address=$addressBech32";
}
