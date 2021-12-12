// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:riverpod/riverpod.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_service.dart';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import './wallet/wallet_state_notifier.dart';
import './wallet/wallet_service.dart';

///
/// Declare services, controllers and providers globally.
///
/// Note: This is just one of many ways services, controllers and providers can be
/// orginized. Having all the state management declarations in one file
/// simplfies the app at the expnse of modularity and testability.
///
final _settingsService = SettingsService();
final settingsController = SettingsController(_settingsService);
final settingsProvider =
    Provider<SettingsController>((ref) => settingsController);

final walletStateNotifier =
    WalletStateNotifier(WalletService(settingService: _settingsService));
final walletProvider =
    StateNotifierProvider<WalletStateNotifier, List<ReadOnlyWallet>>(
        (ref) => walletStateNotifier);
