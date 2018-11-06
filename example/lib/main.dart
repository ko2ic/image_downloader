import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_downloader/image_downloader.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Running on: $_isSuccess\n'),
              RaisedButton(
                onPressed: () {
                  _downloadImage();
                },
                child: Text("save image."),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadImage() async {
    bool isSuccess;
    try {
      isSuccess = await ImageDownloader.downloadImage("https://flutter.io/images/flutter-mark-square-100.png");
    } on PlatformException catch (e) {
      isSuccess = false;
    }

    if (!mounted) return;

    setState(() {
      _isSuccess = isSuccess;
    });
  }
}
