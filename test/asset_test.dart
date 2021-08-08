import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:cardano_wallet_sdk/src/util/codec.dart';
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
      initialMintTxHash: 'abfda1ba36b9ee541516fda311319f7bdb3e3928776c2982d2f027f3e8fa54c7',
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
    expect(testcoin.fingerprint, 'asset1cvmyrfrc7lpht2hcjwr9lulzyyjv27uxh3kcz0');
    expect(testcoin.assetId, testcoin.policyId, reason: 'if no assetName, assetId is just policyId');
    expect(testcoin.name, '');
    expect(testcoin.metadata?.decimals, 0);
    expect(testcoin.isADA, false);
    expect(testcoin.isNativeToken, true);
  });

  test('testLovelacePseudoAsset', () {
    // print("lovelacePseudoAsset.fingerprint:${lovelacePseudoAsset.fingerprint}");
    // print("lovelacePseudoAsset.assetId:${lovelacePseudoAsset.assetId}");
    // print("lovelacePseudoAsset.name:${lovelacePseudoAsset.name}");
    expect(lovelacePseudoAsset.fingerprint, 'asset1cgv8ghtns4cwwprrekqu24zmz9p3t927uet8n8');
    expect(lovelacePseudoAsset.assetId, lovelacePseudoAsset.assetName, reason: 'if no policyId, assetId is just assetName hex');
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
    expect(dudecoin.fingerprint, 'asset167jdqhflz5xjeqhy5esrmg2j7uwv3ghxlqsgv7');
    expect(dudecoin.assetId, '${dudecoin.policyId}${dudecoin.assetName}');
    expect(dudecoin.name, 'dude');
    expect(dudecoin.metadata?.decimals, 0);
    expect(dudecoin.isADA, false);
    expect(dudecoin.isNativeToken, true);
  });

  test('exploreDartFusedCodecs', () {
    final Codec<String, String> str2hex = utf8.fuse(HEX);
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
      assetNameHex: '0000000000000000000000000000000000000000000000000000000000000000',
    );
    expect(fingerPrint, 'asset1pkpwyknlvul7az0xx8czhl60pyel45rpje4z8w');
  });

//   final json = '''
// ["active",false,"controlled_amount","301407406","rewards_sum","0","withdrawals_sum","0","reserves_sum","0","treasury_sum","0","withdrawable_amount","0","pool_id",null]
// ["block","7ee9e04258a467dc29560541f7ae28eb2f4713503455e0a3b3493303f5822ef3","block_height",2607964,"slot",27421587,"index",2,"output_amount",[["unit","lovelace","quantity","899662398"]],"fees","168801","deposit","0","size",289,"invalid_before",null,"invalid_hereafter","27428780","utxo_count",3,"withdrawal_count",0,"mir_cert_count",0,"delegation_count",0,"stake_cert_count",0,"pool_update_count",0,"pool_retire_count",0,"asset_mint_or_burn_count",0]
// ["time",1621790803,"height",2607964,"hash","7ee9e04258a467dc29560541f7ae28eb2f4713503455e0a3b3493303f5822ef3","slot",27421587,"epoch",133,"epoch_slot",335187,"slot_leader","pool1ek7tv04ccm5mhg04r9qz4pcxf8lfm55lax0k67unp3nksukvfuy","size",1209,"tx_count",3,"output","1488607235","fees","520351","block_vrf","vrf_vk1a3h24z97a0g3jmdcf9fwj5xmfa90gschzmsswxuy87m0y6gjl6xqv2s0c7","previous_block","a157050b5ea51448bdd0bf34786bda5d0e69ba5eb6e79206fd6facd7f1a0051a","next_block","d4f2cb8483b3016ddc8c2721c51f3055bb8f9a01251544eb9acd841110538d5d","confirmations",131236]
// ["inputs",[["address","addr_test1qp680xknwamupzcuf9jwngrr6k69vzuwyjs87z583k74gafxngwdkqgqcvjtzmz624d6efz67ysf3597k24uyzqg5ctsx5kkgg","amount",[["unit","lovelace","quantity","899831199"]]]],"outputs",[["address","addr_test1qrzz3zfnzwddmq0end8a89ztrf22sh82rjkxvxsvuw84xnr8dre5um4gaa8mz8dmk9xg99qzeav3eudktywafk77d3lqp2knkj","amount",[["unit","lovelace","quantity","200000000"]]],["address","addr_test1qpjxnqxq0jc5el00l9sh9pk86khvgmrp68f39trlaz07lg3xngwdkqgqcvjtzmz624d6efz67ysf3597k24uyzqg5ctsc64yhe","amount",[["unit","lovelace","quantity","699662398"]]]]]
// ["block","9b796002bb26ce6e1933d9bff4bb30cd1ab37284645b642a5d768d4f5a49ec46","block_height",2608002,"slot",27422752,"index",2,"output_amount",[["unit","lovelace","quantity","199155995"]],"fees","168801","deposit","0","size",289,"invalid_before",null,"invalid_hereafter","27429838","utxo_count",3,"withdrawal_count",0,"mir_cert_count",0,"delegation_count",0,"stake_cert_count",0,"pool_update_count",0,"pool_retire_count",0,"asset_mint_or_burn_count",0]
// ["time",1621791968,"height",2608002,"hash","9b796002bb26ce6e1933d9bff4bb30cd1ab37284645b642a5d768d4f5a49ec46","slot",27422752,"epoch",133,"epoch_slot",336352,"slot_leader","pool1kcu63rqem85pkakgqh76733p7shdfuptwjtrhf9vfd6rg4ky6dg","size",1241,"tx_count",3,"output","778205688","fees","521759","block_vrf","vrf_vk1kf2wc3h4zq2pt7pf6y0yfr4dnkvsmezf5wrxdlkp52c66k6wpggsa3zrx4","previous_block","fc0213330f879136967b77a56c2694810ec4cf58925e9e6cfafdd61aa53690c7","next_block","dad0b2b5fa69371acd70603f396075784976ebf6fca2017a4417dd099555ac90","confirmations",131198]
// ["inputs",[["address","addr_test1qqltwrdj339cx6l98ze8zveldczmrg0cr0u7k7f6gyadae3xngwdkqgqcvjtzmz624d6efz67ysf3597k24uyzqg5ctsh243r9","amount",[["unit","lovelace","quantity","199324796"]]]],"outputs",[["address","addr_test1qprvz9hf0cwfafm3xykfjfy4ggec0wf06r9x0xnv3xg4j3m8dre5um4gaa8mz8dmk9xg99qzeav3eudktywafk77d3lqhqwn0n","amount",[["unit","lovelace","quantity","100000000"]]],["address","addr_test1qzyr4eu2x32yf8mu09f4kk54u9m8yvgsrlqlevap07kx6cpxngwdkqgqcvjtzmz624d6efz67ysf3597k24uyzqg5cts25vfyf","amount",[["unit","lovelace","quantity","99155995"]]]]]
// ["block","ba8e13b4ff18c8758f57cc2559d2086d4b19c16f60a012113ca04e5841a75cf8","block_height",2609552,"slot",27468459,"index",0,"output_amount",[["unit","lovelace","quantity","4968231291"],["unit","6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7","quantity","2"],["unit","6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7","quantity","958"]],"fees","172585","deposit","0","size",365,"invalid_before",null,"invalid_hereafter","27475578","utxo_count",3,"withdrawal_count",0,"mir_cert_count",0,"delegation_count",0,"stake_cert_count",0,"pool_update_count",0,"pool_retire_count",0,"asset_mint_or_burn_count",0]
// ["time",1621837675,"height",2609552,"hash","ba8e13b4ff18c8758f57cc2559d2086d4b19c16f60a012113ca04e5841a75cf8","slot",27468459,"epoch",133,"epoch_slot",382059,"slot_leader","pool1rnsw42f2q0u9fc32ttxy9l085n736jxz07lvwutz63wpyef03zh","size",1316,"tx_count",3,"output","5181296169","fees","525499","block_vrf","vrf_vk1r3udcqqdrey05yw4hn52y82u9a4g3yjmgu9avm99wqlxxst2s3lqdmp0w7","previous_block","189deb1306f94b8b0eeab38bd16d0611585b5cc2c3c0060f270049c308cd5144","next_block","cfb860ea6da2cc9c77d916e1ae95b753e2cd1a9da1b3dff41fa5ed69437095d1","confirmations",129648]
//   ''';
}
