#import "NfcReaderPlugin.h"
#if __has_include(<nfc_reader/nfc_reader-Swift.h>)
#import <nfc_reader/nfc_reader-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "nfc_reader-Swift.h"
#endif

@implementation NfcReaderPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftNfcReaderPlugin registerWithRegistrar:registrar];
}
@end
