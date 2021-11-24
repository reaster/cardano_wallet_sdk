import 'package:flutter/material.dart';

Future<void> asyncAlertDialog(
  BuildContext context,
  String title,
  String content,
) async {
  final titleTheme =
      Theme.of(context).textTheme.subtitle1!.apply(color: Colors.red);
  final bodyTheme = Theme.of(context).textTheme.bodyText1;
  return await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      content: Column(
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
      actions: [
        ElevatedButton(
          child: const Center(child: Text('Ok')),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}
