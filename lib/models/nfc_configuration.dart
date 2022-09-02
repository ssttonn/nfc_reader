abstract class NFCConfiguration{
  Map<String,dynamic> toJson();
}

class IosNfcConfiguration extends NFCConfiguration{
  final String defaultAlertMessage;
  final String successAlertMessage;
  final bool invalidateAfterFirstRead;
  IosNfcConfiguration({this.defaultAlertMessage = "Hold your iPhone near the item to learn more about it.", this.successAlertMessage = "NFC tag found",this.invalidateAfterFirstRead = false});

  @override
  Map<String, dynamic> toJson() {
   return {
      "defaultAlertMessage": defaultAlertMessage,
      "defaultSuccessMessage": successAlertMessage,
      "invalidateAfterFirstRead": invalidateAfterFirstRead
    };
  }
}