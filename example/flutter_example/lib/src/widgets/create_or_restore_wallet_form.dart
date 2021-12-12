// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import './ada_shape_maker.dart';

///
/// Create read-only wallet form. All biz logic passed in via functions.
///
class CreateOrRestoreWalletForm extends StatefulWidget {
  final String mnemonic;
  final String walletName;
  final bool isNew;
  final bool Function(String s) isWalletNameUnique;
  final bool Function(String s) isMnemonicUnique;
  final void Function(
          BuildContext context, String walletName, List<String> mnemonic)
      doCreateWallet;
  final void Function(BuildContext context) doCancel;

  const CreateOrRestoreWalletForm({
    Key? key,
    String? suggestedMnemonic,
    String? suggestedWalletName,
    required this.isNew,
    required this.isWalletNameUnique,
    required this.isMnemonicUnique,
    required this.doCreateWallet,
    required this.doCancel,
  })  : mnemonic = suggestedMnemonic ?? '',
        walletName = suggestedWalletName ?? '',
        super(key: key);

  @override
  _CreateOrRestoreWalletFormState createState() =>
      _CreateOrRestoreWalletFormState();
}

class _CreateOrRestoreWalletFormState extends State<CreateOrRestoreWalletForm> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController walletNameController;
  late TextEditingController mnemonicController;
  late String submitButtonText;
  late String dialogTitleText;
  late String recoveryPhraseHandlingText;

  String walletName = '';
  String mnemonic = '';

  @override
  void initState() {
    super.initState();
    walletName = widget.walletName;
    walletNameController = TextEditingController(text: widget.walletName);
    if (widget.isNew && widget.mnemonic.isEmpty) {
      mnemonic = WalletBuilder.generateNewMnemonic().join(' ');
    } else {
      mnemonic = widget.mnemonic;
    }
    mnemonicController = TextEditingController(text: mnemonic);
    submitButtonText = widget.isNew ? 'Create' : 'Restore';
    dialogTitleText = widget.isNew ? 'Create New Wallet' : 'Restore Wallet';
    recoveryPhraseHandlingText =
        'WARNING: The only way to restore this wallet is to keep a copy of this recoverey phrase in a safe, private location!';
  }

  @override
  void dispose() {
    walletNameController.dispose();
    mnemonicController.dispose();
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
                child: Text(dialogTitleText,
                    style: Theme.of(context).textTheme.headline5),
              ),
              const SizedBox(height: 24),
              buildWalletName(),
              const SizedBox(height: 24),
              if (widget.isNew)
                Center(
                  child: Text(recoveryPhraseHandlingText,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1!
                          .apply(color: Colors.red)),
                ),
              if (widget.isNew) const SizedBox(height: 24),
              buildStakeMnemonicTextField(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    child: Text(submitButtonText),
                    onPressed: () {
                      //print('StakeMnemonic: ${mnemonicController.text}');
                      final isValid = formKey.currentState?.validate() ?? false;
                      setState(() {});
                      if (isValid) {
                        widget.doCreateWallet(
                            context, walletName, mnemonic.split(' '));
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

  Widget buildStakeMnemonicTextField() => TextFormField(
        maxLines: null,
        onChanged: (value) => setState(() => mnemonic = value),
        validator: (value) {
          final result = validMnemonic(phrase: value ?? '');
          if (result.isErr()) {
            debugPrint(result.unwrapErr());
            return result.unwrapErr();
          }
          if (!widget.isMnemonicUnique(mnemonic)) {
            return "wallet for this mnemonic already exists";
          }
          return null; //valid
        },
        controller: mnemonicController,
        decoration: InputDecoration(
          hintText: '24-words seperated by spaces',
          labelText: 'Recoverey Phrase',
          prefixIcon: const Icon(Icons.security),
          suffixIcon: mnemonicController.text.isEmpty
              ? Container(width: 0)
              : IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'copy to clipboard',
                  onPressed: () {
                    Clipboard.setData(
                            ClipboardData(text: mnemonicController.text))
                        .then((_) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                              Text("Recoverey phrase copied to clipboard")));
                    });
                  },
                ),
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.go,
        autofocus: kIsWeb,
      );

  Widget buildWalletName() => TextFormField(
        onChanged: (value) => setState(() => walletName = value),
        validator: (value) {
          if (!widget.isWalletNameUnique(walletName)) {
            return 'name is already in use';
          } else if (walletName.isEmpty) {
            return 'wallet name required';
          } else {
            return null; //valid
          }
        },
        controller: walletNameController,
        decoration: InputDecoration(
          hintText: 'Personalized Name...',
          labelText: 'Wallet Name',
          prefixIcon: const Icon(Icons.contacts),
          errorText: null,
          suffixIcon: walletNameController.text.isEmpty
              ? Container(width: 0)
              : IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'remove text',
                  onPressed: () {
                    walletNameController.clear();
                    walletName = '';
                  },
                ),
          border: const OutlineInputBorder(),
        ),
      );
}
