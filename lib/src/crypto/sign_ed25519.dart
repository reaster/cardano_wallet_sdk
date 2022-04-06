// Copyright 2022 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:bip32_ed25519/api.dart';
import 'package:pinenacl/tweetnacl.dart';
import '../../cardano_wallet_sdk.dart';

///
/// Cryptographic signature methods.
///

///Sign a message with a ed25519 private key and return signature
Uint8List signEd25519(
    {required Uint8List message, required Uint8List privateKey}) {
  final signingKey = SigningKey(seed: privateKey);
  final verifyKey = signingKey.verifyKey;
  final signed = signingKey.sign(message);
  if (signed.isEmpty) {
    throw Exception('Signing the massage is failed');
  }
  if (!verifyKey.verify(signature: signed.signature, message: message)) {
    throw Exception('verify massage failed');
  }
  // print("signed: ${signed.length}");
  return signed.prefix.asTypedList;
}

/// Sign a message with a ed25519 expanded private key and return signature
Uint8List signEd25519Extended(
    {required Uint8List message,
    required Uint8List privateKey,
    required Uint8List publicKey}) {
  List<int> hash = blake2bHash256(message);
  var sm = Uint8List(hash.length + TweetNaCl.signatureLength);
  final kb = Uint8List.fromList(privateKey + publicKey);
  final result = TweetNaCl.crypto_sign(sm, -1, message, 0, message.length, kb,
      extended: true);
  if (result != 0) {
    throw Exception('Signing the massage is failed');
  }
  //print("sm: ${sm.length}, result: $result");
  return sm.length > 64 ? sm.sublist(0, 64) : sm;
}

bool verifyEd25519(
    {required Uint8List signature,
    required Uint8List message,
    required Uint8List publicKey}) {
  if (signature.length != TweetNaCl.signatureLength) {
    throw Exception(
        'Signature length (${signature.length}) is invalid, expected "${TweetNaCl.signatureLength}"');
  }
  final newmessage = signature + message;
  if (newmessage.length < TweetNaCl.signatureLength) {
    throw Exception(
        'Signature length (${newmessage.length}) is invalid, expected "${TweetNaCl.signatureLength}"');
  }
  var m = Uint8List(newmessage.length);

  final result = TweetNaCl.crypto_sign_open(
      m, -1, Uint8List.fromList(newmessage), 0, newmessage.length, publicKey);
  if (result != 0) {
    throw Exception(
        'The message is forged or malformed or the signature is invalid');
  }
  return true;
}
