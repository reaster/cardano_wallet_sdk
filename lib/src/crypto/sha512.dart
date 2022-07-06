// import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

List<int> hmacSha512({required List<int> key, required List<int> data}) {
  // var key = utf8.encode('p@ssw0rd');
  // var bytes = utf8.encode("foobar");

  final hmacSha512 = Hmac(sha512, key);
  final digest = hmacSha512.convert(data);

  print("HMAC digest as bytes: ${digest.bytes}");
  print("HMAC digest as hex string: $digest");
  return digest.bytes;
}

Uint8List hmacSha512Uint8({required Uint8List key, required Uint8List data}) {
  // var key = utf8.encode('p@ssw0rd');
  // var bytes = utf8.encode("foobar");

  final hmacSha512 = Hmac(sha512, key);
  final digest = hmacSha512.convert(data);

  print("HMAC digest as bytes: ${digest.bytes}");
  print("HMAC digest as hex string: $digest");
  return Uint8List.fromList(digest.bytes);
}
