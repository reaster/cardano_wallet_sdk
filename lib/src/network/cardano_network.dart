enum NetworkId { testnet, mainnet }

class CardanoNetwork {
  final NetworkId networkId;
  final String name;
  final String blockfrostUrl;
  final String browserUrl;
  final CardanoBlockchainExplorer explorer;

  CardanoNetwork(this.networkId, this.name, this.blockfrostUrl, this.browserUrl)
      : explorer = CardanoBlockchainExplorer(baseUrl: browserUrl);

  static Map<NetworkId, CardanoNetwork> _map = {};

  static CardanoNetwork network(NetworkId networkId) {
    if (_map.isEmpty) {
      _map[NetworkId.testnet] = CardanoNetwork(
        NetworkId.testnet,
        'Cardano Testnet',
        'https://cardano-testnet.blockfrost.io/api/v0',
        'https://explorer.cardano-testnet.iohkdev.io/',
      );
      _map[NetworkId.mainnet] = CardanoNetwork(
        NetworkId.mainnet,
        'Cardano Main Network',
        'https://cardano-mainnet.blockfrost.io/api/v0',
        'https://explorer.cardano.org/',
      );
    }
    return _map[networkId]!;
  }
}

class CardanoBlockchainExplorer {
  final String baseUrl;
  final String lang;

  CardanoBlockchainExplorer({required this.baseUrl, this.lang = 'en'});

  /// result example: https://explorer.cardano.org/en/epoch?number=268
  String epicUrl({required int epicNumber}) => "$baseUrl/$lang/epoch?number=$epicNumber";

  /// result example: https://explorer.cardano.org/en/block?id=67f5e3c6094c7c3e5a3ec82d75b6cb0e5009f9bb3b7f8bd9eab6cd248b2f5f54
  String blockUrl({required String blockIdHex32}) => "$baseUrl/$lang/block?id=$blockIdHex32";

  // result example: https://explorer.cardano.org/en/transaction?id=4602417d2786f6e315b320275a54432b935f770cf1b43811f676fd352645c158
  String transactionUrl({required String transactionIdHex32}) => "$baseUrl/$lang/transaction?id=$transactionIdHex32";

  /// result example: https://explorer.cardano.org/en/address?address=addr1qyvadph9dewhm8nn0lm2telukv9egd3sxayzextnrr9ephyhky2d9jpqrr83rzvpyum7gty3slchf0u9lnczfqsh2n3q8ukd37
  String addressUrl({required String addressBech32}) => "$baseUrl/$lang/address?address=$addressBech32";
}

class CardanoScanBlockchainExplorer {
  final String baseUrl;

  CardanoScanBlockchainExplorer({this.baseUrl = 'https://cardanoscan.io'});

  /// result example: https://cardanoscan.io/epoch/269
  String epicUrl({required int epicNumber}) => "$baseUrl/epoch/$epicNumber";

  /// result example: https://cardanoscan.io/block/5805954
  String blockUrl({required int blockNumber}) => "$baseUrl/block/$blockNumber";

  // result example: https://cardanoscan.io/transaction/811f7323ad7866cb4093ebbe7d98006f43303a0b7d8654391b571f3f9a952011
  String transactionUrl({required String transactionIdHex32}) => "$baseUrl/transaction/$transactionIdHex32";

  /// result example: https://cardanoscan.io/address/addr1v95sf69jcfhnmknvffwmfvlvnccatqwfjcyh0nlfc6gh5scta2yzg
  String addressUrl({required String addressBech32}) => "$baseUrl/address/$addressBech32";
}
