// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

// import 'package:bip32_ed25519/bip32_ed25519.dart';
// import 'package:pinenacl/tweetnacl.dart';
// import '../../../cardano_wallet_sdk.dart';
// import 'package:cbor/cbor.dart';

//const int secretKeyLength = 32;

///
/// Extends ShelleyTransaction to handle signature verification.
///
// @Deprecated('use bc_tx_ext.dart')
// extension ShelleyTransactionLogic on ShelleyTransaction {
//   ///
//   /// Verify each witness in the witness set.
//   ///
//   bool get verify {
//     for (ShelleyVkeyWitness witness in witnessSet!.vkeyWitnesses) {
//       final signature =
//           Signature(Uint8List.fromList(witness.signature.sublist(0, 64)));
//       // witness.signature.sublist(0, Signature.signatureLength)));
//       final verifyKey = VerifyKey(witness.vkey.sublist(0, 32).toUint8List());
//       // final verifyKey = Bip32VerifyKey(witness.vkey.toUint8List());
//       final bodyData = cbor.encode(body.toCborMap());
//       final List<int> hash = blake2bHash256(bodyData);
//       Uint8List message = Uint8List.fromList(hash);
//       // if (!verifyKey.verify(signature: signature, message: message)) {
//       if (!verifyEd25519(
//           signature: signature.asTypedList,
//           message: message,
//           publicKey: verifyKey.asTypedList)) {
//         return false;
//       }
//     }
//     return true;
//   }
// }
