import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:flutter_example/src/wallet/wallet_controller.dart';
import 'package:flutter_example/src/wallet/wallet_service.dart';
import 'package:riverpod/riverpod.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_service.dart';

///
/// This is just one of many ways services, controllers and providers can be
/// orginized. Having all the state management declarations in one file
/// simplfies the app at the expnse of modularity and testability.
///
final _settingsService = SettingsService();
final settingsController = SettingsController(_settingsService);
final settingsProvider = Provider<SettingsController>((ref) => settingsController);

final walletStateNotifier = WalletStateNotifier(WalletService(settingService: _settingsService));
final walletProvider = StateNotifierProvider<WalletStateNotifier, List<ReadOnlyWallet>>((ref) => walletStateNotifier);
