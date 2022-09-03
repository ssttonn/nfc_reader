import 'package:nfc_reader/models/nfc_configuration.dart';
import 'package:nfc_reader/models/nfc_tag.dart';

import 'nfc_reader_platform_interface.dart';

class NFCTagReader {
  static final NFCTagReader _instance = NFCTagReader._internal();

  NFCTagReader._internal();
  static NFCTagReader instance = _instance;

  Future<bool> isNFCAvailable() {
    return NfcReaderPlatform.instance.isNFCAvailable();
  }

  Future<NFCTag> scanNFCNDefTag({NFCConfiguration? configuration}) {
    return NfcReaderPlatform.instance
        .scanNFCNDefTag(configuration: configuration);
  }

  Future<NFCTag> scanTag({NFCConfiguration? configuration}) {
    return NfcReaderPlatform.instance.scanNFCTag(configuration: configuration);
  }

  Future writeTag(
      {List<NFCDefPayload> payloads = const [],
      NFCConfiguration? configuration}) {
    return NfcReaderPlatform.instance
        .writeNFCTag(payloads: payloads, configuration: configuration);
  }

  void finishCurrentSession({String? errorMessage}) {
    return NfcReaderPlatform.instance
        .finishCurrentSession(errorMessage: errorMessage);
  }
}

class NFCDefReader {}
