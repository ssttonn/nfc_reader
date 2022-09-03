import 'dart:developer';

/// [ErrorMessageType] for IOS NFC scan popup
enum ErrorMessageType {
  unknownError,
  sessionError,
  sessionTimeoutError,
  connectTagError,
  queryNDefStatusError,
  readNDefError,
  parsingDataError
}

enum IOSPollingOption { iso14443, iso15693, iso18092 }

abstract class NFCConfiguration {
  Map<String, dynamic> toJson();
}

class IosNfcScanConfiguration extends NFCConfiguration {
  final String defaultAlertMessage; // message used during scanning progress
  final String
      successAlertMessage; // message used after nfc tag is completely fetched
  final bool invalidateAfterFirstRead;
  final List<IOSPollingOption> pollingOptions;
  final Duration? timeoutDuration;
  final Map<ErrorMessageType, String> errorMessages;
  IosNfcScanConfiguration(
      {this.defaultAlertMessage =
          "Hold your iPhone near the item to learn more about it.",
      this.successAlertMessage = "NFC tag found",
      this.timeoutDuration,
      this.errorMessages = const {
        ErrorMessageType.unknownError: "Unknown error",
        ErrorMessageType.sessionError: "NFC session error, please try again",
        ErrorMessageType.sessionTimeoutError: "Session timeout",
        ErrorMessageType.connectTagError: "Can't connect to NFC Card",
        ErrorMessageType.queryNDefStatusError:
            "Unable to query NDEF status of tag",
        ErrorMessageType.readNDefError: "Fail to read NDEF message from tag",
        ErrorMessageType.parsingDataError: "Error when parsing data"
      },
      this.pollingOptions = IOSPollingOption.values,
      this.invalidateAfterFirstRead = false});

  @override
  Map<String, dynamic> toJson() {
    inspect(pollingOptions.map((option) => option.toString().split(".")[1]));
    return {
      "defaultAlertMessage": defaultAlertMessage,
      "defaultSuccessMessage": successAlertMessage,
      "invalidateAfterFirstRead": invalidateAfterFirstRead,
      if (timeoutDuration != null)
        "timeoutInMillis": timeoutDuration!.inMilliseconds,
      "pollingOptions": pollingOptions
          .map((option) => option.toString().split(".")[1])
          .toList(),
      ...errorMessages.map((key, value) {
        return MapEntry(key.toString().split(".")[1], value.toString());
      })
    };
  }
}
