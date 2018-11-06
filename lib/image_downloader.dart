import 'dart:async';

import 'package:flutter/services.dart';

class ImageDownloader {
  static const MethodChannel _channel = const MethodChannel('plugins.ko2ic.com/image_downloader');

  static Future<bool> downloadImage(String url) async {
    return await _channel.invokeMethod('downloadImage', <String, String>{'url': url}).then<bool>((dynamic result) => result);
  }
}
