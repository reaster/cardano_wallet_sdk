// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:pinenacl/encoding.dart';
import 'package:test/test.dart';
import 'my_api_key_auth.dart';

///
/// insure documented tests are actually working code.
///
void main() {
  final ADA = 1000000;
  final interceptor = MyApiKeyAuthInterceptor();
  final mnemonic =
      "alpha desert more credit sad balance receive sand someone correct used castle present bar shop borrow inmate estate year flip theory recycle measure silk"
          .split(' ');
  final toAddress = ShelleyAddress.fromBech32(
      'addr_test1qpsmv09c74c6s0r5tzru9flgyaksn782gqt5plrca9rc5xexngwdkqgqcvjtzmz624d6efz67ysf3597k24uyzqg5ctsvc54s8');

  group('payment -', () {
    test('send 3 ADA from walley to wallet 1', () async {
      final formatter = AdaFormattter.compactCurrency();
      final w1Addr2 =
          "addr_test1qqwncl938qg3sf46z8n878z26fnq426ttyarv3hk58keyzpxngwdkqgqcvjtzmz624d6efz67ysf3597k24uyzqg5ctsq32vnr";
      final w1Addr3 =
          "addr_test1qqda55x4jf75h9qqmne0aj62hksm6lsscqg5k7r3u3emtzfxngwdkqgqcvjtzmz624d6efz67ysf3597k24uyzqg5ctspcyv85";
      final w1Addr4 =
          "addr_test1qrf6r5df3v4p43f5ncyjgtwmajnasvw6zath6wa7226jxcfxngwdkqgqcvjtzmz624d6efz67ysf3597k24uyzqg5ctsw3hqzt";
      final lovelace = 3 * ADA;
      final builder = WalletBuilder()
        ..networkId = NetworkId.testnet
        ..testnetAdapterKey = interceptor.apiKey
        ..mnemonic = mnemonic;
      final createResult = await builder.buildAndSync();
      if (createResult.isOk()) {
        var walley = createResult.unwrap();
        final toAddress = ShelleyAddress.fromBech32(w1Addr2);
        final sendResult = await walley.sendAda(
          toAddress: toAddress,
          lovelace: lovelace,
          fee: 169000,
          ttl: 41180968 * 2,
        );

        sendResult.when(
          ok: (tx) => print(
              "${formatter.format(lovelace)} sent to ${toAddress.toBech32().substring(0, 16)}... with ${formatter.format(tx.body.fee)} lovelace fee"),
          err: (err) => print("Funds not sent. Error: ${err}"),
        );
      } else {
        print("error creating wallet: ${createResult.unwrapErr()}");
      }
    }); //, skip: "invalid format");
  });
}

  /*
{
  "body" : {
    "inputs" : [ {
      "transactionId" : "d65a6fdb484f4984cb982d4a4f3cba04e8e64feceec1891c63ea7c97ffe9458e",
      "index" : 1
    } ],
    "outputs" : [ {
      "address" : "addr_test1qqwncl938qg3sf46z8n878z26fnq426ttyarv3hk58keyzpxngwdkqgqcvjtzmz624d6efz67ysf3597k24uyzqg5ctsq32vnr",
      "value" : {
        "coin" : 2000000,
        "multiAssets" : null
      }
    }, {
      "address" : "addr_test1qr94pw040yeq5x75g38jnsjg95rv6xy4jyttedukatlpd2424kyuyck0xp0a7n7rah0gxj5mq3zdrc6xnaqph967c2kqja24jq",
      "value" : {
        "coin" : 995663806,
        "multiAssets" : [ ]
      }
    } ],
    "fee" : 168097,
    "ttl" : 41180968,
    "mint" : null,
    "metadataHash" : null,
    "validityStartInterval" : 0
  },
  "witnessSet" : null,
  "metadata" : null
}  

[{0: [[h'D65A6FDB484F4984CB982D4A4F3CBA04E8E64FECEEC1891C63EA7C97FFE9458E', 1]], 
  1: [[h'001D3C7CB138111826BA11E67F1C4AD2660AAB4B593A3646F6A1ED9208269A1CDB0100C324B16C5A555BACA45AF12098D0BEB2ABC20808A617', 2000000], 
      [h'00CB50B9F579320A1BD4444F29C2482D06CD18959116BCB796EAFE16AAAAAD89C262CF305FDF4FC3EDDE834A9B0444D1E3469F401B975EC2AC', 995663806]], 
  2: 168097, 
  3: 41180968
 }, 
 {0: [[h'F94431A84C877CAC81092CCA3448219808111398021A2C3DBB30BA5BE289EC5B', 
       h'43B43C33619852EB4CA45573EAC05C62A32557E5FF78D2A7B0AF3B47BAE2B77CA82CB02BD03CB6CD2DC416DE24ED9560B2AFB5C78E46A4DF02A4B67CA2AA280C']]
 }, 
 null
]
*/
