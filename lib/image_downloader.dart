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
  /// Returns imageId of the saved image if saving succeeded.
  /// Returns null if not been granted permission.
  /// Otherwise it is a PlatformException.
  ///
  /// imageId is in case of Adroid,  MediaStore.Images.Media._ID, in case of ios, PHObjectPlaceholder#localIdentifier.
  static Future<String> downloadImage(String url) async {
    return await _channel.invokeMethod('downloadImage', <String, String>{'url': url}).then<String>((dynamic result) => result);
  }

  /// Acquire the saved image name.
  static Future<String> findName(String imageId) async {
    return await _channel.invokeMethod('findName', <String, String>{'imageId': imageId}).then<String>((dynamic result) => result);
  }

  /// Acquire the saved image path.
  static Future<String> findPath(String imageId) async {
    return await _channel.invokeMethod('findPath', <String, String>{'imageId': imageId}).then<String>((dynamic result) => result);
  }

  /// Acquire the saved image byte size.
  static Future<int> findByteSize(String imageId) async {
    return await _channel.invokeMethod('findByteSize', <String, String>{'imageId': imageId}).then<int>((dynamic result) => result);
  }

  /// Acquire the saved image mimeType.
  static Future<String> findMimeType(String imageId) async {
    return await _channel.invokeMethod('findMimeType', <String, String>{'imageId': imageId}).then<String>((dynamic result) => result);
  }
}
