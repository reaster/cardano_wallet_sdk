// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:hex/hex.dart';
import 'package:oxidized/oxidized.dart';
import '../../wallet/wallet.dart';
import '../../util/ada_types.dart';
import '../../address/hd_wallet.dart';
import '../../address/shelley_address.dart';
import '../../transaction/coin_selection.dart';
import '../../transaction/spec/shelley_spec.dart';
import '../../transaction/spec/shelley_tx_logic.dart';
import '../../transaction/transaction_builder.dart';
import '../../blockchain/blockchain_adapter.dart';
import './read_only_wallet_impl.dart';

///
/// Build transactional wallet by combining features of HdWallet, TransactionBuilder and
/// ReadOnlyWallet.
///
class WalletImpl extends ReadOnlyWalletImpl implements Wallet {
  @override
  final HdWallet hdWallet;
  @override
  final int accountIndex;
  @override
  final Bip32KeyPair addressKeyPair;
  final CoinSelectionAlgorithm coinSelectionFunction;
  final Map<ShelleyAddress, ShelleyAddressKit> _addressCache = {};
  // final logger = Logger();

  /// Normaly WalletFactory is used to build a wallet and call this method.
  WalletImpl({
    required BlockchainAdapter blockchainAdapter,
    required ShelleyAddress stakeAddress,
    required this.addressKeyPair,
    required String walletName,
    required this.hdWallet,
    this.accountIndex = defaultAddressIndex,
    this.coinSelectionFunction = largestFirst,
  }) : super(
            blockchainAdapter: blockchainAdapter,
            stakeAddress: stakeAddress,
            walletName: walletName);

  @override
  ShelleyAddress get firstUnusedReceiveAddress => hdWallet
      .deriveUnusedBaseAddressKit(
          networkId: networkId, unusedCallback: isUnusedAddress)
      .address;

  /// Find signing key for spend or change address.
  @override
  Bip32KeyPair? findKeyPairForChangeAddress({
    required ShelleyAddress address,
    int account = defaultAccountIndex,
    int index = defaultAddressIndex,
  }) {
    if (_addressCache.isEmpty) {
      final spends = hdWallet.buildAddressKitCache(
          usedSet: addresses.toSet(),
          account: account,
          role: paymentRole,
          index: index,
          networkId: networkId,
          beyondUsedOffset: HdWallet.maxOverrun);
      for (var kit in spends) {
        _addressCache[kit.address] = kit;
      }
      final change = hdWallet.buildAddressKitCache(
          usedSet: addresses.toSet(),
          account: account,
          role: changeRole,
          index: index,
          networkId: networkId,
          beyondUsedOffset: HdWallet.maxOverrun);
      for (var kit in change) {
        _addressCache[kit.address] = kit;
      }
    }
    final kit = _addressCache[address];
    return kit == null
        ? null
        : Bip32KeyPair(signingKey: kit.signingKey, verifyKey: kit.verifyKey);
  }

  @override
  ShelleyAddress get firstUnusedChangeAddress => hdWallet
      .deriveUnusedBaseAddressKit(
        role: changeRole,
        networkId: networkId,
        unusedCallback: isUnusedAddress,
      )
      .address;
  // to duplicate cardano-client-lib we always return the 1st paymentAddress.
  // ShelleyAddress get firstUnusedChangeAddress => hdWallet
  //     .deriveUnusedBaseAddressKit(
  //       role: paymentRole,
  //       networkId: networkId,
  //       unusedCallback: alwaysUnused,
  //     )
  //     .address;

  /// return true if the address has not been used before
  bool isUnusedAddress(ShelleyAddress address) =>
      !addresses.toSet().contains(address);

  @override
  Future<Result<ShelleyTransaction, String>> submitTransaction({
    required ShelleyTransaction tx,
  }) async {
    final submitResult =
        await blockchainAdapter.submitTransaction(tx.serialize);
    if (submitResult.isErr()) return Err(submitResult.unwrapErr());
    return Ok(tx);
  }

  @override
  Future<Result<ShelleyTransaction, String>> sendAda({
    required ShelleyAddress toAddress,
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
      print("tx: ${txResult.unwrap().toJson(prettyPrint: true)}");
    }
    final sendResult = submitTransaction(
      tx: txResult.unwrap(),
    );
    return sendResult;
  }

  @override
  Future<Result<ShelleyTransaction, String>> buildSpendTransaction({
    required ShelleyAddress toAddress,
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
    if (toAddress.hrp != 'addr' && toAddress.hrp != 'addr_test') {
      return Err(
          "not a valid shelley external addresses, expecting 'addr' or 'addr_test' prefix");
    }
    //coin selection:
    //TODO handle edge-case where fee adjustment requires input recalculation.
    const Coin maxFeeGuess = 200000; //0.2 ADA
    final inputsResult = await coinSelectionFunction(
      unspentInputsAvailable: unspentTransactions,
      outputsRequested: [MultiAssetRequest.lovelace(lovelace + maxFeeGuess)],
      ownedAddresses: addresses.toSet(),
    );
    if (inputsResult.isErr()) return Err(inputsResult.unwrapErr().message);
    //use builder to build ShelleyTransaction
    //final pair = hdWallet.accountKeys();
    final builder = TransactionBuilder()
      ..inputs(inputsResult.unwrap().inputs)
      ..value(ShelleyValue(coin: lovelace, multiAssets: []))
      ..toAddress(toAddress)
      ..wallet(this) //contains sign key & verify key
      ..blockchainAdapter(blockchainAdapter)
      ..changeAddress(firstUnusedChangeAddress)
      ..ttl(ttl)
      ..fee(fee);
    final txResult = await builder.buildAndSign();
    if (txResult.isOk() && !txResult.unwrap().verify) {
      return Err('transaction validation failed');
    }
    return txResult;
  }

  @override
  bool get readOnly => false;

  @override
  Bip32KeyPair get rootKeyPair => Bip32KeyPair(
      signingKey: hdWallet.rootSigningKey, verifyKey: hdWallet.rootVerifyKey);
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
