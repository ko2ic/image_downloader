import Flutter
import Photos
import UIKit

public class SwiftImageDownloaderPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "plugins.ko2ic.com/image_downloader", binaryMessenger: registrar.messenger())
        let instance = SwiftImageDownloaderPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "downloadImage":

            guard let dict = call.arguments as? [String: Any], let url = dict["url"] as? String else {
                result(FlutterError(code: "assertion_error", message: "url required.", details: nil))
                return
            }

            PHPhotoLibrary.requestAuthorization { status in
                switch status {
                case .authorized:
                    self.downloadImage(url, result)
                case .denied, .restricted:
                    result(false)
                case .notDetermined:
                    result(false)
                }
            }
        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }

    private func downloadImage(_ url: String, _ result: @escaping FlutterResult) {
        let task = URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: { (fileData: Data?, urlResponse: URLResponse?, error: Error?) in
            if error != nil {
                result(FlutterError(code: "request_error", message: error?.localizedDescription, details: error))
                return
            } else {
                guard let data = fileData else {
                    result(FlutterError(code: "data_error", message: "response data is nil", details: nil))
                    return
                }
                var values: UInt8 = 0
                data.copyBytes(to: &values, count: 1)
                switch values {
                case 0xFF:
                    // image/jpeg
                    self.saveImage(data, result: result)
                case 0x89:
                    // image/png
                    self.saveImage(data, result: result)
                case 0x47:
                    // image/gif
                    self.saveGif(data: data, name: urlResponse?.suggestedFilename, result: result)
                case 0x49, 0x4D:
                    // image/tiff
                    self.saveImage(data, result: result)
                default:
                    self.saveImage(data, result: result)
                }
            }
        })
        task.resume()
    }

    private func saveImage(_ data: Data, result: @escaping FlutterResult) {
        guard let image = UIImage(data: data) else {
            result(FlutterError(code: "data_error", message: "Couldn't convert to UIImage.", details: nil))
            return
        }

        var exifDatetime: String?
        var latitude: Double?
        var logitude: Double?

        if let ref = CGImageSourceCreateWithData(data as CFData, nil) {
            if let metadata = CGImageSourceCopyPropertiesAtIndex(ref, 0, nil) as? [String: AnyObject] {
                if let exifDict = metadata["{Exif}"] as? [CFString: AnyObject] {
                    exifDatetime = exifDict[kCGImagePropertyExifDateTimeOriginal] as? String
                }
                if let gpsDict = metadata["{GPS}"] as? [CFString: AnyObject] {
                    latitude = gpsDict[kCGImagePropertyGPSLatitude] as? Double
                    logitude = gpsDict[kCGImagePropertyGPSLongitude] as? Double
                }
                if let tiffDict = metadata["{TIFF}"] as? [CFString: AnyObject] {
                    if let datetime = tiffDict[kCGImagePropertyTIFFDateTime] as? String {
                        exifDatetime = datetime
                    }
                }
            }
        }

        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            if let exifDatetime = exifDatetime {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
                request.creationDate = formatter.date(from: exifDatetime)
            }
            if let latitude = latitude, let logitude = logitude {
                request.location = CLLocation(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(logitude))
            }
        }) { isSuccess, error in
            if isSuccess {
                result(true)
            } else {
                result(FlutterError(code: "save_error", message: "Couldn't save to photo library.", details: error))
            }
        }
    }

    private func saveGif(data: Data, name: String?, result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            _ = UIImageView(image: UIImage(data: data))
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd.HH.mm.sss"
        let now = Date()

        let fileName = (name != nil) ? name! : "\(formatter.string(from: now)).gif"
        guard let imageUrl = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(fileName) else {
            result(FlutterError(code: "save_error", message: "Couldn't save gif in temporary directory.", details: nil))
            return
        }
        do {
            try data.write(to: imageUrl)
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: imageUrl)
            }, completionHandler: { _, error in
                if error != nil {
                    result(FlutterError(code: "save_error", message: "Couldn't save gif to photo library.", details: error))
                } else {
                    result(true)
                }
            })
        } catch {
            result(FlutterError(code: "save_error", message: "Couldn't save gif to photo library.", details: error))
        }
    }
}
