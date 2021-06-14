class CurrencyAsset {
  /// Policy ID of the asset
  final String policyId;

  /// Hex-encoded asset name of the asset
  final String? assetName;

  /// CIP14 based user-facing fingerprint
  final String? fingerprint;

  /// Current asset quantity
  final String quantity;

  /// ID of the initial minting transaction
  final String initialMintTxHash;

  final CurrencyAssetMetadata? metadata;

  CurrencyAsset(
      {required this.policyId, this.assetName, this.fingerprint, required this.quantity, required this.initialMintTxHash, this.metadata});

  bool get isNativeToken => policyId != 'lovelace';
  bool get isADA => policyId == 'lovelace';

  /// return first non-null match from: ticker, name, assetName, policyId
  String get symbol => metadata?.ticker ?? metadata?.name ?? assetName ?? policyId;

  @override
  String toString() =>
      "CurrencyAsset(policyId: $policyId assetName: $assetName fingerprint: $fingerprint quantity: $quantity initialMintTxHash: $initialMintTxHash, metadata: $metadata)";
}

class CurrencyAssetMetadata {
  /// Asset name
  final String name;

  /// Asset description
  final String description;

  final String? ticker;

  /// Asset website
  final String? url;

  /// Base64 encoded logo of the asset
  final String? logo;

  CurrencyAssetMetadata({required this.name, required this.description, this.ticker, this.url, this.logo});
  @override
  String toString() => "CurrencyAssetMetadata(name: $name ticker: $ticker url: $url description: $description hasLogo: ${logo != null})";
}

final lovelaceCurrencyAsset = CurrencyAsset(
  policyId: 'lovelace',
  assetName: 'lovelace',
  fingerprint: 'asset1lovelace',
  quantity: '45000000000', //max
  initialMintTxHash: "${'lovelace'.hashCode}",
  metadata: CurrencyAssetMetadata(
      name: 'Cardano', description: 'Principal currency of Cardano', ticker: 'ADA', url: 'https://cardano.org', logo: null),
);
