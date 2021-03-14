import 'dart:async';

import 'package:flutter/services.dart';

/// Provide the function to save the image on the Internet to each devices.
class ImageDownloader {
  /// MethodChannel of image_downloader.
  static const MethodChannel _channel =
      const MethodChannel('plugins.ko2ic.com/image_downloader');

  /// private constructor.
  ImageDownloader._();

  /// Save the image of the specified [url] on each devices.
  ///
  /// ios will be saved in Photo Library.
  /// Android will be saved in the specified [AndroidDestinationType].
  /// (default: setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, `yyyy-MM-dd.HH.mm.sss.<extension>') ).
  ///
  /// Returns imageId of the saved image if saving succeeded.
  /// Returns null if not been granted permission.
  /// Otherwise it is a PlatformException.
  ///
  /// imageId is in case of Adroid,  MediaStore.Images.Media._ID, in case of ios, PHObjectPlaceholder#localIdentifier.
  static Future<String?> downloadImage(
    String url, {
    String? outputMimeType,
    Map<String, String>? headers,
    AndroidDestinationType? destination,
  }) async {
    return _channel.invokeMethod<String>('downloadImage', {
      'url': url,
      'mimeType': outputMimeType,
      'headers': headers,
      'inPublicDir': destination?._inPublicDir,
      'directory': destination?._directory,
      'subDirectory': destination?._subDirectory,
    });
  }

  /// You can get the progress with [onProgressUpdate].
  /// On iOS, cannot get imageId.
  static void callback({required Function(String?, int) onProgressUpdate}) {
    _channel.setMethodCallHandler((MethodCall call) {
      if (call.method == 'onProgressUpdate') {
        final id = call.arguments['image_id'] as String?;
        final progress = call.arguments['progress'] as int;
        onProgressUpdate(id, progress);
      }
      return Future.value(null);
    });
  }

  /// cancel a single Downloading.
  static Future<void> cancel() async {
    return _channel.invokeMethod('cancel');
  }

  static Future<void> open(String localPath) async {
    return _channel.invokeMethod('open', {'path': localPath});
  }

  /// Acquire the saved image name.
  static Future<String?> findName(String imageId) async {
    return _channel.invokeMethod<String>('findName', {'imageId': imageId});
  }

  /// Acquire the saved image path.
  static Future<String?> findPath(String imageId) async {
    return _channel.invokeMethod<String>('findPath', {'imageId': imageId});
  }

  /// Acquire the saved image byte size.
  static Future<int?> findByteSize(String imageId) async {
    return _channel.invokeMethod<int>('findByteSize', {'imageId': imageId});
  }

  /// Acquire the saved image mimeType.
  static Future<String?> findMimeType(String imageId) async {
    return _channel.invokeMethod<String>('findMimeType', {'imageId': imageId});
  }
}

/// Save destination on android.
class AndroidDestinationType {
  final String _directory;
  String? _subDirectory;
  bool? _inPublicDir;

  /// Save to specified [directory].
  /// If it is a empty string, it points to each route.
  /// If [inPublicDir] is `true`, it can be obtained by calling Environment.getExternalStoragePublicDirectory() of Android.
  /// For example, ```/storage/emulated/0/``` .
  /// If [inPublicDir] is `false`, it can be obtained by calling context.getExternalFilesDir() of Android.
  /// For example, ```/storage/emulated/0/Android/data/<applicationId>/files``` .
  /// [subDirectory] can contain a file name.
  factory AndroidDestinationType.custom({
    bool? inPublicDir,
    required String directory,
    String? subDirectory,
  }) {
    return AndroidDestinationType._internal(directory)
      .._setInPublicDir(inPublicDir)
      ..subDirectory(subDirectory);
  }

  AndroidDestinationType._internal(this._directory);

  /// When this is called, it will be saved in the location that can be obtained by calling context.getExternalFilesDirs().
  void inExternalFilesDir() {
    this._inPublicDir = false;
  }

  /// Specify sud directory that inclueds file name.
  void subDirectory(String? subDirectory) {
    this._subDirectory = subDirectory;
  }

  void _setInPublicDir(bool? inPublicDir) {
    this._inPublicDir = inPublicDir;
  }

  /// Environment.DIRECTORY_DOWNLOADS
  static final directoryDownloads =
      AndroidDestinationType._internal("DIRECTORY_DOWNLOADS");

  /// Environment.DIRECTORY_PICTURES
  static final directoryPictures =
      AndroidDestinationType._internal("DIRECTORY_PICTURES");

  /// Environment.DIRECTORY_DCIM
  static final directoryDCIM =
      AndroidDestinationType._internal("DIRECTORY_DCIM");

  /// Environment.DIRECTORY_MOVIES
  static final directoryMovies =
      AndroidDestinationType._internal("DIRECTORY_MOVIES");
}
