import 'package:nfc_reader/models/nfc_configuration.dart';
import 'package:nfc_reader/models/nfc_tag.dart';

import 'nfc_reader_platform_interface.dart';

class NfcReader {
  static final NfcReader _instance = NfcReader._internal();

  NfcReader._internal();
  factory NfcReader() {
    return _instance;
  }

  Future<bool> isNFCAvailable() {
    return NfcReaderPlatform.instance.isNFCAvailable();
  }

  Future<NFCTag> scanNFCNDefTag({NFCConfiguration? configuration}) {
    return NfcReaderPlatform.instance
        .scanNFCNDefTag(configuration: configuration);
  }
}
