// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'dart:convert';
import 'dart:typed_data';
import 'package:base_x/base_x.dart';
import 'package:hex/hex.dart';
import 'package:typed_data/typed_data.dart'; // as typed;
import '../address/shelley_address.dart';

///
/// Various encoders, decoders and type converters.
///

/// base58 codec
BaseXCodec base58Codec =
    BaseXCodec('123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz');

final Codec<String, String> str2hex = utf8.fuse(HEX);
final Codec<String, String> hex2str = str2hex.inverted;

final _emptyUint8Buffer = Uint8Buffer(0);

///
/// convert hex string to Uint8Buffer. Strips off 0x prefix if present.
///
Uint8Buffer uint8BufferFromHex(String hex,
    {bool utf8EncodeOnHexFailure = false}) {
  if (hex.isEmpty) return _emptyUint8Buffer;
  try {
    final list =
        hex.startsWith('0x') ? HEX.decode(hex.substring(2)) : HEX.decode(hex);
    final result = Uint8Buffer();
    result.addAll(list);
    return result;
  } catch (e) {
    if (!utf8EncodeOnHexFailure) rethrow;
    final list = utf8.encode(hex);
    final result = Uint8Buffer();
    result.addAll(list);
    return result;
  }
}

///
/// convert hex string to Uint8Buffer. Strips off 0x prefix if present.
///
Uint8List uint8ListFromHex(String hex, {bool utf8EncodeOnHexFailure = false}) {
  if (hex.isEmpty) return Uint8List.fromList([]);
  try {
    final list =
        hex.startsWith('0x') ? HEX.decode(hex.substring(2)) : HEX.decode(hex);
    return Uint8List.fromList(list);
  } catch (e) {
    if (!utf8EncodeOnHexFailure) rethrow;
    final list = utf8.encode(hex);
    return Uint8List.fromList(list);
    ;
  }
}

///
/// Convert List<int> bytes to Uint8Buffer.
///
// Uint8Buffer unit8BufferFromBytes(List<int> bytes) =>
//     Uint8Buffer()..addAll(bytes);

///
/// Convert List<int> bytes to Uint8List.
///
//Uint8List uint8ListFromBytes(List<int> bytes) => Uint8List.fromList(bytes);

String hexFromUnit8Buffer(Uint8Buffer bytes) => HEX.encode(bytes);

///
/// Convert bech32 address payload to hex adding network prefix.
/// TODO move to shelley_address.dart
///
Uint8Buffer unit8BufferFromShelleyAddress(String bech32) {
  final addr = ShelleyAddress.fromBech32(bech32); //TODO rather inefficient
  final result = Uint8Buffer();
  result.addAll(addr.bytes);
  return result;
}

///
/// Convert bech32 address payload to hex string. Optionaly uppercase hex string.
/// TODO move to shelley_address.dart
///
String hexFromShelleyAddress(String bech32, {bool uppercase = false}) {
  final result = HEX.encode(unit8BufferFromShelleyAddress(bech32));
  return uppercase ? result.toUpperCase() : result;
}

///
/// Convert bytes to bech32 Shelley address.
/// TODO move to shelley_address.dart
///
String bech32ShelleyAddressFromBytes(Uint8Buffer bytes) {
  final addr = ShelleyAddress(bytes);
  return addr.toBech32();
}

String bech32ShelleyAddressFromIntList(List<int> bytes) {
  final addr = ShelleyAddress(bytes);
  return addr.toBech32();
}
