// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:bip32_ed25519/bip32_ed25519.dart';
import 'package:cardano_wallet_sdk/src/crypto/key_util.dart';

import './model/bc_scripts.dart';

class Policy {
  final String? name;
  final BcNativeScript policyScript;
  final List<SigningKey> policyKeys;

  Policy({this.name, required this.policyScript, required this.policyKeys});

  String get policyId => policyScript.policyId;

  static const int slotsPerEpoch = 5 * 24 * 60 * 60;

  factory Policy.createEpochBasedTimeLocked(
      String? name, int currentSlot, int epochs) {
    final signingKey = KeyUtil.generateSigningKey();
    final scriptPubkey = BcScriptPubkey(
        keyHash: KeyUtil.keyHash(verifyKey: signingKey.verifyKey));
    final requireTimeBefore =
        BcRequireTimeBefore(slot: currentSlot + slotsPerEpoch * epochs);
    final scriptAll = BcScriptAll(scripts: [requireTimeBefore, scriptPubkey]);
    return Policy(
        name: name, policyScript: scriptAll, policyKeys: [signingKey]);
  }

  factory Policy.createMultiSigScriptAll(String? name, int numOfSigners) {
    if (numOfSigners < 1) {
      throw ArgumentError(
          "Number of policy signers must be larger or equal to 1");
    }
    final policyKeys = List<SigningKey>.generate(
        numOfSigners, (_) => KeyUtil.generateSigningKey(),
        growable: false);
    final policyAll = BcScriptAll(
        scripts: policyKeys
            .map((k) => BcScriptPubkey(
                keyHash: KeyUtil.keyHash(verifyKey: k.verifyKey)))
            .toList());
    return Policy(name: name, policyScript: policyAll, policyKeys: policyKeys);
  }

  factory Policy.createMultiSigScriptAtLeast(
    String? name,
    int numOfSigners,
    int atLeast,
  ) {
    if (atLeast > numOfSigners) {
      throw ArgumentError(
          "Number of required signers cannot be higher than overall signers amount");
    }
    final p = Policy.createMultiSigScriptAll(name, numOfSigners);
    final scriptAtLeast = BcScriptAtLeast(
        amount: atLeast, scripts: (p.policyScript as BcScriptAll).scripts);
    return Policy(
        name: name, policyScript: scriptAtLeast, policyKeys: p.policyKeys);
  }
}
