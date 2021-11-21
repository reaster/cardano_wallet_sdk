import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_example/src/widgets/ada_shape_maker.dart';

///
/// Create read-only wallet form. All biz logic passed in via functions.
///
class CreateReadOnlyWalletForm extends StatefulWidget {
  final String address;
  final String walletName;
  final bool Function(String s) isWalletNameUnique;
  final bool Function(String s) isAddressUnique;
  final void Function(BuildContext context, String walletName, String address)
      doCreateWallet;
  final void Function(BuildContext context) doCancel;

  const CreateReadOnlyWalletForm({
    Key? key,
    String? suggestedAddress,
    String? suggestedWalletName,
    required this.isWalletNameUnique,
    required this.isAddressUnique,
    required this.doCreateWallet,
    required this.doCancel,
  })  : address = suggestedAddress ?? '',
        walletName = suggestedWalletName ?? '',
        super(key: key);

  @override
  _CreateReadOnlyWalletFormState createState() =>
      _CreateReadOnlyWalletFormState();
}

class _CreateReadOnlyWalletFormState extends State<CreateReadOnlyWalletForm> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController walletNameController;
  late TextEditingController addressController;

  String walletName = '';
  String address = '';

  @override
  void initState() {
    super.initState();
    walletName = widget.walletName;
    walletNameController = TextEditingController(text: widget.walletName);
    address = widget.address;
    addressController = TextEditingController(text: widget.address);
  }

  @override
  void dispose() {
    walletNameController.dispose();
    addressController.dispose();
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
            buildStakeAddressTextField(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  child: const Text('Submit'),
                  onPressed: () {
                    //print('StakeAddress: ${addressController.text}');
                    final isValid = formKey.currentState?.validate() ?? false;
                    setState(() {});
                    if (isValid) {
                      widget.doCreateWallet(context, walletName, address);
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

  Widget buildStakeAddressTextField() => TextFormField(
        onChanged: (value) => setState(() => address = value),
        validator: (value) {
          //stake_test1upnk3u6wd65w7na3rkamznyzjspv7kgu7xm9j8w5m00xcls39m99d
          final hrpPrefixes = ['stake_test'];
          final result = validBech32(
              bech32: value ?? '',
              hrpPrefixes: hrpPrefixes,
              dataPartRequiredLength: 53);
          if (result.isErr()) {
            print(result.unwrapErr());
            return result.unwrapErr();
          }
          if (!widget.isAddressUnique(address)) {
            return "wallet for this address already exists";
          }
          print("valid");
          return null;
        },
        controller: addressController,
        decoration: InputDecoration(
          hintText: 'stake_test1uqhw...edxa',
          labelText: 'Stake Address',
          prefixIcon: const Icon(Icons.how_to_vote),
          // icon: Icon(Icons.mail),
          suffixIcon: addressController.text.isEmpty
              ? Container(width: 0)
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    addressController.clear();
                    address = '';
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
            print("valid");
            return null;
          }
        },
        controller: walletNameController,
        //onSubmitted: (value) => setState(() => this.walletName = value),
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
