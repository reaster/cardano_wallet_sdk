// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/src/transaction/spec/shelley_spec.dart';
import 'package:cardano_wallet_sdk/src/util/blake2bhash.dart';
import 'package:cardano_wallet_sdk/src/util/codec.dart';
import 'package:bip32_ed25519/bip32_ed25519.dart';

///
/// Extends ShelleyTransaction to handle signature verification.
///
extension ShelleyTransactionLogic on ShelleyTransaction {
  ///
  /// Verify each witness in the witness set.
  ///
  bool get verify {
    for (ShelleyVkeyWitness witness in this.witnessSet!.vkeyWitnesses) {
      final signature = Signature(Uint8List.fromList(
          witness.signature.sublist(0, Signature.signatureLength)));
      final verifyKey = Bip32VerifyKey(uint8ListFromBytes(witness.vkey));
      final bodyData = this.body.toCborMap().getData();
      final List<int> hash = blake2bHash256(bodyData);
      Uint8List message = Uint8List.fromList(hash);
      if (!verifyKey.verify(signature: signature, message: message)) {
        return false;
      }
    }
    return true;
  }
}
