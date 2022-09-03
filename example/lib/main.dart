import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:nfc_reader/models/nfc_configuration.dart';
import 'package:nfc_reader/models/nfc_tag.dart';
import 'package:nfc_reader/nfc_reader.dart';
import 'package:nfc_reader_example/pages/scanned_tags_page.dart';
import 'package:nfc_reader_example/pages/tag_info_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        initialRoute: "/scannedTags",
        onGenerateRoute: ((settings) {
          switch (settings.name) {
            case "/scannedTags":
              return MaterialPageRoute(builder: (context) => ScannedTagsPage());
            case "/tagInfo":
              return MaterialPageRoute(builder: (context) => TagInfoPage());
          }
        }));
  }
}
