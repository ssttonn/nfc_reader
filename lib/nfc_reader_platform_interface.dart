import 'package:nfc_reader/models/nfc_configuration.dart';
import 'package:nfc_reader/models/nfc_tag.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'nfc_reader_method_channel.dart';

abstract class NfcReaderPlatform extends PlatformInterface {
  /// Constructs a NfcReaderPlatform.
  NfcReaderPlatform() : super(token: _token);

  static final Object _token = Object();

  static NfcReaderPlatform _instance = MethodChannelNfcReader();

  /// The default instance of [NfcReaderPlatform] to use.
  ///
  /// Defaults to [MethodChannelNfcReader].
  static NfcReaderPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NfcReaderPlatform] when
  /// they register themselves.
  static set instance(NfcReaderPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> isNFCAvailable() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<NFCTag> scanNFCNDefTag({NFCConfiguration? configuration}) {
    throw UnimplementedError('scanNFCNDefTag() has not been implemented.');
  }

  Future<NFCTag> scanNFCTag({NFCConfiguration? configuration}) {
    throw UnimplementedError('scanNFCTag() has not been implemented.');
  }

  void finishCurrentSession({String? errorMessage}) {
    throw UnimplementedError(
        'finishCurrentSession() has not been implemented.');
  }
}
