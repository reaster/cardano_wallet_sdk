import 'dart:typed_data';

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:cardano_wallet_sdk/src/address/hd_wallet.dart';
import 'package:cardano_wallet_sdk/src/address/shelley_address.dart';
import 'package:cardano_wallet_sdk/src/transaction/transaction_builder.dart';
import 'package:cardano_wallet_sdk/src/wallet/wallet.dart';
import 'package:oxidized/oxidized.dart';

///
/// Build transactional wallet by combining features of HdWallet, TransactionBuilder and
/// ReadOnlyWallet.
///
class WalletImpl extends ReadOnlyWalletImpl implements Wallet {
  final HdWallet hdWallet;

  /// Normaly WalletFactory is used to build a wallet and call this method.
  /// TODO change seed to private key
  WalletImpl({
    required ShelleyAddress stakeAddress,
    required String walletName,
    required Uint8List seed,
  })  : hdWallet = HdWallet(seed: seed),
        super(stakeAddress: stakeAddress, walletName: walletName);

  @override
  ShelleyAddress get firstUnusedChangeAddress =>
      hdWallet.deriveUnusedBaseAddress(role: changeRole, networkId: networkId, unusedCallback: _isUnusedSpendAddress);

  @override
  ShelleyAddress get firstUnusedSpendAddress =>
      hdWallet.deriveUnusedBaseAddress(networkId: networkId, unusedCallback: _isUnusedChangeAddress);

  bool _isUnusedSpendAddress(ShelleyAddress address) => true; //TODO

  bool _isUnusedChangeAddress(ShelleyAddress address) => true;

  @override
  Future<Result<Transaction, String>> sendAda({required ShelleyAddress toAddress, required int lovelaceAmount}) async {
    if (lovelaceAmount > balance) {
      return Err('insufficient balance');
    }
    if (toAddress.addressType != AddressType.Base) {
      return Err('only base shelley addresses currently supported');
    }
    if (toAddress.hrp != 'addr' && toAddress.hrp != 'addr_test') {
      return Err("not a valid shelley external addresses, expecting 'addr' or 'addr_test' prefix");
    }
    final builder = TransactionBuilder().send(shelleyAddress: toAddress, lovelace: lovelaceAmount);
    //TODO calculate, fee, make change, sign and send
    return Err('not yet implmented');
  }

  @override
  Bip32KeyPair get rootKeyPair => Bip32KeyPair(privateKey: hdWallet.rootSigningKey, publicKey: hdWallet.rootVerifyKey);
}

// Yorio Wallet interface:

// id: string;

// networkId: NetworkId;

// walletImplementationId: WalletImplementationId;

// isHW: boolean;

// hwDeviceInfo: ?HWDeviceInfo;

// isReadOnly: boolean;

// provider: ?YoroiProvider;

// isEasyConfirmationEnabled: boolean;

// internalChain: AddressChain;

// externalChain: AddressChain;

// // note: currently not exposed to redux's store
// publicKeyHex: string;

// // note: exposed to redux's store but not in storage (as it can be derived)
// rewardAddressHex: ?string;

// // last known version the wallet has been opened on
// // note: Prior to v4.1.0, `version` was set upon wallet creation/restoration
// // and was never updated. Starting from v4.1.0, we instead store the
// // last version the wallet has been *opened* on, since this is the actual
// // relevant information we need to decide on whether migrations are needed.
// // Saved in storage but not exposed to redux's store.
// version: string;

// state: WalletState;

// isInitialized: boolean;

// transactionCache: TransactionCache;

// checksum: WalletChecksum;

// // =================== getters =================== //

// get internalAddresses(): Addresses;

// get externalAddresses(): Addresses;

// get isUsedAddressIndex(): Dict<boolean>;

// get numReceiveAddresses(): number;

// get transactions(): Dict<Transaction>;

// get confirmationCounts(): Dict<number>;

// // =================== create =================== //

// create(
//   mnemonic: string,
//   newPassword: string,
//   networkId: NetworkId,
//   implementationId: WalletImplementationId,
//   provider: ?YoroiProvider,
// ): Promise<string>;

// createWithBip44Account(
//   accountPublicKey: string,
//   networkId: NetworkId,
//   implementationId: WalletImplementationId,
//   hwDeviceInfo: ?HWDeviceInfo,
//   isReadOnly: boolean,
// ): Promise<string>;

// // ============ security & key management ============ //

// encryptAndSaveMasterKey(encryptionMethod: EncryptionMethod, masterKey: string, password?: string): Promise<void>;

// getDecryptedMasterKey(masterPassword: string, intl: IntlShape): Promise<string>;

// enableEasyConfirmation(masterPassword: string, intl: IntlShape): Promise<void>;

// changePassword(masterPassword: string, newPassword: string, intl: IntlShape): Promise<void>;

// // =================== subscriptions =================== //

// subscribe(handler: (Wallet) => any): void;
// subscribeOnTxHistoryUpdate(handler: () => any): void;

// // =================== synch =================== //

// doFullSync(): Promise<Dict<Transaction>>;

// tryDoFullSync(): Promise<Dict<Transaction> | null>;

// // =================== state/UI =================== //

// canGenerateNewReceiveAddress(): boolean;

// generateNewUiReceiveAddressIfNeeded(): boolean;

// generateNewUiReceiveAddress(): boolean;

// // =================== persistence =================== //

// // TODO: type
// toJSON(): any;

// restore(data: any, walletMeta: WalletMeta): Promise<void>;

// // =================== tx building =================== //

// // not exposed to wallet manager, consider removing
// getChangeAddress(): string;

// getAllUtxosForKey(utxos: Array<RawUtxo>): Promise<Array<AddressedUtxo>>;

// getAddressingInfo(address: string): any;

// asAddressedUtxo(utxos: Array<RawUtxo>): Array<AddressedUtxo>;

// getDelegationStatus(): Promise<DelegationStatus>;

// createUnsignedTx<T>(
//   utxos: Array<RawUtxo>,
//   receiver: string,
//   tokens: SendTokenList,
//   defaultToken: DefaultTokenEntry,
//   serverTime: Date | void,
//   metadata: Array<JSONMetadata> | void,
// ): Promise<ISignRequest<T>>;

// signTx<T>(signRequest: ISignRequest<T>, decryptedMasterKey: string): Promise<SignedTx>;

// createDelegationTx<T>(
//   poolRequest: void | string,
//   valueInAccount: BigNumber,
//   utxos: Array<RawUtxo>,
//   defaultAsset: DefaultAsset,
//   serverTime: Date | void,
// ): Promise<{
//   signRequest: ISignRequest<T>,
//   totalAmountToDelegate: MultiToken,
// }>;

// createVotingRegTx<T>(
//   utxos: Array<RawUtxo>,
//   catalystPrivateKey: string,
//   decryptedKey: string | void,
//   serverTime: Date | void,
// ): Promise<ISignRequest<T>>;

// createWithdrawalTx<T>(
//   utxos: Array<RawUtxo>,
//   shouldDeregister: boolean,
//   serverTime: Date | void,
// ): Promise<ISignRequest<T>>;

// signTxWithLedger<T>(request: ISignRequest<T>, useUSB: boolean): Promise<SignedTx>;

// // =================== backend API =================== //

// checkServerStatus(): Promise<ServerStatusResponse>;

// submitTransaction(signedTx: string): Promise<[]>;

// getTxsBodiesForUTXOs(request: TxBodiesRequest): Promise<TxBodiesResponse>;

// fetchUTXOs(): Promise<Array<RawUtxo>>;

// fetchAccountState(): Promise<AccountStateResponse>;

// fetchPoolInfo(request: PoolInfoRequest): Promise<PoolInfoResponse>;

// fetchTokenInfo(request: TokenInfoRequest): Promise<TokenInfoResponse>;

// fetchFundInfo(): Promise<FundInfoResponse>;
