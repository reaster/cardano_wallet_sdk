import 'package:blockfrost/blockfrost.dart';
import 'package:cardano_wallet_sdk/src/network/cardano_network.dart';
import 'package:cardano_wallet_sdk/src/util/ada_formatter.dart';
import 'package:cardano_wallet_sdk/src/wallet/public_wallet.dart';
import 'package:cardano_wallet_sdk/src/wallet/wallet_factory.dart';
import 'package:test/test.dart';

void main() {
  final wallet1 = 'stake_test1uqnf58xmqyqvxf93d3d92kav53d0zgyc6zlt927zpqy2v9cyvwl7a';
  final wallet2 = 'stake_test1uz425a6u2me7xav82g3frk2nmxhdujtfhmf5l275dr4a5jc3urkeg';
  final wallet3 = 'stake_test1upnk3u6wd65w7na3rkamznyzjspv7kgu7xm9j8w5m00xcls39m99d';
  final wallet4 = 'stake_test1uqhwfumjye2t99ekdq02njm0wsdz84pmd0h2cxrg4napshs0uedxa';
  final formatter = AdaFormattter.compactCurrency();
  final walletFactory = ShelleyWalletFactory(authInterceptor: MyApiKeyAuthInterceptor());
  group('PublicWallet -', () {
    test('test create testnet wallet 1', () async {
      final result = await walletFactory.createPublicWallet(networkId: NetworkId.testnet, stakeAddress: wallet1);
      result.when(
          ok: (wallet) {
            print("Wallet(name: ${wallet.name}, balance: ${formatter.format(wallet.balance)})");
            wallet.addresses().forEach((addr) {
              print(addr.toBech32());
            });
            wallet.transactions.forEach((tx) {
              print("$tx");
            });
            wallet.currencies.forEach((key, value) {
              print("$key: ${key == 'lovelace' ? formatter.format(value) : value}");
            });
            expect(wallet.balance, equals(wallet.currencies['lovelace']));
          },
          err: (err) => print(err));
      final wallet = walletFactory.byStakeAddress(wallet1);
      final update = await walletFactory.updatePublicWallet(wallet: wallet as PublicWalletImpl);
      expect(false, update.unwrap());
    });
    test('create testnet wallet 2', () async {
      final result2 = await walletFactory.createPublicWallet(networkId: NetworkId.testnet, stakeAddress: wallet2, name: 'Wallet 2');
      result2.when(
          ok: (wallet) {
            print("Wallet(name: ${wallet.name}, balance: ${formatter.format(wallet.balance)})");
            wallet.addresses().forEach((addr) {
              print(addr.toBech32());
            });
            wallet.transactions.forEach((tx) {
              print("$tx");
            });
            wallet.currencies.forEach((key, value) {
              print("$key: ${key == 'lovelace' ? formatter.format(value) : value}");
            });
            expect(wallet.balance, equals(wallet.currencies['lovelace']));
          },
          err: (err) => print(err));
    });
    test('create testnet wallet 3', () async {
      final result3 = await walletFactory.createPublicWallet(networkId: NetworkId.testnet, stakeAddress: wallet3, name: 'Wallet 3');
      result3.when(
          ok: (wallet) {
            print("Wallet(name: ${wallet.name}, balance: ${formatter.format(wallet.balance)})");
            wallet.addresses().forEach((addr) {
              print(addr.toBech32());
            });
            wallet.transactions.forEach((tx) {
              print("$tx");
            });
            wallet.currencies.forEach((key, value) {
              final asset = wallet.assets[key];
              print("Currency: ${asset?.symbol ?? key}: ${asset?.isADA ?? false ? formatter.format(value) : value}");
            });
            expect(wallet.balance, equals(wallet.currencies['lovelace']));
          },
          err: (err) => print(err));
    });
    test('create testnet wallet 4', () async {
      final result4 = await walletFactory.createPublicWallet(networkId: NetworkId.testnet, stakeAddress: wallet4, name: 'Wallet 4');
      result4.when(
          ok: (wallet) {
            print("Wallet(name: ${wallet.name}, balance: ${formatter.format(wallet.balance)})");
            wallet.addresses().forEach((addr) {
              print(addr.toBech32());
            });
            wallet.transactions.forEach((tx) {
              print("$tx");
            });
            wallet.currencies.forEach((key, value) {
              print("$key: ${key == 'lovelace' ? formatter.format(value) : value}");
            });
            expect(wallet.balance, equals(wallet.currencies['lovelace']));
          },
          err: (err) => print(err));
    });
  });
}
