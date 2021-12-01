// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';

Future<void> asyncAlertDialog(
  BuildContext context,
  String title,
  String content,
) async {
  return await showDialog(
      context: context,
      builder: (dialogContext) {
        final titleTheme = Theme.of(dialogContext)
            .textTheme
            .subtitle1!
            .apply(color: Colors.red);
        final bodyTheme = Theme.of(dialogContext).textTheme.bodyText1;

        return AlertDialog(
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(title, style: titleTheme),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(content, style: bodyTheme),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              child: const Center(child: Text('Ok')),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      });
}
