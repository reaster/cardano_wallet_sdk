import 'package:cardano_wallet_sdk/src/address/shelley_address.dart';
import 'package:cardano_wallet_sdk/src/network/network_id.dart';
import 'package:cardano_wallet_sdk/src/util/ada_formatter.dart';
import 'package:cardano_wallet_sdk/src/wallet/impl/read_only_wallet_impl.dart';
import 'package:cardano_wallet_sdk/src/wallet/impl/wallet_factory_impl.dart';
import 'package:cardano_wallet_sdk/src/wallet/read_only_wallet.dart';
import 'package:cardano_wallet_sdk/src/wallet/wallet_factory.dart';
import 'package:test/test.dart';
import './my_api_key_auth.dart';
import 'package:cardano_wallet_sdk/src/asset/asset.dart';
import 'package:oxidized/oxidized.dart';

void main() {
  final wallet1 = 'stake_test1uqnf58xmqyqvxf93d3d92kav53d0zgyc6zlt927zpqy2v9cyvwl7a';
  final wallet2 = 'stake_test1uz425a6u2me7xav82g3frk2nmxhdujtfhmf5l275dr4a5jc3urkeg';
  final wallet3 = 'stake_test1upnk3u6wd65w7na3rkamznyzjspv7kgu7xm9j8w5m00xcls39m99d';
  final wallet4 = 'stake_test1uqhwfumjye2t99ekdq02njm0wsdz84pmd0h2cxrg4napshs0uedxa';

  final walletFactory = ShelleyWalletFactory(authInterceptor: MyApiKeyAuthInterceptor(), networkId: NetworkId.testnet);

  group('PublicWallet -', () {
    test('test create testnet wallet 1', () async {
      await testWallet(stakeAddress: wallet1, walletFactory: walletFactory);
    });
    test('create testnet wallet 2', () async {
      await testWallet(stakeAddress: wallet2, walletFactory: walletFactory, walletName: 'Wallet 2');
    });
    test('create testnet wallet 3', () async {
      await testWallet(stakeAddress: wallet3, walletFactory: walletFactory, walletName: 'Wallet 3');
    });
    test('create testnet wallet 4', () async {
      await testWallet(stakeAddress: wallet4, walletFactory: walletFactory, walletName: 'Wallet 4');
    });
    test('missing account', () async {
      final result = await testWallet(
          stakeAddress: 'stake1uy88uenysztnswv6u3cssgpamztc25q5wea703rnp50s4qq0ddctn',
          walletFactory: walletFactory,
          walletName: 'MIA');
      expect(true, result.isErr());
      print("ERROR: ${result.unwrapErr()}");
    });
    test('create mainnet wallet 8', () async {
      final wallet8 = 'stake1uy88uenysztnswv6u3cssgpamztc25q5wea703rnp50s4qq0ddctn';
      await testWallet(stakeAddress: wallet8, walletFactory: walletFactory, walletName: 'Fat Cat 8');
    }, skip: 'mainnet auth not working');
  });
}

final formatter = AdaFormattter.compactCurrency();

Future<Result<ReadOnlyWallet, String>> testWallet(
    {required String stakeAddress, required WalletFactory walletFactory, String? walletName}) async {
  final result = await walletFactory.createReadOnlyWallet(
      stakeAddress: ShelleyAddress.fromBech32(stakeAddress), walletName: walletName);
  bool error = false;
  result.when(
    ok: (wallet) {
      print("Wallet(name: ${wallet.walletName}, balance: ${formatter.format(wallet.balance)})");
      wallet.addresses.forEach((addr) {
        print(addr.toBech32());
      });
      wallet.transactions.forEach((tx) {
        print("$tx");
      });
      wallet.currencies.forEach((key, value) {
        print("$key: ${key == lovelaceHex ? formatter.format(value) : value}");
      });
      wallet.stakeAccounts.forEach((acct) {
        final ticker = acct.poolMetadata?.ticker ?? acct.poolMetadata?.name ?? acct.poolId!;
        acct.rewards.forEach((reward) {
          print("epoch: ${reward.epoch}, value: ${formatter.format(reward.amount)}, ticker: $ticker");
        });
      });
      final int calculatSum = wallet.calculatedBalance; //TODO figure out the math
      expect(wallet.balance, equals(calculatSum));
    },
    err: (err) {
      print(err);
      error = true;
      return Err(err);
    },
  );
  if (error) {
    return Err(result.unwrapErr());
  }
  final wallet = walletFactory.byStakeAddress(stakeAddress);
  final update = await walletFactory.updateWallet(wallet: wallet as ReadOnlyWalletImpl);
  expect(false, update.unwrap());
  return Ok(result.unwrap());
}
