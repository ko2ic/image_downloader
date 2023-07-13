import Flutter
import UIKit

public class ImageDownloaderPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    SwiftImageDownloaderPlugin.register(with: registrar)
  }
}
