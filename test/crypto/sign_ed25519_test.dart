// Copyright 2022 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:test/test.dart';
import 'package:pinenacl/ed25519.dart';
import 'dart:convert';
import 'package:hex/hex.dart';
import 'dart:typed_data';

void main() {
  group('Ed25519 - ', () {
    test('signEd25519Extended', () {
      final msg = Uint8List.fromList(utf8.encode('hello'));
      final pvtKey = Uint8List.fromList(HEX.decode(
          '78bfcc962ce4138fba00ea6e46d4eca6ae9457a058566709b52941aaf026fe53dede3f2ddde7762821c2f957aac77b80a3c36beab75881cc83c600695806f1dd'));
      final pubKey = Uint8List.fromList(HEX.decode(
          '9518c18103cbdab9c6e60b58ecc3e2eb439fef6519bb22570f391327381900a8'));
      final expectedSignatureHex =
          'f13fa9acffb108114ec060561b58005fb2d69184de0a2d7400b2ea1f111c0794831cc832c92daf4807820dd9458324935e90bec855e8bf076bbbc4e42b727b07';
      final expectResult = Uint8List.fromList(HEX.decode(expectedSignatureHex));
      //print("expectResult.length: ${expectResult.length}");

      Uint8List signature = signEd25519Extended(
          message: msg, privateKey: pvtKey, publicKey: pubKey);
      final signatureHex = HEX.encode(signature);

      expect(signatureHex, expectedSignatureHex);

      final verified =
          verifyEd25519(signature: signature, message: msg, publicKey: pubKey);
      expect(verified, isTrue);
    });

    test('signEd25519', () {
      final privateKey = Uint8List.fromList(HEX.decode(
          '9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60'));
      final publicKey = Uint8List.fromList(HEX.decode(
          'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a'));
      final msg = Uint8List.fromList(utf8
          .encode('eyJhbGciOiJFZERTQSJ9.RXhhbXBsZSBvZiBFZDI1NTE5IHNpZ25pbmc'));
      final signature = signEd25519(message: msg, privateKey: privateKey);
      final expectedSignature = Uint8List.fromList(HEX.decode(
          '860c98d2297f3060a33f42739672d61b53cf3adefed3d3c672f320dc021b411e9d59b8628dc351e248b88b29468e0e41855b0fb7d83bb15be902bfccb8cd0a02'));
      expect(signature, expectedSignature);

      final verified = verifyEd25519(
          signature: signature, message: msg, publicKey: publicKey);
      expect(verified, isTrue);
    });

    test('signEd25519ZeroSeed', () {
      final seed = Uint8List.fromList(HEX.decode(
          '0000000000000000000000000000000000000000000000000000000000000000'));
      final msg = Uint8List.fromList(utf8.encode('This is a secret message'));
      final signature = signEd25519(message: msg, privateKey: seed);
      final expectedSignature = Uint8List.fromList(HEX.decode(
          '94825896c7075c31bcb81f06dba2bdcd9dcf16e79288d4b9f87c248215c8468d475f429f3de3b4a2cf67fe17077ae19686020364d6d4fa7a0174bab4a123ba0f'));
      expect(signature, expectedSignature);

      final verifyKey = SigningKey(seed: seed).verifyKey;
      final verified = verifyEd25519(
          signature: signature, message: msg, publicKey: verifyKey.asTypedList);
      expect(verified, isTrue);
    });
  });
}
