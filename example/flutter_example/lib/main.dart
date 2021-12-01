// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/providers.dart';
import 'src/app.dart';

void main() async {
  // Load the user's preferred theme while the splash screen is displayed.
  // This prevents a sudden theme change when the app is first displayed.
  await settingsController.loadSettings();

  // Run the app and add a ProviderScope to hold the providers.
  runApp(const ProviderScope(
    child: MyApp(),
  ));
}
