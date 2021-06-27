import 'dart:typed_data';
import 'package:pinenacl/api.dart';

import 'package:pinenacl/ed25519.dart';
import 'package:pinenacl/digests.dart';
import 'package:pinenacl/tweetnacl.dart';

class InvalidSigningKeyError extends Error {}

class ExtendedSigningKey extends SigningKey {
  // Throws Error as it is very dangerous to have non prune-to-buffered bytes.
  ExtendedSigningKey(Uint8List secretBytes) : this.fromValidBytes(secretBytes);
  ExtendedSigningKey.fromSeed(Uint8List seed) : this(_seedToSecret(seed));

  ExtendedSigningKey.decode(String keyString, {Encoder coder = decoder}) : this(coder.decode(keyString));

  ExtendedSigningKey.generate() : this.normalizeBytes(PineNaClUtils.randombytes(keyLength));

  /// FIXME: `normalizeBytes` modify the source array/list.
  ExtendedSigningKey.normalizeBytes(Uint8List secretBytes) : this.fromValidBytes(clampKey(secretBytes, keyLength), keyLength: keyLength);

  ExtendedSigningKey.fromValidBytes(Uint8List secret, {int keyLength = keyLength})
      : super.fromValidBytes(validateKeyBits(secret), keyLength: keyLength);

  static Uint8List _seedToSecret(Uint8List seed) {
    if (seed.length != seedSize) {
      throw Exception('Seed\'s length (${seed.length}) must be $seedSize long.');
    }
    final extendedSecret = Hash.sha512(seed);
    return clampKey(extendedSecret, keyLength);
  }

  static VerifyKey _toPublic(Uint8List secret) {
    var pk = Uint8List(TweetNaCl.publicKeyLength);
    TweetNaClExt.crypto_scalar_base(pk, secret.toUint8List());
    return VerifyKey(pk);
  }

  static const seedSize = TweetNaCl.seedSize;

  @override
  final int prefixLength = keyLength;

  static const keyLength = 64;

  VerifyKey? _verifyKey;

  @override
  VerifyKey get verifyKey => _verifyKey ??= _toPublic(this.asTypedList);

  @override
  VerifyKey get publicKey => verifyKey;

  ByteList get keyBytes => prefix;

  /// Throws an error on invalid bytes and return the bytes itself anyway
  static Uint8List validateKeyBits(Uint8List bytes) {
    var valid = ((bytes[0] & 7) == 0) && ((bytes[31] & 192) == 64);
    if (bytes.length < 32 || !valid) {
      throw InvalidSigningKeyError();
    }

    return bytes;
  }

  static Uint8List clampKey(Uint8List bytes, int byteLength) {
    if (bytes.length != byteLength) {
      throw InvalidSigningKeyError();
    }
    var resultBytes = bytes.toUint8List();
    resultBytes[0] &= 0xF8; // clear the last 3 bits
    resultBytes[31] &= 0x7F; // clear the 1st bit
    resultBytes[31] |= 0x40; // set the 2nd bit
    return resultBytes;
  }

  @override
  //SignedMessage sign(Uint8List message, {bool extended: false}) => super.sign(message, extended: true);
  SignedMessage sign(List<int> message) {
    // signed message
    var sm = Uint8List(message.length + TweetNaCl.signatureLength);
    var kb = (this.keyBytes + publicKey).toUint8List();
    final result = TweetNaCl.crypto_sign(sm, -1, message.toUint8List(), 0, message.length, kb, extended: true);
    if (result != 0) {
      throw Exception('Signing the massage is failed');
    }

    return SignedMessage.fromList(signedMessage: sm);
  }

  static const decoder = Bech32Coder(hrp: 'ed25519e_sk');

  @override
  Encoder get encoder => decoder;
}
