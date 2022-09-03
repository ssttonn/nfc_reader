import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nfc_reader/models/nfc_tag.dart';
import 'package:nfc_reader/nfc_reader.dart';

class ScannedTagsPage extends StatefulWidget {
  const ScannedTagsPage({Key? key}) : super(key: key);

  @override
  State<ScannedTagsPage> createState() => _ScannedTagsPageState();
}

class _ScannedTagsPageState extends State<ScannedTagsPage> {
  ThemeData? themeData;
  List<NFCTag> tags = [];
  @override
  Widget build(BuildContext context) {
    themeData = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("NFC Reader example"),
      ),
      body: _body(),
    );
  }

  _onScanDefTag() async {
    try {
      NFCTag tag = await NFCTagReader.instance.scanNFCNDefTag();

      setState(() {
        tags.add(tag);
      });
    } catch (e) {}
  }

  _onScanTag() async {
    try {
      NFCTag tag = await NFCTagReader.instance.scanTag();
      setState(() {
        tags.add(tag);
      });
    } catch (e) {}
  }

  Widget _body() {
    return FutureBuilder<bool>(
        future: NFCTagReader.instance
            .isNFCAvailable(), // Detect if the current device supports NFC
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!) {
            return ListView(
              children: [
                _scanBtn("Scan for NDEF tags", onPressed: _onScanDefTag),
                _scanBtn("Scan for tags", onPressed: _onScanTag),
                ...tags
                    .map((tag) => Container(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: const Color(0xFFf5f5f5),
                              borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text("Supported: ${tag.supported}",
                                  style: themeData!.textTheme.subtitle1
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              Text("Capacity: ${tag.capacity}",
                                  style: themeData!.textTheme.subtitle1
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              Text("Writable: ${tag.writable}",
                                  style: themeData!.textTheme.subtitle1
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              Text("Readonly: ${tag.readable}",
                                  style: themeData!.textTheme.subtitle1
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              Text("Total payloads: ${tag.payloads.length}",
                                  style: themeData!.textTheme.subtitle1
                                      ?.copyWith(fontWeight: FontWeight.bold))
                            ],
                          ),
                        ))
                    .toList()
              ],
            );
          }
          return const Text("Your device doesn't support NFC");
        });
  }

  Widget _scanBtn(String buttonTitle, {VoidCallback? onPressed}) {
    return CupertinoButton(
        onPressed: onPressed,
        child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: themeData!.colorScheme.primary),
            child: Text(
              buttonTitle,
              style:
                  themeData!.textTheme.subtitle1?.copyWith(color: Colors.white),
            )));
  }
}
