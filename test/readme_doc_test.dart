import 'package:bip32_ed25519/bip32_ed25519.dart';
import 'package:cardano_wallet_sdk/src/address/hd_wallet.dart';
import 'package:cardano_wallet_sdk/src/address/shelley_address.dart';
import 'package:cardano_wallet_sdk/src/network/network_id.dart';
import 'package:cardano_wallet_sdk/src/wallet/impl/wallet_factory_impl.dart';
import 'package:cardano_wallet_sdk/src/wallet/read_only_wallet.dart';
import 'package:cardano_wallet_sdk/src/wallet/wallet.dart';
import 'package:cardano_wallet_sdk/src/util/ada_types.dart';
import 'package:oxidized/oxidized.dart';
import 'package:test/test.dart';

import 'my_api_key_auth.dart';

///
/// insure documented tests are actually working code.
///
void main() {
  final testnet = NetworkId.testnet;
  final interceptor = MyApiKeyAuthInterceptor();
  final walletFactory = ShelleyWalletFactory(authInterceptor: interceptor, networkId: testnet);
  final mnemonic =
      "rude stadium move tumble spice vocal undo butter cargo win valid session question walk indoor nothing wagon column artefact monster fold gallery receive just"
          .split(' ');

  group('wallet management -', () {
    test('walletFactory from policy-id', () {
      String myPolicyId = interceptor.apiKey;
      final walletFactory = ShelleyWalletFactory.fromKey(key: myPolicyId, networkId: testnet);
      expect(walletFactory, isNotNull);
    });
    test('Create a read-only wallet using a staking address', () async {
      final bechAddr = 'stake_test1uqevw2xnsc0pvn9t9r9c7qryfqfeerchgrlm3ea2nefr9hqp8n5xl';
      var address = ShelleyAddress.fromBech32(bechAddr);
      Result<ReadOnlyWallet, String> result = await walletFactory.createReadOnlyWallet(stakeAddress: address);
      result.when(
        ok: (w) => print("${w.walletName}: ${w.balance}"),
        err: (err) => print("Error: ${err}"),
      );
    });
    test('Restore existing wallet using 24 word mnemonic', () async {
      //List<String> mnemonic = 'rude stadium move...gallery receive just'.split(' ');
      Result<Wallet, String> result = await walletFactory.createWalletFromMnemonic(mnemonic: mnemonic);
      if (result.isOk()) {
        var w = result.unwrap();
        print("${w.walletName}: ${w.balance}");
      }
    });
    test('Update existing wallet', () async {
      var result = await walletFactory.createWalletFromMnemonic(mnemonic: mnemonic, load: false);
      Wallet wallet = result.unwrap();
      // expect(wallet.stakeAddress.toBech32(), 'stake_test1uzgkwv76l9sgct5xq4gldxe6g93x39yvjh4a7wu8hk2ufeqx3aar6');
      Coin old = wallet.balance;
      var result2 = await walletFactory.updateWallet(wallet: wallet);
      result2.when(
        ok: (_) => print("old:$old ADA, new: ${wallet.balance} ADA"),
        err: (err) => print("Error: ${err}"),
      );
    });
    test('Create a new 24 word mnemonic', () {
      List<String> mnemonic = walletFactory.generateNewMnemonic();
      print("mnemonic: ${mnemonic.join(' ')}");
    });
  });
}
