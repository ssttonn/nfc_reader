import 'package:nfc_reader/base/enums.dart';

enum NFCTagType {
  ndef,
  felica,
  mifarePlus,
  mifareUltraLight,
  mifareDesfire,
  mifareUnknown,
  iso7816,
  iso15693,
  unknown
}

class NFCTag {
  final NFCTagType tagType;
  final String? identifer;
  final String? historicalBytes;
  final String? applicationData;
  final String? initialSelectedAID;
  final bool
      supported; // a flag to determine whether this tag is in NDEF format or not
  final bool writable;
  final bool readable;
  final int capacity;
  final String name;
  final List<String> standards;
  final String? currentSystemCode;
  final String? manufacturerIdentifer;
  final List<NFCDefPayload> payloads; // data return by this tag

  NFCTag(
      {required this.tagType,
      required this.supported,
      required this.writable,
      required this.readable,
      required this.capacity,
      required this.name,
      required this.standards,
      required this.payloads,
      this.manufacturerIdentifer,
      this.currentSystemCode,
      this.identifer,
      this.historicalBytes,
      this.applicationData,
      this.initialSelectedAID});

  factory NFCTag.fromJson(Map<String, dynamic> json) {
    return NFCTag(
        tagType: json["type"] != null
            ? NFCTagType.values.firstWhere(
                (type) => type.toString().split(".")[1] == json["type"],
                orElse: () => NFCTagType.unknown)
            : NFCTagType.unknown,
        supported: json["supported"] ?? false,
        writable: json["writable"] ?? false,
        readable: json["readable"] ?? false,
        capacity: json["capacity"] ?? 0,
        name: json["name"] ?? "",
        standards: (json["standards"] as List<dynamic>? ?? [])
            .map((standard) => standard.toString())
            .toList(),
        payloads: (json["payloads"] as List<dynamic>? ?? [])
            .map((payload) => NFCDefPayload.fromJson(payload))
            .toList(),
        manufacturerIdentifer: json["manufacturerIdentifer"],
        currentSystemCode: json["currentSystemCode"],
        identifer: json["identifer"],
        historicalBytes: json["historycalBytes"],
        applicationData: json["applicationData"],
        initialSelectedAID: json["initialSelectedAID"]);
  }
}

class NFCDefPayload {
  final TypeNameFormat typeNameFormat;
  final String identifer;
  final String type;
  final String data;
  NFCDefPayload(
      {this.typeNameFormat = TypeNameFormat.unknown,
      this.identifer = "",
      this.type = "",
      this.data = ""});

  factory NFCDefPayload.fromJson(Map<String, dynamic> json) {
    return NFCDefPayload(
        typeNameFormat: json["format"] != null && json["format"] is int
            ? TypeNameFormat.values[json["format"]]
            : TypeNameFormat.unknown,
        identifer: json["identifer"] as String? ?? "",
        type: json["type"] as String? ?? "",
        data: json["data"] as String? ?? "");
  }

  Map<String, dynamic> toJson() {
    return {
      "format": typeNameFormat.index,
      "identifer": identifer,
      "type": type,
      "data": data
    };
  }
}
