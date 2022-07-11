// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:bip32_ed25519/api.dart';
import '../address/shelley_address.dart';
import '../crypto/mnemonic.dart';
import '../crypto/mnemonic_english.dart';
import '../transaction/model/bc_abstract.dart';
import '../crypto/shelley_key_derivation.dart';
import '../network/network_id.dart';
import 'derivation_chain.dart';

///
/// These classes implement the Cardano version of HD (Hierarchical Deterministic)
/// Wallets which are used to generate a tree of cryptographic keys and addresses
/// from a single seed or master key in a reproducable way accross wallet vendors.
///
/// The Cardano CIP1852 adoption of the BIP32 tree path is as follows:
///     m / 1852' / 1815' / account' / role / index
///

///
/// All HD Wallet use-cases are (or will eventualy be) supported as specified here:
///
/// https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki#use-cases
///
enum HdUseCase {
  fullWalletSharing('m'),
  audits('N(m/*)'),
  perOfficeBalances("m/i'"),
  recurrentBToBTx("N(m/i'/0)"),
  unsecureMoneyReceiver("N(m/i'/0)");

  const HdUseCase(this.expression);
  final String expression;
}

///
/// Base Account class specifies a Network and at least one received address (Shelley or Byron).
///
abstract class HdAbstract {
  HdUseCase get useCase;
  NetworkId get network;
  AbstractAddress receiveAddress({int index = 0});
  //int get firstUnusedReceiveIndex => 0;
}

///
/// AddressReceiver is the simplest possible Account, containing a collection
/// of addresses (Shelley or Byron) that can receive Cardano assets.
///
class HdAddressReceiver extends HdAbstract {
  @override
  final HdUseCase useCase = HdUseCase.unsecureMoneyReceiver;
  @override
  final NetworkId network;
  final List<AbstractAddress> receiveAddresses;

  HdAddressReceiver({required this.receiveAddresses})
      : network = _extractNetwork(receiveAddresses) {
    if (receiveAddresses.isEmpty) {
      throw InvalidAccountError('at least one address must be provided');
    }
  }

  @override
  AbstractAddress receiveAddress({int index = 0}) => receiveAddresses[index];

  static NetworkId _extractNetwork(List<AbstractAddress> receiveAddresses) {
    final network = receiveAddresses[0].networkId;
    for (AbstractAddress addr in receiveAddresses) {
      if (addr.networkId != network) {
        throw InvalidAccountError(
            "Can't have mainnet and testnet addresses in the same account: $receiveAddresses");
      }
    }

    return network;
  }
}

///
/// Chain
abstract class HdAbstractAccount extends HdAbstract {
  ShelleyKeyDerivation get derivation;
  DerivationChain get chain;
  String get chainLabel;
}

/// Read-only Audit Account
class HdAudit extends HdAbstractAccount {
  @override
  final HdUseCase useCase = HdUseCase.audits;
  @override
  final NetworkId network;
  @override
  final ShelleyKeyDerivation derivation;
  final ShelleyKeyDerivation derivationInternal;
  @override
  final DerivationChain chain;
  late final Bip32VerifyKey publicStakeKey;
  final int accountIndex;

  HdAudit({
    required Bip32VerifyKey publicExternalKey,
    required Bip32VerifyKey publicInternalKey,
    required this.publicStakeKey,
    this.network = NetworkId.mainnet,
    this.accountIndex = 0,
  })  : chain = const DerivationChain(key: 'M', segments: []),
        derivation = ShelleyKeyDerivation(publicExternalKey),
        derivationInternal = ShelleyKeyDerivation(publicInternalKey);

  Bip32VerifyKey externalAddrPublicKey({int index = 0}) =>
      derivation.fromChain(chain.append(Segment(index: index)))
          as Bip32VerifyKey;

  Bip32VerifyKey internalAddrPublicKey({int index = 0}) =>
      derivationInternal.fromChain(chain.append(Segment(index: index)))
          as Bip32VerifyKey;

  ShelleyAddress baseAddress({int index = 0}) => ShelleyAddress.toBaseAddress(
      spend: externalAddrPublicKey(index: index),
      stake: publicStakeKey,
      networkId: network);

  ShelleyAddress changeAddress({int index = 0}) => ShelleyAddress.toBaseAddress(
      spend: internalAddrPublicKey(index: index),
      stake: publicStakeKey,
      networkId: network);

  @override
  AbstractAddress receiveAddress({int index = 0}) => spendAddress(index: index);

  @override
  String get chainLabel => "M/$accountIndex'";
}

/// Office Account
class HdAccount implements HdAbstractAccount {
  @override
  final HdUseCase useCase = HdUseCase.perOfficeBalances;
  // @override
  // final DerivationChain chainKey;
  @override
  final ShelleyKeyDerivation derivation;
  @override
  final NetworkId network;
  final int accountIndex;
  final Bip32SigningKey
      accountSigningKey; //Pvt key at account level m/1852'/1815'/x'
  @override
  final DerivationChain chain;
  late final Bip32VerifyKey publicStakeKey;

  HdAccount({
    required this.accountSigningKey,
    this.network = NetworkId.mainnet,
    this.accountIndex = 0,
  })  : chain = const DerivationChain(key: 'm', segments: []),
        // chainKey = DerivationChain(key: 'm', segments: [
        //   cip1852,
        //   cip1815,
        //   Segment(index: accountIndex, harden: true)
        // ]),
        derivation = ShelleyKeyDerivation(accountSigningKey) {
    publicStakeKey = derivation
        .fromChain(chain.append2(stakeRole, zeroSoft))
        .publicKey as Bip32VerifyKey;
  }

  Bip32SigningKey basePrivateKey({int index = 0}) =>
      derivation.fromChain(chain.append2(spendRole, Segment(index: index)))
          as Bip32SigningKey;

  Bip32SigningKey changePrivateKey({int index = 0}) =>
      derivation.fromChain(chain.append2(changeRole, Segment(index: index)))
          as Bip32SigningKey;

  Bip32SigningKey stakePrivateKey({int index = 0}) =>
      derivation.fromChain(chain.append2(stakeRole, Segment(index: index)))
          as Bip32SigningKey;

  @override
  AbstractAddress receiveAddress({int index = 0}) => baseAddress(index: index);

  ShelleyAddress baseAddress({int index = 0}) => ShelleyAddress.toBaseAddress(
      spend: basePrivateKey(index: index).verifyKey,
      stake: publicStakeKey,
      networkId: network);

  ShelleyAddress enterpriseScriptAddress({required BcAbstractScript script}) =>
      ShelleyAddress.enterpriseScriptAddress(
          script: script, networkId: network);

  ShelleyAddress scriptAddress({required BcAbstractScript script}) =>
      ShelleyAddress.toBaseScriptAddress(
          script: script, stake: publicStakeKey, networkId: network);

  //header: 0001....
  // public Address getBaseAddress(Script paymentKey, HdPublicKey delegationKey, Network networkInfo) throws CborSerializationException {
  //     if (paymentKey == null || delegationKey == null)
  //         throw new AddressRuntimeException("paymentkey and delegationKey cannot be null");

  //     byte[] paymentKeyHash = paymentKey.getScriptHash();
  //     byte[] delegationKeyHash = delegationKey.getKeyHash();

  //     byte headerType = 0b0001_0000;

  //     return getAddress(paymentKeyHash, delegationKeyHash, headerType, networkInfo, AddressType.Base);
  // }

  ShelleyAddress changeAddress({int index = 0}) => ShelleyAddress.toBaseAddress(
      spend: changePrivateKey(index: index).verifyKey,
      stake: publicStakeKey,
      networkId: network);

  ShelleyAddress enterpriseAddress({int index = 0}) =>
      ShelleyAddress.enterpriseAddress(
          spend: basePrivateKey(index: index).verifyKey, networkId: network);

  ShelleyAddress stakeAddress({int index = 0}) =>
      ShelleyAddress.toRewardAddress(spend: publicStakeKey, networkId: network);

  @override
  String get chainLabel => "m/1852'/1815'/$accountIndex'";
}

///
/// The HD master contains the master private key allowing it create any type of Account.
///
/// However, 99% of the time you'll just create a master using a mnemonic and get the
/// default account:
///
///   Account account = HdMaster.mnemonic(['head', 'guard',...]).account();
///
/// Unless specified, the default network is mainnet.
///
class HdMaster {
  final HdUseCase useCase = HdUseCase.fullWalletSharing;
  final DerivationChain chain = const DerivationChain(key: 'm', segments: [
    cip1852,
    cip1815,
  ]);
  final ShelleyKeyDerivation derivation;
  final NetworkId network;

  HdMaster({
    required this.derivation,
    this.network = NetworkId.mainnet,
  });

  HdMaster.entropy(Uint8List entropy, {NetworkId network = NetworkId.mainnet})
      : this(
            network: network,
            derivation: ShelleyKeyDerivation.entropy(entropy));

  HdMaster.entropyHex(String entropyHex,
      {NetworkId network = NetworkId.mainnet})
      : this(
            network: network,
            derivation: ShelleyKeyDerivation.entropyHex(entropyHex));

  // ignore: non_constant_identifier_names
  HdMaster.bech32(String root_sk, {NetworkId network = NetworkId.mainnet})
      : this(network: network, derivation: ShelleyKeyDerivation.rootX(root_sk));

  HdMaster.mnemonic(
    ValidMnemonicPhrase mnemonic, {
    LoadMnemonicWordsFunction loadWordsFunction = loadEnglishMnemonicWords,
    MnemonicLang lang = MnemonicLang.english,
    NetworkId network = NetworkId.mainnet,
  }) : this.entropyHex(
            mnemonicToEntropyHex(
                mnemonic: mnemonic,
                loadWordsFunction: loadWordsFunction,
                lang: lang),
            network: network);

  Bip32SigningKey get masterPrivateKey => derivation.root as Bip32SigningKey;

  /// Lookup and/or create an account if one doesn't exist.
  /// The default zero index will be used if not specified.
  /// Paths are generated using the "m/1852'/1815'/$index'" template.
  HdAccount account({int accountIndex = 0}) =>
      accountByPath(_acctPathTemplate(accountIndex));

  /// Look up an account based on it's path. Paths define the cryptocraphic key of the account
  /// from which all other account keys and addresses are derived.
  HdAccount accountByPath(String path) {
    final derivationPath = DerivationChain.fromPath(path);
    final accountKey = derivation.fromChain(derivationPath) as Bip32SigningKey;
    return HdAccount(
        accountSigningKey: accountKey,
        accountIndex: derivationPath.segments.last.index,
        network: network);
  }

  ///
  /// Audit for specific account index that can generate all internal (change) and external (spend) addresses.
  ///
  HdAudit audit({int accountIndex = 0}) {
    final chain = DerivationChain.fromPath(_acctPathTemplate(accountIndex));
    final ext = derivation.fromChain(chain.append(spendRole)).publicKey;
    final int = derivation.fromChain(chain.append(changeRole)).publicKey;
    final stake =
        derivation.fromChain(chain.append2(stakeRole, zeroSoft)).publicKey;
    return HdAudit(
      publicExternalKey: ext as Bip32VerifyKey,
      publicInternalKey: int as Bip32VerifyKey,
      publicStakeKey: stake as Bip32VerifyKey,
      network: network,
      accountIndex: accountIndex,
    );
  }

  // static const _defaultAcctPath = "m/1852'/1815'/0'";
  String _acctPathTemplate(int accountIndex) => "m/1852'/1815'/$accountIndex'";

  String get chainLabel => 'm';
}

class InvalidAccountError extends Error {
  final String message;
  InvalidAccountError(this.message);
  @override
  String toString() => message;
}
