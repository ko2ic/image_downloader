import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_downloader/image_downloader.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _message = "";
  String _path = "";
  String _size = "";
  String _mimeType = "";
  File _imageFile;

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(_message),
                Text(_size),
                Text(_mimeType),
                Text(_path),
                RaisedButton(
                  onPressed: () {
                    _downloadImage();
                  },
                  child: Text("default destination"),
                ),
                RaisedButton(
                  onPressed: () {
                    _downloadImage(
                      destination: AndroidDestinationType.directoryPictures
                        ..inExternalFilesDir()
                        ..subDirectory("sample.gif"),
                    );
                  },
                  child: Text("custom destination(only android)"),
                ),
                (_imageFile == null) ? Container() : Image.file(_imageFile)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadImage({AndroidDestinationType destination}) async {
    String fileName;
    String path;
    int size;
    String mimeType;
    try {
      String imageId;
      if (destination == null) {
        imageId = await ImageDownloader.downloadImage("https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/flutter.png");
      } else {
        imageId = await ImageDownloader.downloadImage(
          "https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/flutter.png",
          destination: destination,
        );
      }

      if (imageId == null) {
        return;
      }
      fileName = await ImageDownloader.findName(imageId);
      path = await ImageDownloader.findPath(imageId);
      size = await ImageDownloader.findByteSize(imageId);
      mimeType = await ImageDownloader.findMimeType(imageId);
    } on PlatformException catch (error) {
      setState(() {
        _message = error.message;
      });
      return;
    }

    if (!mounted) return;

    setState(() {
      var location = Platform.isAndroid ? "Directory" : "Photo Library";
      _message = 'Saved as "$fileName" in $location.\n';
      _size = 'size:     $size';
      _mimeType = 'mimeType: $mimeType';
      _path = 'path:$path';

      _imageFile = File(path);
    });
  }
}
