// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:bip32_ed25519/bip32_ed25519.dart';
import 'package:pinenacl/tweetnacl.dart';
import '../../../cardano_wallet_sdk.dart';
import 'package:cbor/cbor.dart';

const int secretKeyLength = 32;

///
/// Extends ShelleyTransaction to handle signature verification.
///
extension BcTransactionLogic on BcTransaction {
  ///
  /// Given a signing key, return the signature and verify key as a witness.
  /// If fakeSignature is true, just return a dummy signature for cost calculations.
  /// TODO use signEd25519Extended function?
  ///
  BcVkeyWitness signedWitness(Bip32SigningKey signingKey,
      {bool fakeSignature = false}) {
    final bodyData = cbor.encode(body.toCborMap());
    List<int> hash = blake2bHash256(bodyData);
    final signedMessage =
        fakeSignature ? _fakeSign(hash) : signingKey.sign(hash);
    final witness = BcVkeyWitness(
        vkey: signingKey.verifyKey.rawKey, signature: signedMessage.signature);
    return witness;
  }

  ///
  /// Give a list of signing keys, generate new transaction containing a witness set.
  /// If fakeSignature is true, generate dummy signatures for cost calculations.
  ///
  BcTransaction sign(List<Bip32SigningKey> signingKeys,
      {bool fakeSignature = false}) {
    List<BcVkeyWitness> witnesses = signingKeys
        .map((k) => signedWitness(k, fakeSignature: fakeSignature))
        .toList();
    final witnessSet =
        BcTransactionWitnessSet(vkeyWitnesses: witnesses, nativeScripts: []);
    return BcTransaction(
        body: body,
        isValid: isValid,
        metadata: metadata,
        witnessSet: witnessSet);
  }

  /// Generate fake signature that just has to be correct length for size calculation.
  SignedMessage _fakeSign(List<int> message) {
    var sm = Uint8List(message.length + TweetNaCl.signatureLength);
    sm.fillRange(
        0, sm.length, 42); //file fake sig with meaning of life & everything.
    return SignedMessage.fromList(signedMessage: sm);
  }

  ///
  /// Verify each witness in the witness set.
  ///
  bool get verify {
    if (witnessSet == null || witnessSet!.isEmpty) {
      return false;
    }
    for (BcVkeyWitness witness in witnessSet!.vkeyWitnesses) {
      final signature =
          Signature(Uint8List.fromList(witness.signature.sublist(0, 64)));
      // witness.signature.sublist(0, Signature.signatureLength)));
      final verifyKey = VerifyKey(witness.vkey.sublist(0, 32).toUint8List());
      // final verifyKey = Bip32VerifyKey(witness.vkey.toUint8List());
      final bodyData = cbor.encode(body.toCborMap());
      final List<int> hash = blake2bHash256(bodyData);
      Uint8List message = Uint8List.fromList(hash);
      // if (!verifyKey.verify(signature: signature, message: message)) {
      if (!verifyEd25519(
          signature: signature.asTypedList,
          message: message,
          publicKey: verifyKey.asTypedList)) {
        return false;
      }
    }
    return true;
  }
}
