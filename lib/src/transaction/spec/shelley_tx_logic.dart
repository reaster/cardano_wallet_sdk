// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:bip32_ed25519/bip32_ed25519.dart';
import '../../util/blake2bhash.dart';
import '../../util/codec.dart';
import './shelley_spec.dart';

///
/// Extends ShelleyTransaction to handle signature verification.
///
extension ShelleyTransactionLogic on ShelleyTransaction {
  ///
  /// Verify each witness in the witness set.
  ///
  bool get verify {
    for (ShelleyVkeyWitness witness in witnessSet!.vkeyWitnesses) {
      final signature = Signature(Uint8List.fromList(
          witness.signature.sublist(0, Signature.signatureLength)));
      final verifyKey = Bip32VerifyKey(uint8ListFromBytes(witness.vkey));
      final bodyData = body.toCborMap().getData();
      final List<int> hash = blake2bHash256(bodyData);
      Uint8List message = Uint8List.fromList(hash);
      if (!verifyKey.verify(signature: signature, message: message)) {
        return false;
      }
    }
    return true;
  }
}
