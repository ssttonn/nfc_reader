import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nfc_reader/models/nfc_configuration.dart';
import 'package:nfc_reader/models/nfc_tag.dart';

import 'nfc_reader_platform_interface.dart';

/// An implementation of [NfcReaderPlatform] that uses method channels.
class MethodChannelNfcReader extends NfcReaderPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('nfc_reader');

  @override
  Future<bool> isNFCAvailable() async {
    bool? isNFCAvailable =
        await methodChannel.invokeMethod<bool>('isNFCAvailable');
    if (isNFCAvailable == null) {
      return false;
    }
    return isNFCAvailable;
  }

  /// [scanNFCNDefTag] method for
  @override
  Future<NFCDefTag> scanNFCNDefTag({NFCConfiguration? configuration}) async {
    final result = await methodChannel.invokeMethod("scanNDEFTag",
        configuration == null ? {} : {...configuration.toJson()});
    return NFCDefTag.fromJson(jsonDecode(result));
  }

  @override
  Future<NFCTag> scanNFC({required String type}) async {
    final result = await methodChannel.invokeMethod("scan", {"type": type});
    return NFCDefTag.fromJson(jsonDecode(result));
  }
}
