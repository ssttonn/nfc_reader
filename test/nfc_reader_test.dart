import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_reader/nfc_reader.dart';
import 'package:nfc_reader/nfc_reader_platform_interface.dart';
import 'package:nfc_reader/nfc_reader_method_channel.dart';


void main() {
  final NfcReaderPlatform initialPlatform = NfcReaderPlatform.instance;

  test('$MethodChannelNfcReader is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNfcReader>());
  });

  test('getPlatformVersion', () async {
    NfcReader nfcReaderPlugin = NfcReader();
  
    expect(await nfcReaderPlugin.isNFCAvailable(), '42');
  });
}
