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
  File? _imageFile;
  int _progress = 0;

  List<File> _mulitpleFiles = [];

  @override
  void initState() {
    super.initState();

    ImageDownloader.callback(onProgressUpdate: (String? imageId, int progress) {
      setState(() {
        _progress = progress;
      });
    });
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
                Text('Progress: $_progress %'),
                Text(_message),
                Text(_size),
                Text(_mimeType),
                Text(_path),
                _path == ""
                    ? Container()
                    : Builder(
                        builder: (context) => ElevatedButton(
                          onPressed: () async {
                            await ImageDownloader.open(_path)
                                .catchError((error) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(
                                    (error as PlatformException).message ?? ''),
                              ));
                            });
                          },
                          child: Text("Open"),
                        ),
                      ),
                ElevatedButton(
                  onPressed: () {
                    ImageDownloader.cancel();
                  },
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    _downloadImage(
                        "https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/bigsize.jpg");
                  },
                  child: Text("default destination"),
                ),
                ElevatedButton(
                  onPressed: () {
                    _downloadImage(
                      "https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/flutter.png",
                      destination: AndroidDestinationType.directoryPictures
                        ..inExternalFilesDir()
                        ..subDirectory("sample.gif"),
                    );
                  },
                  child: Text("custom destination(only android)"),
                ),
                ElevatedButton(
                  onPressed: () {
                    _downloadImage(
                        "https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/flutter_no.png",
                        whenError: true);
                  },
                  child: Text("404 error"),
                ),
                ElevatedButton(
                  onPressed: () {
                    _downloadImage(
                        "https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/sample.mkv",
                        whenError: true);
                    //_downloadImage("https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/sample.3gp");
                  },
                  child: Text("unsupported file error(only ios)"),
                ),
                ElevatedButton(
                  onPressed: () {
                    //_downloadImage("https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/sample.mp4");
                    //_downloadImage("https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/sample.m4v");
                    _downloadImage(
                        "https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/sample.mov");
                  },
                  child: Text("movie"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    var list = [
                      "https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/bigsize.jpg",
                      "https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/flutter.jpg",
                      "https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/sample.HEIC",
                      "https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/flutter_transparent.png",
                      "https://raw.githubusercontent.com/wiki/ko2ic/flutter_google_ad_manager/images/sample.gif",
                      "https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/flutter_no.png",
                      "https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/flutter.png",
                      "https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/flutter_real_png.jpg",
                      "https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/bigsize.jpg",
                      "https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/flutter.jpg",
                      "https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/flutter_transparent.png",
                      "https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/flutter_no.png",
                      "https://raw.githubusercontent.com/wiki/ko2ic/flutter_google_ad_manager/images/sample.gif",
                      "https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/flutter.png",
                      "https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/flutter_real_png.jpg",
                    ];

                    List<File> files = [];

                    for (var url in list) {
                      try {
                        final imageId =
                            await ImageDownloader.downloadImage(url);
                        final path = await ImageDownloader.findPath(imageId!);
                        files.add(File(path!));
                      } catch (error) {
                        print(error);
                      }
                    }
                    setState(() {
                      _mulitpleFiles.addAll(files);
                    });
                  },
                  child: Text("multiple downlod"),
                ),
                ElevatedButton(
                  onPressed: () => _downloadImage(
                    "https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/sample.webp",
                    outputMimeType: "image/png",
                  ),
                  child: Text("download webp(only Android)"),
                ),
                (_imageFile == null) ? Container() : Image.file(_imageFile!),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: BouncingScrollPhysics(),
                  children: List.generate(_mulitpleFiles.length, (index) {
                    return SizedBox(
                      width: 50,
                      height: 50,
                      child: Image.file(File(_mulitpleFiles[index].path)),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadImage(
    String url, {
    AndroidDestinationType? destination,
    bool whenError = false,
    String? outputMimeType,
  }) async {
    String? fileName;
    String? path;
    int? size;
    String? mimeType;
    try {
      String? imageId;

      if (whenError) {
        imageId = await ImageDownloader.downloadImage(url,
                outputMimeType: outputMimeType)
            .catchError((error) {
          if (error is PlatformException) {
            String? path = "";
            if (error.code == "404") {
              print("Not Found Error.");
            } else if (error.code == "unsupported_file") {
              print("UnSupported FIle Error.");
              path = error.details["unsupported_file_path"];
            }
            setState(() {
              _message = error.toString();
              _path = path ?? '';
            });
          }

          print(error);
        }).timeout(Duration(seconds: 10), onTimeout: () {
          print("timeout");
          return;
        });
      } else {
        if (destination == null) {
          imageId = await ImageDownloader.downloadImage(
            url,
            outputMimeType: outputMimeType,
          );
        } else {
          imageId = await ImageDownloader.downloadImage(
            url,
            destination: destination,
            outputMimeType: outputMimeType,
          );
        }
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
        _message = error.message ?? '';
      });
      return;
    }

    if (!mounted) return;

    setState(() {
      var location = Platform.isAndroid ? "Directory" : "Photo Library";
      _message = 'Saved as "$fileName" in $location.\n';
      _size = 'size:     $size';
      _mimeType = 'mimeType: $mimeType';
      _path = path ?? '';

      if (!_mimeType.contains("video")) {
        _imageFile = File(path!);
      }
      return;
    });
  }
}
