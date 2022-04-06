// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:hex/hex.dart';
import 'package:pinenacl/encoding.dart';
import '../util/blake2bhash.dart';
import '../util/codec.dart';

class CurrencyAsset {
  /// unique ID for this asset (i.e. policyId+assetName)
  final String assetId;

  /// Policy ID of the asset as a hex encoded hash. Blank for non-mintable tokens (i.e. ADA).
  final String policyId;

  /// Hex-encoded asset name of the asset
  final String assetName;

  /// human-readable version of assetName or empty string
  final String name;

  /// CIP14 based user-facing fingerprint
  final String fingerprint;

  /// Current asset quantity
  final String quantity;

  /// ID of the initial minting transaction
  final String initialMintTxHash;

  final CurrencyAssetMetadata? metadata;

  CurrencyAsset({
    required this.policyId,
    required this.assetName,
    String? fingerprint,
    required this.quantity,
    required this.initialMintTxHash,
    this.metadata,
  })  : assetId = '$policyId$assetName',
        name = hex2str
            .encode(assetName), //if assetName is not hex, this will usualy fail
        fingerprint = fingerprint ??
            calculateFingerprint(policyId: policyId, assetNameHex: assetName);

  bool get isNativeToken => assetId != lovelaceAssetId;
  bool get isADA => assetId == lovelaceAssetId;

  /// return first non-null match from: ticker, metadata.name, name
  String get symbol => metadata?.ticker ?? metadata?.name ?? name;

  @override
  String toString() =>
      "CurrencyAsset(policyId: $policyId assetName: $assetName fingerprint: $fingerprint quantity: $quantity initialMintTxHash: $initialMintTxHash, metadata: $metadata)";
}

/// 'lovelace' encoded as a hex string (i.e. str2hex.encode('lovelace') or '6c6f76656c616365').
const lovelaceHex = '6c6f76656c616365';
const lovelaceAssetId =
    lovelaceHex; // TODO nonstandard. All other libraries just use 'lovelace'

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

  /// Number of decimals in currency. ADA has 6. Default is 0.
  final int decimals;

  CurrencyAssetMetadata(
      {required this.name,
      required this.description,
      this.ticker,
      this.url,
      this.logo,
      this.decimals = 0});
  @override
  String toString() =>
      "CurrencyAssetMetadata(name: $name ticker: $ticker url: $url description: $description hasLogo: ${logo != null})";
}

///
/// Pseudo ADA asset instance allows principal asset to be treated like other native tokens.
/// Blockfrost returns 'lovelace' as the currency unit, whereas all other native tokens are identified by their assetId, a hex string.
/// For consistency, 'lovelace' unit values must be converted to lovelaceHex strings.
///
final lovelacePseudoAsset = CurrencyAsset(
  policyId: '',
  assetName: lovelaceHex,
  quantity: '45000000000', //max
  initialMintTxHash: '',
  metadata: CurrencyAssetMetadata(
    name: 'Cardano',
    description: 'Principal currency of Cardano',
    ticker: 'ADA',
    url: 'https://cardano.org',
    logo: null,
    decimals: 6,
  ),
);

/// given a asset policyId and an assetName in hex, generate a bech32 asset fingerprint
String calculateFingerprint(
    {required String policyId,
    required String assetNameHex,
    String hrp = 'asset'}) {
  //final assetNameHex = str2hex.encode(assetName);
  final assetId = '$policyId$assetNameHex';
  //logger.i("assetId: $assetId");
  final assetIdBytes = HEX.decode(assetId);
  //logger.i(b2s(assetIdBytes, prefix: 'assetIdBytes'));
  final List<int> hashBytes = blake2bHash160(assetIdBytes);
  //logger.i(b2s(hashBytes, prefix: 'hashBytes'));
  final List<int> fiveBitArray = convertBits(hashBytes, 8, 5, false);
  //logger.i(b2s(fiveBitArray, prefix: 'fiveBitArray'));
  return bech32.encode(Bech32(hrp, fiveBitArray));
}

List<int> convertBits(List<int> data, int fromWidth, int toWidth, bool pad) {
  int acc = 0;
  int bits = 0;
  int maxv = (1 << toWidth) - 1;
  List<int> ret = [];

  for (int i = 0; i < data.length; i++) {
    int value = data[i] & 0xff;
    if (value < 0 || value >> fromWidth != 0) {
      throw FormatException("input data bit-width exceeds $fromWidth: $value");
    }
    acc = (acc << fromWidth) | value;
    bits += fromWidth;
    while (bits >= toWidth) {
      bits -= toWidth;
      ret.add((acc >> bits) & maxv);
    }
  }

  if (pad) {
    if (bits > 0) {
      ret.add((acc << (toWidth - bits)) & maxv);
    } else if (bits >= fromWidth || ((acc << (toWidth - bits)) & maxv) != 0) {
      throw FormatException("input data bit-width exceeds $fromWidth: $bits");
    }
  }

  return ret;
}

//
// An AssetId uniquly identifies a native token by combining the policyId with the token name.
// Some properties name this type 'unit'.
//
// class AssetId {
//   /// Policy ID of the asset as a hex encoded hash. Blank for non-mintable tokens (i.e. ADA).
//   final String policyId;

//   /// Hex-encoded asset name of the asset
//   final String name;

//   AssetId({required this.policyId, required this.name});

//   /// ADA assetId has no policyId, just 'lovelace' hex encoded.
//   factory AssetId.ada() => AssetId(policyId: '', name: lovelaceHex);

//   /// return hex encoded assetId by appending policyId+name
//   @override
//   String toString() => policyId + name;
//   @override
//   int get hashCode => policyId.hashCode + name.hashCode;
//   @override
//   bool operator ==(Object other) {
//     final isEqual =
//         identical(this, other) || other is AssetId && runtimeType == other.runtimeType && length == other.length;
//     return isEqual && this.policyId == (other as AssetId).policyId && this.name == other.name;
//   }

//   int get length => policyId.length + name.length;
// }
