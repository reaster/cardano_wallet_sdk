import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_example/src/widgets/ada_shape_maker.dart';

///
/// Create read-only wallet form. All biz logic passed in via functions.
///
class CreateOrRestoreWalletForm extends StatefulWidget {
  final String mnemonic;
  final String walletName;
  final bool isNew;
  final bool Function(String s) isWalletNameUnique;
  final bool Function(String s) isMnemonicUnique;
  final void Function(BuildContext context, String walletName, String mnemonic)
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

  String walletName = '';
  String mnemonic = '';

  @override
  void initState() {
    super.initState();
    walletName = widget.walletName;
    walletNameController = TextEditingController(text: widget.walletName);
    mnemonic = widget.mnemonic;
    mnemonicController = TextEditingController(text: widget.mnemonic);
  }

  @override
  void dispose() {
    walletNameController.dispose();
    mnemonicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
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
              child: Text("Create Read-Only Wallet",
                  style: Theme.of(context).textTheme.headline5),
            ),
            const SizedBox(height: 24),
            buildWalletName(),
            const SizedBox(height: 24),
            buildStakeMnemonicTextField(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  child: const Text('Submit'),
                  onPressed: () {
                    //print('StakeMnemonic: ${mnemonicController.text}');
                    final isValid = formKey.currentState?.validate() ?? false;
                    setState(() {});
                    if (isValid) {
                      widget.doCreateWallet(context, walletName, mnemonic);
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
      );

  Widget buildStakeMnemonicTextField() => TextFormField(
        onChanged: (value) => setState(() => mnemonic = value),
        validator: (value) {
          final result = validMnemonic(phrase: value ?? '');
          if (result.isErr()) {
            print(result.unwrapErr());
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
          labelText: 'Mnemonic Phrase',
          prefixIcon: const Icon(Icons.how_to_vote),
          // icon: Icon(Icons.mail),
          suffixIcon: mnemonicController.text.isEmpty
              ? Container(width: 0)
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    mnemonicController.clear();
                    mnemonic = '';
                  },
                ),
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.go,
        autofocus: true,
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
                  onPressed: () {
                    walletNameController.clear();
                    walletName = '';
                  },
                ),
          border: const OutlineInputBorder(),
        ),
      );
}
