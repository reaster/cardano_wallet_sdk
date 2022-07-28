// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

// import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:hex/hex.dart';
import 'package:oxidized/oxidized.dart';
import '../../asset/asset.dart';
import '../../transaction/model/bc_tx.dart';
import '../../transaction/model/bc_tx_ext.dart';
import '../../transaction/tx_builder.dart';
import '../../wallet/wallet.dart';
import '../../util/ada_types.dart';
import '../../address/shelley_address.dart';
import '../../transaction/coin_selection.dart';
import '../../blockchain/blockchain_adapter.dart';
import '../../hd/hd_account.dart';
import '../../hd/hd_derivation_chain.dart';
import './read_only_wallet_impl.dart';

///
/// Build transactional wallet by combining features of HdAccount, TxBuilder and
/// ReadOnlyWallet.
///
class WalletImpl extends ReadOnlyWalletImpl implements Wallet {
  @override
  final HdAccount account;
  final CoinSelectionAlgorithm coinSelectionFunction;
  //final Map<ShelleyAddress, ShelleyAddressKit> _addressCache = {};
  // final logger = Logger();

  /// Normaly WalletFactory is used to build a wallet and call this method.
  WalletImpl({
    required this.account,
    required String walletName,
    required BlockchainAdapter blockchainAdapter,
    this.coinSelectionFunction = largestFirst,
  }) : super(
            stakeAddress: account.stakeAddress,
            walletName: walletName,
            blockchainAdapter: blockchainAdapter);

  @override
  ShelleyReceiveKit get firstUnusedReceiveAddress =>
      account.unusedReceiveAddresses(
          usedCallback: isUsedAddress, beyondUsedOffset: 1)[0];

  /// Find signing key for spend or change address.
  @override
  Map<ShelleyAddress, ShelleyUtxoKit> findSigningKeyForUtxos(
          {required Set<ShelleyAddress> utxos}) =>
      account.signableAddresses(utxos: utxos, usedCallback: isUsedAddress);

  @override
  ShelleyReceiveKit get firstUnusedChangeAddress =>
      account.unusedReceiveAddresses(
          role: changeRole,
          usedCallback: isUsedAddress,
          beyondUsedOffset: 1)[0];

  /// return true if the address has not been used before
  bool isUsedAddress(ShelleyAddress address) =>
      addresses.toSet().contains(address);

  @override
  Future<Result<BcTransaction, String>> submitTransaction({
    required BcTransaction tx,
  }) async {
    final submitResult =
        await blockchainAdapter.submitTransaction(tx.serialize);
    if (submitResult.isErr()) return Err(submitResult.unwrapErr());
    return Ok(tx);
  }

  @override
  Future<Result<BcTransaction, String>> sendAda({
    required AbstractAddress toAddress,
    required int lovelace,
    int ttl = 0,
    int fee = 0,
    bool logTxHex = false,
    bool logTx = false,
  }) async {
    final txResult = await buildSpendTransaction(
      toAddress: toAddress,
      lovelace: lovelace,
      ttl: ttl,
      fee: fee,
    );
    if (txResult.isErr()) {
      return Err(txResult.unwrapErr());
    }
    if (logTxHex) {
      print("tx hex: ${HEX.encode(txResult.unwrap().serialize)}");
    }
    if (logTx) {
      print("tx: ${txResult.unwrap().toJson}");
    }
    final sendResult = submitTransaction(
      tx: txResult.unwrap(),
    );
    return sendResult;
  }

  @override
  Future<Result<BcTransaction, String>> buildSpendTransaction({
    required AbstractAddress toAddress,
    required int lovelace,
    int ttl = 0,
    int fee = 0,
  }) async {
    if (lovelace > balance) {
      return Err('insufficient balance');
    }
    if (toAddress.addressType != AddressType.base) {
      return Err('only base shelley addresses currently supported');
    }
    if (toAddress is ShelleyAddress) {
      if (toAddress.hrp != 'addr' && toAddress.hrp != 'addr_test') {
        return Err(
            "not a valid shelley external addresses, expecting 'addr' or 'addr_test' prefix");
      }
    }
    //coin selection:
    //TODO handle edge-case where fee adjustment requires input recalculation.
    const Coin maxFeeGuess = 200000; //0.2 ADA
    final inputsResult = await coinSelectionFunction(
      unspentInputsAvailable: unspentTransactions,
      spendRequest:
          FlatMultiAsset(fee: maxFeeGuess, assets: {lovelaceHex: lovelace}),
      ownedAddresses: addresses.toSet(),
    );
    if (inputsResult.isErr()) return Err(inputsResult.unwrapErr().message);
    //use builder to build ShelleyTransaction
    //final pair = hdWallet.accountKeys();
    final builder = TxBuilder()
      ..inputs(inputsResult.unwrap().inputs)
      ..spendRequest(FlatMultiAsset(fee: fee, assets: {lovelaceHex: lovelace}))
      //..value(BcValue(coin: lovelace, multiAssets: []))
      ..toAddress(toAddress)
      ..wallet(this) //contains sign key & verify key
      ..blockchainAdapter(blockchainAdapter)
      ..changeAddress(firstUnusedChangeAddress)
      ..ttl(ttl);
    // ..fee(fee);
    final txResult = await builder.buildAndSign();
    if (txResult.isOk() && !txResult.unwrap().verify) {
      return Err('transaction validation failed');
    }
    return txResult;
  }

  @override
  bool get readOnly => false;
}

// Yorio Wallet interface for reference:

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
