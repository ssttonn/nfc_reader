import 'package:nfc_reader/base/enums.dart';

abstract class NFCTag {
  final bool
      supported; // a flag to determine whether this tag is in NDEF format or not
  final bool writable;
  final bool readable;
  final int capacity;
  final List<NFCPayload>? payloads; // data return by this tag
  NFCTag(
      {this.supported = false,
      this.writable = false,
      this.readable = false,
      this.capacity = 0,
      this.payloads});
}

abstract class NFCPayload {}

class NFCDefTag extends NFCTag {
  NFCDefTag(
      {bool supported = false,
      bool writable = false,
      bool readable = false,
      int capacity = 0,
      List<NFCDefPayload> payloads = const []})
      : super(
            payloads: payloads,
            supported: supported,
            writable: writable,
            readable: readable,
            capacity: capacity);

  factory NFCDefTag.fromJson(Map<String, dynamic> json) {
    return NFCDefTag(
      supported: json["supported"] ?? false,
      writable: json["writable"] ?? false,
      readable: json["readOnly"] ?? false,
      capacity: json["capacity"] ?? 0,
      payloads: (json["payloads"] as List<dynamic>? ?? [])
          .map((payload) => NFCDefPayload.fromJson(payload))
          .toList(),
    );
  }
}

class NFCDefPayload extends NFCPayload {
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
}
