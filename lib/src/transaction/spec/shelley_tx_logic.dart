// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:bip32_ed25519/bip32_ed25519.dart';
import '../../../cardano_wallet_sdk.dart';

const int secretKeyLength = 32;

///
/// Extends ShelleyTransaction to handle signature verification.
///
extension ShelleyTransactionLogic on ShelleyTransaction {
  ///
  /// Verify each witness in the witness set.
  ///
  bool get verify {
    for (ShelleyVkeyWitness witness in witnessSet!.vkeyWitnesses) {
      final signature =
          Signature(Uint8List.fromList(witness.signature.sublist(0, 64)));
      // witness.signature.sublist(0, Signature.signatureLength)));
      final verifyKey =
          VerifyKey(uint8ListFromBytes(witness.vkey.sublist(0, 32)));
      // final verifyKey = Bip32VerifyKey(uint8ListFromBytes(witness.vkey));
      final bodyData = body.toCborMap().getData();
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
