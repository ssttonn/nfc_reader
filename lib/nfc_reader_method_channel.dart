import 'dart:convert';
import 'dart:developer';
import 'dart:io';

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

  @override
  Future<NFCTag> scanNFCNDefTag({NFCConfiguration? configuration}) async {
    late NFCConfiguration defaultConfiguration;
    if (Platform.isIOS) {
      defaultConfiguration = IosNfcScanConfiguration();
    } else {
      //TODO implement android configurations
    }
    final result = await methodChannel.invokeMethod(
        "scanNDEFTag", {...(configuration ?? defaultConfiguration).toJson()});
    return NFCTag.fromJson(jsonDecode(result));
  }

  @override
  Future<NFCTag> scanNFCTag({NFCConfiguration? configuration}) async {
    late NFCConfiguration defaultConfiguration;
    if (Platform.isIOS) {
      defaultConfiguration = IosNfcScanConfiguration();
    } else {
      //TODO implement android configurations
    }
    final result = await methodChannel.invokeMethod(
        "scanTag", {...(configuration ?? defaultConfiguration).toJson()});
    inspect(jsonDecode(result));
    return NFCTag.fromJson(jsonDecode(result));
  }

  @override
  void finishCurrentSession({String? errorMessage}) async {
    return await methodChannel.invokeMethod("finishCurrentSession",
        {if (errorMessage != null) "errorMessage": errorMessage});
  }
}
