# Flutter Example App

This Flutter app demonstrates using the Cardano Wallet SDK to manage wallets, 
send payments, handle input validation, process errors, list transactions and 
verify them in a blockchain browser. 
It is a multi-platform app that has been tested on iOS, Android, macOS and the web.

<div align="center">
    <img style="margin:5px;" src="https://github.com/reaster/cardano_wallet_sdk/raw/main/example/flutter_example/screenshots/FlutterSDK_Drawer_iPadPro9_7-inch.png" width="200px"</img> 
    <img style="margin:5px;" src="https://github.com/reaster/cardano_wallet_sdk/raw/main/example/flutter_example/screenshots/FlutterSDK_ListWallets_iPodTouch7thGen.png" width="100px"</img> 
    <img style="margin:5px;" src="https://github.com/reaster/cardano_wallet_sdk/raw/main/example/flutter_example/screenshots/FlutterSDK_Sliders_MacOS.png" width="200px"</img> 
    <img style="margin:5px;" src="https://github.com/reaster/cardano_wallet_sdk/raw/main/example/flutter_example/screenshots/FlutterSDK_DarkMode_MacOS.png" width="200px"</img> 
</div>


## Getting Started

This project requires that a testnet policy-id key from [BlockFrost](https://blockfrost.io/) 
be placed in the `assets/res` project folder (the same file required to run the integration tests):

```
flutter_example/assets/res/blockfrost_project_id.txt
```

For more general help getting started with Flutter, view the
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Implementation

This project started with the Flutter 2.5 skeleton template:
```
flutter create -t skeleton flutter_example
```
Which produced a multi-platform,  [internationalization-ready](https://flutter.dev/docs/development/accessibility-and-localization/internationalization), [multi-page](https://docs.flutter.dev/development/ui/navigation) master-detail starting app. This code was combined with [Riverpod](https://riverpod.dev) to create a [reactive state management template app](https://github.com/reaster/skeleton_riverpod). Finally, adding the [Cardano Wallet SDK](https://pub.dev/packages/cardano_wallet_sdk) produced a robust, multi-account Cardano wallet app. 


