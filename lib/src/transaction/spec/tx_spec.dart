//import 'package:cardano_wallet_sdk/src/asset/asset.dart';
// import 'package:built_collection/built_collection.dart';
import 'package:hex/hex.dart';
import 'dart:convert';
import 'package:cbor/cbor.dart' as cbor;

///
/// translation from java: https://github.com/bloxbean/cardano-client-lib/tree/master/src/main/java/com/bloxbean/cardano/client/transaction/spec
///
class TxAsset {
  final String name;
  final int value;

  TxAsset({required this.name, required this.value});

  ///name is stored in hex in ledger. Try Hex decode first. If fails, try string.getBytes (used in mint transaction from client)
  List<int> getNameAsBytes() {
    try {
      return name.startsWith('0x') ? HEX.decode(name.substring(2)) : HEX.decode(name);
    } catch (e) {
      return utf8.encode(name);
    }
  }
}

class TxMultiAsset {
  final String policyId;
  final List<TxAsset> assets;

  TxMultiAsset({required this.policyId, required this.assets});

  void serialize(cbor.MapBuilder multiAssetMap) {
    final mb = cbor.MapBuilder.builder();
    for (TxAsset asset in assets) {
      mb.writeString(asset.name); //key
      mb.writeInt(asset.value);
    }
    multiAssetMap.writeString(policyId); //key
    multiAssetMap.addBuilderOutput(mb.getData());
  }

  static TxMultiAsset deserialize(Map multiAssetsMap, String key) {
    List<TxAsset> assets = [];
    String policyId = '';
    // final data = codec2.getDecodedData()!;
    // ByteString keyBS = (ByteString) key;
    // String policyId = (HEX.encode(keyBS.getBytes()));

    // Map assetsMap = (Map) multiAssetsMap.get(key);
    // for(DataItem assetKey: assetsMap.getKeys()) {
    //     ByteString assetNameBS = (ByteString)assetKey;
    //     UnsignedInteger assetValueUI = (UnsignedInteger)(assetsMap.get(assetKey));

    //     String name = HEX.encode(assetNameBS.getBytes());
    //     assets.add(TxAsset(name:name, value:assetValueUI.getValue()));
    // }
    return TxMultiAsset(policyId: policyId, assets: assets);
  }
}
