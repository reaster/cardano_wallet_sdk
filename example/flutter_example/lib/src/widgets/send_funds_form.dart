// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import '../providers.dart';
import './ada_shape_maker.dart';
import './alert_dialog.dart';

///
/// Create a send funds form. All biz logic passed in via functions.
///
// ignore: must_be_immutable
class SendFundsForm extends StatefulWidget {
  final Wallet wallet;
  ShelleyAddress? toAddress;
  int lovelace = 0;
  final void Function({
    required BuildContext context,
    required Wallet wallet,
    required ShelleyAddress toAddress,
    required int lovelace,
  }) doSendAda;
  final void Function(BuildContext context) doCancel;

  SendFundsForm({
    Key? key,
    required this.wallet,
    this.toAddress,
    this.lovelace = 0,
    required this.doSendAda,
    required this.doCancel,
  }) : super(key: key);

  @override
  _SendFundsFormState createState() => _SendFundsFormState();
}

class _SendFundsFormState extends State<SendFundsForm> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController toAddressController;
  late TextEditingController adaController;
  static const adaToLovelace = 1000000;
  String adaText = '';
  String toAddress = '';

  @override
  void initState() {
    super.initState();
    toAddress = widget.toAddress?.toBech32() ?? '';
    toAddressController = TextEditingController(text: toAddress);
    double initialAda = widget.lovelace / adaToLovelace;
    adaText = initialAda == 0.0 ? '' : '$initialAda';
    adaController = TextEditingController(text: adaText);
  }

  @override
  void dispose() {
    toAddressController.dispose();
    adaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: CustomPaint(
                  size: const Size(80, 80),
                  painter: AdaCustomPainter(color: Colors.blue[800]),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text("Send ADA",
                    style: Theme.of(context).textTheme.headline5),
              ),
              const SizedBox(height: 24),
              buildToAddressTextField(),
              const SizedBox(height: 24),
              buildAdaAmount(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    child: const Text('Send'),
                    onPressed: () {
                      debugPrint('Send ${toAddressController.text}');
                      final isValid = formKey.currentState?.validate() ?? false;
                      setState(() {});
                      if (isValid) {
                        final ada =
                            double.tryParse(validAda(ada: adaText).unwrap()) ??
                                0.0;
                        final lovelace = (ada * adaToLovelace).toInt();
                        final address = ShelleyAddress.fromBech32(toAddress);
                        widget.doSendAda(
                            context: context,
                            wallet: widget.wallet,
                            lovelace: lovelace,
                            toAddress: address);
                      }
                    },
                  ),
                  ElevatedButton(
                    child: const Text('Cancel'),
                    onPressed: () => widget.doCancel(context),
                  ),
                ],
              )
            ],
          ),
          // ),
          // ],
        ),
      );

  Widget buildToAddressTextField() => TextFormField(
        onChanged: (value) => setState(() => toAddress = value),
        validator: (value) {
          //addr_test1qrme7jnq9el49wndaty0nay09rqw7t8025ef9nlvl7qmufgxu2hyfhlkwuxupa9d5085eunq2qywy7hvmvej456flkns94xvlv
          final hrpPrefixes = ['addr_test'];
          final result = validBech32(
              bech32: value ?? '',
              hrpPrefixes: hrpPrefixes,
              dataPartRequiredLength: 98);
          if (result.isErr()) {
            return result.unwrapErr();
          }
          return null; //valid
        },
        controller: toAddressController,
        decoration: InputDecoration(
          hintText: 'addr_test1qrme7jnq9e...',
          labelText: 'To Address',
          prefixIcon: const Icon(Icons.send_sharp),
          suffixIcon: toAddressController.text.isEmpty
              ? Container(width: 0)
              : IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'remove text',
                  onPressed: () {
                    toAddressController.clear();
                    toAddress = '';
                  },
                ),
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.go,
        autofocus: kIsWeb,
      );

  Widget buildAdaAmount() => TextFormField(
        onChanged: (value) => setState(() => adaText = value),
        validator: (value) {
          if (value != null) {
            final result = validAda(ada: value);
            if (result.isErr()) {
              return result.unwrapErr();
            }
          }
          return null; //valid
        },
        controller: adaController,
        decoration: InputDecoration(
          hintText: '10.000000',
          labelText: 'ADA',
          prefixIcon: const Icon(Icons.contacts),
          errorText: null,
          suffixIcon: adaController.text.isEmpty
              ? Container(width: 0)
              : IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'clear',
                  onPressed: () {
                    adaController.clear();
                    adaText = '';
                  },
                ),
          border: const OutlineInputBorder(),
        ),
      );
}

/// Function to load SendFundsForm wrapped in a AlertDialog.
Future<void> openSendAdaForm(BuildContext context, Wallet wallet) async {
  late ShelleyAddress targetAddress;
  Coin lovelaceToSend = coinZero;
  final form = SendFundsForm(
    key: const Key('sendAdaForm'),
    wallet: wallet,
    toAddress: null,
    lovelace: 0,
    doSendAda: (
        {required BuildContext context,
        required Wallet wallet,
        required ShelleyAddress toAddress,
        required int lovelace}) {
      targetAddress = toAddress;
      lovelaceToSend = lovelace;
      Navigator.of(context).pop(true);
    },
    doCancel: (context) => Navigator.of(context).pop(false),
  );
  final formCompleted = await showDialog(
        context: context,
        builder: (context) => AlertDialog(content: form),
      ) ??
      false;
  if (formCompleted) {
    final result = await walletStateNotifier.sendAda(
      wallet: wallet,
      toAddress: targetAddress,
      lovelace: lovelaceToSend,
    );
    result.when(
      ok: (tx) {
        final message =
            'sent ${_formatter.format(lovelaceToSend)} to ${targetAddress.toBech32().substring(0, 30)}...';
        debugPrint(message);
        _showSnackBar(context, message);
      },
      err: (message) {
        debugPrint("error sending ada: $message");
        asyncAlertDialog(
            context,
            'Error sending ${_formatter.format(lovelaceToSend)} to ${targetAddress.toBech32().substring(0, 30)}...',
            message);
      },
    );
  }
}

final _formatter = AdaFormattter.compactCurrency();

void _showSnackBar(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
