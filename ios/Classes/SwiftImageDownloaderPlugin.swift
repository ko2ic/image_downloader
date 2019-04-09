import Flutter
import MobileCoreServices
import Photos
import UIKit

@objcMembers
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
                result(FlutterError(code: "assertion_error", message: "url is required.", details: nil))
                return
            }

            PHPhotoLibrary.requestAuthorization { status in
                switch status {
                case .authorized:
                    self.downloadImage(url, result)
                case .denied, .restricted:
                    result(nil)
                case .notDetermined:
                    result(nil)
                }
            }
        case "findPath":
            setData(call, result: result) { imageId in
                findPath(imageId: imageId) { value in
                    result(value)
                }
            }
        case "findName":
            setData(call, result: result) { imageId in
                let name = findName(imageId: imageId)
                result(name)
            }
        case "findByteSize":
            setData(call, result: result) { imageId in
                findByteSize(imageId: imageId) { value in
                    result(value)
                }
            }
        case "findMimeType":
            setData(call, result: result) { imageId in
                findMimeType(imageId: imageId) { value in
                    result(value)
                }
            }
        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }

    private func setData(_ call: FlutterMethodCall, result: @escaping FlutterResult, completion: (String) -> Void) {
        guard let imageId = (call.arguments as? Dictionary<String, String>)?["imageId"] else {
            result(FlutterError(code: "assertion_error", message: "imageId is required.", details: nil))
            return
        }
        completion(imageId)
    }

    private func downloadImage(_ url: String, _ result: @escaping FlutterResult) {
        let task = URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: { (fileData: Data?, urlResponse: URLResponse?, error: Error?) in
            if error != nil {
                result(FlutterError(code: "request_error", message: error?.localizedDescription, details: error))
                return
            } else {
                if let statusCode = (urlResponse as? HTTPURLResponse)?.statusCode {
                    if 400...599 ~= statusCode {
                        result(FlutterError(code: "\(statusCode)", message: "HTTP status code error.", details: nil))
                        return
                    }
                }

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

        var imageId: String?
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
            imageId = request.placeholderForCreatedAsset?.localIdentifier

        }) { isSuccess, error in
            if let imageId = imageId, isSuccess {
                result(imageId)
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
            var imageId: String?
            try data.write(to: imageUrl)
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: imageUrl)
                imageId = request?.placeholderForCreatedAsset?.localIdentifier
            }, completionHandler: { isSuccess, error in
                if let imageId = imageId, isSuccess {
                    result(imageId)
                } else {
                    result(FlutterError(code: "save_error", message: "Couldn't save to photo library.", details: error))
                }
            })
        } catch {
            result(FlutterError(code: "save_error", message: "Couldn't save gif to photo library.", details: error))
        }
    }

    private func findPath(imageId: String, completion: @escaping (String) -> Void) {
        let asset = PHAsset.fetchAssets(withLocalIdentifiers: [imageId], options: nil).firstObject!
        asset.requestContentEditingInput(with: PHContentEditingInputRequestOptions()) { input, _ in
            let url = input?.fullSizeImageURL
            completion(url!.path)
        }
    }

    private func findName(imageId: String) -> String {
        return PHAsset.fetchAssets(withLocalIdentifiers: [imageId], options: nil).firstObject?.value(forKey: "filename") as! String
    }

    private func findByteSize(imageId: String, completion: @escaping (Int) -> Void) {
        let asset = PHAsset.fetchAssets(withLocalIdentifiers: [imageId], options: nil).firstObject!
        PHImageManager.default().requestImageData(for: asset, options: nil) { imageData, _, _, _ in
            completion(imageData!.count)
        }
    }

    private func findMimeType(imageId: String, completion: @escaping (String) -> Void) {
        let asset = PHAsset.fetchAssets(withLocalIdentifiers: [imageId], options: nil).firstObject!
        PHImageManager.default().requestImageData(for: asset, options: nil) { _, uti, _, _ in
            let mimeType: String = UTTypeCopyPreferredTagWithClass(uti! as CFString, kUTTagClassMIMEType)!.takeRetainedValue() as String
            completion(mimeType)
        }
    }
}
