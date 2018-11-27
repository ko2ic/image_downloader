import 'dart:async';

import 'package:flutter/services.dart';

/// Provide the function to save the image on the Internet to each devices.
class ImageDownloader {
  /// MethodChannel of image_downloader.
  static const MethodChannel _channel = const MethodChannel('plugins.ko2ic.com/image_downloader');

  /// private constructor.
  ImageDownloader._();

  /// Save the image of the specified [url] on each devices.
  ///
  /// ios will be saved in Photo Library.
  /// Android will be saved in the download directory.
  ///
  /// Returns `true` if saving succeeded.
  /// Returns `false` if not been granted permission.
  /// Otherwise it is a PlatformException.
  static Future<bool> downloadImage(String url) async {
    return await _channel.invokeMethod('downloadImage', <String, String>{'url': url}).then<bool>((dynamic result) => result);
  }
}
