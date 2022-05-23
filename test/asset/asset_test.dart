// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:hex/hex.dart';
import 'package:test/test.dart';
import 'dart:convert';

void main() {
  test('testTestcoinAsset', () {
    final testcoin = CurrencyAsset(
      policyId: '6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7',
      assetName: '',
      //fingerprint: 'asset1cvmyrfrc7lpht2hcjwr9lulzyyjv27uxh3kcz0',
      quantity: '100042',
      initialMintTxHash:
          'abfda1ba36b9ee541516fda311319f7bdb3e3928776c2982d2f027f3e8fa54c7',
      metadata: CurrencyAssetMetadata(
        name: 'Testcoin',
        description: 'Testcoin cyrpto powered by Cardano testnet',
        ticker: 'TEST',
        url: 'https://developers.cardano.org/',
        logo: null,
      ),
    );

    // print("testcoin.fingerprint:${testcoin.fingerprint}");
    // print("testcoin.assetId:${testcoin.assetId}");
    expect(
        testcoin.fingerprint, 'asset1cvmyrfrc7lpht2hcjwr9lulzyyjv27uxh3kcz0');
    expect(testcoin.assetId, testcoin.policyId,
        reason: 'if no assetName, assetId is just policyId');
    expect(testcoin.name, '');
    expect(testcoin.metadata?.decimals, 0);
    expect(testcoin.isADA, false);
    expect(testcoin.isNativeToken, true);
  });

  test('testLovelacePseudoAsset', () {
    // print("lovelacePseudoAsset.fingerprint:${lovelacePseudoAsset.fingerprint}");
    // print("lovelacePseudoAsset.assetId:${lovelacePseudoAsset.assetId}");
    // print("lovelacePseudoAsset.name:${lovelacePseudoAsset.name}");
    expect(lovelacePseudoAsset.fingerprint,
        'asset1cgv8ghtns4cwwprrekqu24zmz9p3t927uet8n8');
    expect(lovelacePseudoAsset.assetId, lovelacePseudoAsset.assetName,
        reason: 'if no policyId, assetId is just assetName hex');
    expect(lovelacePseudoAsset.name, 'lovelace');
    expect(lovelacePseudoAsset.metadata?.decimals, 6);
    expect(lovelacePseudoAsset.isADA, true);
    expect(lovelacePseudoAsset.isNativeToken, false);
  });

  test('testDudecoinAsset', () {
    final dudecoin = CurrencyAsset(
      policyId: '12345678901234567890123456789012345678901234567890123456',
      assetName: str2hex.encode('dude'),
      quantity: '777',
      initialMintTxHash: 'baba',
      metadata: CurrencyAssetMetadata(
        name: 'DudeCoin',
        description: 'The coin abides',
        ticker: 'DUDE',
        url: 'https://dude.abide.org/',
        logo: null,
      ),
    );

    //print("testcoin.fingerprint:${dudecoin.fingerprint}");
    //print("testcoin.assetId:${dudecoin.assetId}");
    //print("testcoin.assetName:${dudecoin.assetName}");
    expect(
        dudecoin.fingerprint, 'asset167jdqhflz5xjeqhy5esrmg2j7uwv3ghxlqsgv7');
    expect(dudecoin.assetId, '${dudecoin.policyId}${dudecoin.assetName}');
    expect(dudecoin.name, 'dude');
    expect(dudecoin.metadata?.decimals, 0);
    expect(dudecoin.isADA, false);
    expect(dudecoin.isNativeToken, true);
  });

  test('exploreDartFusedCodecs', () {
    final Codec<String, String> str2hex = utf8.fuse(HEX);
    // ignore: prefer_const_declarations
    final string1 = 'myName1234XYZ';
    final hex1 = str2hex.encode(string1);
    //print("hex1:$hex1");
    expect(hex1, HEX.encode(utf8.encode(string1)));
    expect(hex1, '6d794e616d653132333458595a');
    final string2 = str2hex.inverted.encode(hex1);
    expect(string2, utf8.decode(HEX.decode(hex1)));
    expect(string2, string1);
  });

  test('calculateFingerprint1', () {
    final fingerPrint = calculateFingerprint(
      policyId: '7eae28af2208be856f7a119668ae52a49b73725e326dc16579dcc373',
      assetNameHex: '',
    );
    expect(fingerPrint, 'asset1rjklcrnsdzqp65wjgrg55sy9723kw09mlgvlc3');
  });
  test('calculateFingerprint2', () {
    final fingerPrint = calculateFingerprint(
      policyId: '7eae28af2208be856f7a119668ae52a49b73725e326dc16579dcc37e',
      assetNameHex: '',
    );
    expect(fingerPrint, 'asset1nl0puwxmhas8fawxp8nx4e2q3wekg969n2auw3');
  });
  test('calculateFingerprint3', () {
    final fingerPrint = calculateFingerprint(
      policyId: '1e349c9bdea19fd6c147626a5260bc44b71635f398b67c59881df209',
      assetNameHex: '',
    );
    expect(fingerPrint, 'asset1uyuxku60yqe57nusqzjx38aan3f2wq6s93f6ea');
  });
  test('calculateFingerprint4', () {
    final fingerPrint = calculateFingerprint(
      policyId: '7eae28af2208be856f7a119668ae52a49b73725e326dc16579dcc373',
      assetNameHex: '504154415445',
    );
    expect(fingerPrint, 'asset13n25uv0yaf5kus35fm2k86cqy60z58d9xmde92');
  });
  test('calculateFingerprint5', () {
    final fingerPrint = calculateFingerprint(
      policyId: '1e349c9bdea19fd6c147626a5260bc44b71635f398b67c59881df209',
      assetNameHex: '504154415445',
    );
    expect(fingerPrint, 'asset1hv4p5tv2a837mzqrst04d0dcptdjmluqvdx9k3');
  });
  test('calculateFingerprint6', () {
    final fingerPrint = calculateFingerprint(
      policyId: '1e349c9bdea19fd6c147626a5260bc44b71635f398b67c59881df209',
      assetNameHex: '7eae28af2208be856f7a119668ae52a49b73725e326dc16579dcc373',
    );
    expect(fingerPrint, 'asset1aqrdypg669jgazruv5ah07nuyqe0wxjhe2el6f');
  });
  test('calculateFingerprint7', () {
    final fingerPrint = calculateFingerprint(
      policyId: '7eae28af2208be856f7a119668ae52a49b73725e326dc16579dcc373',
      assetNameHex: '1e349c9bdea19fd6c147626a5260bc44b71635f398b67c59881df209',
    );
    expect(fingerPrint, 'asset17jd78wukhtrnmjh3fngzasxm8rck0l2r4hhyyt');
  });
  test('calculateFingerprint8', () {
    final fingerPrint = calculateFingerprint(
      policyId: '7eae28af2208be856f7a119668ae52a49b73725e326dc16579dcc373',
      assetNameHex:
          '0000000000000000000000000000000000000000000000000000000000000000',
    );
    expect(fingerPrint, 'asset1pkpwyknlvul7az0xx8czhl60pyel45rpje4z8w');
  });
}
