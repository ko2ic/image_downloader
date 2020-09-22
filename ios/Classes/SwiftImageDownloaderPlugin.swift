import Flutter
import MobileCoreServices
import Photos
import UIKit

@objcMembers
public class SwiftImageDownloaderPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "plugins.ko2ic.com/image_downloader", binaryMessenger: registrar.messenger())
        let instance = SwiftImageDownloaderPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    let channel: FlutterMethodChannel
    var result: FlutterResult!
    var fileData: NSMutableData = NSMutableData()
    var dataTask: URLSessionDataTask?
    var expectedContentLength = 0
    var progress: Float = 0.0

    init(channel: FlutterMethodChannel) {
        self.channel = channel
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "downloadImage":

            guard let dict = call.arguments as? [String: Any], let url = dict["url"] as? String else {
                result(FlutterError(code: "assertion_error", message: "url is required.", details: nil))
                return
            }

            let headers = dict["headers"] as? [String: String]

            PHPhotoLibrary.requestAuthorization { status in
                switch status {
                case .authorized:
                    self.downloadImage(url, headers, result)
                case .denied, .restricted:
                    result(nil)
                case .notDetermined:
                    result(nil)
                default:
                    result(nil)
                    break
                }
            }
        case "cancel":
            dataTask?.cancel()
        case "open":
            open(call, result: result)
            break
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

    private func downloadImage(_ url: String, _ headers: [String: String]?, _ result: @escaping FlutterResult) {
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
        let url = URL(string: url)!
        var request = URLRequest(url: url)

        if let headers = headers {
            headers.forEach { (arg: (key: String, value: String)) in
                let (key, value) = arg
                request.addValue(value, forHTTPHeaderField: key)
            }
        }

        let task = session.dataTask(with: request)
        dataTask = task
        task.resume()
        self.result = result
    }

//    private func downloadImage(_ url: String, _ result: @escaping FlutterResult) {
//        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
//        let task = session.dataTask(with: URL(string: url)!, completionHandler: { (fileData: Data?, urlResponse: URLResponse?, error: Error?) in
//            if error != nil {
//                result(FlutterError(code: "request_error", message: error?.localizedDescription, details: error))
//                return
//            } else {
//                if let statusCode = (urlResponse as? HTTPURLResponse)?.statusCode {
//                    if 400 ... 599 ~= statusCode {
//                        result(FlutterError(code: "\(statusCode)", message: "HTTP status code error.", details: nil))
//                        return
//                    }
//                }
//
//                guard let data = fileData else {
//                    result(FlutterError(code: "data_error", message: "response data is nil", details: nil))
//                    return
//                }
//                var values: UInt8 = 0
//                data.copyBytes(to: &values, count: 1)
//                switch values {
//                case 0xFF:
//                    // image/jpeg
//                    self.saveImage(data, result: result)
//                case 0x89:
//                    // image/png
//                    self.saveImage(data, result: result)
//                case 0x47:
//                    // image/gif
//                    self.saveGif(data: data, name: urlResponse?.suggestedFilename, result: result)
//                case 0x49, 0x4D:
//                    // image/tiff
//                    self.saveImage(data, result: result)
//                default:
//                    self.saveImage(data, result: result)
//                }
//            }
//        })
//        task.resume()
//    }

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
                if (error! as NSError).domain == "NSCocoaErrorDomain", (error! as NSError).code == -1 {
                    guard let imageUrl = self.createTemporaryFile(fileName: nil, ext: "jpg") else {
                        return
                    }
                    let detail = ["unsupported_file_path": imageUrl.path]
                    result(FlutterError(code: "unsupported_file", message: "Couldn't save to photo library.", details: detail))
                    return
                } else {
                    result(FlutterError(code: "save_error", message: "Couldn't save to photo library.", details: error))
                }
            }
        }
    }

    private func saveGif(data: Data, name: String?, result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            _ = UIImageView(image: UIImage(data: data))
        }

        guard let imageUrl = createTemporaryFile(fileName: name, ext: "gif") else {
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

    private func saveVideo(data: Data, name: String?, result: @escaping FlutterResult) {
        guard let videoUrl = createTemporaryFile(fileName: name, ext: "mp4") else {
            return
        }

        do {
            var imageId: String?
            try data.write(to: videoUrl)
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl)
                imageId = request?.placeholderForCreatedAsset?.localIdentifier
            }, completionHandler: { isSuccess, error in
                if let imageId = imageId, isSuccess {
                    result(imageId)
                } else {
                    if (error! as NSError).domain == "NSCocoaErrorDomain", (error! as NSError).code == -1 {
                        let detail = ["unsupported_file_path": videoUrl.path]
                        result(FlutterError(code: "unsupported_file", message: "Couldn't save to photo library.", details: detail))
                        return
                    } else {
                        result(FlutterError(code: "save_error", message: "Couldn't save to photo library.", details: error))
                    }
                }
            })
        } catch {
            result(FlutterError(code: "save_error", message: "Couldn't save gif to photo library.", details: error))
        }
    }

    private func createTemporaryFile(fileName: String?, ext: String) -> URL? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd.HH.mm.sss"
        let now = Date()

        let fileName = (fileName != nil) ? fileName! : "\(formatter.string(from: now)).\(ext)"
        guard let temporaryFile = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(fileName) else {
            var ext = ext
            if let lastFileName = fileName.split(separator: ".").last {
                ext = String(lastFileName)
            }
            result(FlutterError(code: "save_error", message: "Couldn't save \(ext) in temporary directory.", details: nil))
            return nil
        }
        return temporaryFile
    }

    private func open(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let path = (call.arguments as? Dictionary<String, String>)?["path"] else {
            result(FlutterError(code: "assertion_error", message: "path is required.", details: nil))
            return
        }

        let controller = UIDocumentInteractionController(url: URL(fileURLWithPath: path))
        controller.delegate = self
        if !controller.presentPreview(animated: true) {
            result(FlutterError(code: "preview_error", message: "This file is not supported for previewing", details: nil))
        }
    }

    private func findPath(imageId: String, completion: @escaping (String) -> Void) {
        let asset = PHAsset.fetchAssets(withLocalIdentifiers: [imageId], options: nil).firstObject!

        if asset.mediaType == PHAssetMediaType.video {
            PHImageManager().requestAVAsset(forVideo: asset, options: nil, resultHandler: { avurlAsset, _, _ in
                let asset = avurlAsset as! AVURLAsset
                completion(asset.url.path)
            })
        } else {
            asset.requestContentEditingInput(with: PHContentEditingInputRequestOptions()) { input, _ in
                let url = input?.fullSizeImageURL
                completion(url!.path)
            }
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

        if asset.mediaType == PHAssetMediaType.video {
            PHImageManager().requestAVAsset(forVideo: asset, options: nil, resultHandler: { avurlAsset, _, _ in
                let asset = avurlAsset as! AVURLAsset
                let pathExtension = asset.url.pathExtension
                if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
                    if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                        completion(mimetype as String)
                    }
                } else {
                    completion("")
                }
            })
        } else {
            PHImageManager.default().requestImageData(for: asset, options: nil) { _, uti, _, _ in
                if let uti = uti {
                    let mimeType: String = UTTypeCopyPreferredTagWithClass(uti as CFString, kUTTagClassMIMEType)!.takeRetainedValue() as String
                    completion(mimeType)
                } else {
                    completion("")
                }
            }
        }
    }
}

extension SwiftImageDownloaderPlugin: URLSessionDataDelegate {
    public func urlSession(_: URLSession, dataTask _: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        progress = 0.0
        fileData.length = 0
        expectedContentLength = Int(response.expectedContentLength)
        completionHandler(URLSession.ResponseDisposition.allow)
    }

    public func urlSession(_: URLSession, dataTask _: URLSessionDataTask, didReceive data: Data) {
        fileData.append(data)
        let percentageDownloaded = Float(fileData.length) / Float(expectedContentLength)
        progress = percentageDownloaded

        channel.invokeMethod("onProgressUpdate", arguments: ["progress": Int(progress * 100)])
    }
}

extension SwiftImageDownloaderPlugin: URLSessionDelegate {
    public func urlSession(_: URLSession, task downloadTask: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil {
            if let code = (error as NSError?)?.code {
                if code == NSURLErrorCancelled {
                    result(nil)
                    result = nil
                    return
                }
            }
            result(FlutterError(code: "request_error", message: error?.localizedDescription, details: error))
            result = nil
            return
        }
        let httpResponse = (downloadTask.response as? HTTPURLResponse)
        if let statusCode = httpResponse?.statusCode {
            if 400 ... 599 ~= statusCode {
                result(FlutterError(code: "\(statusCode)", message: "HTTP status code error.", details: nil))
                result = nil
                return
            }
        }

        let data = fileData as Data

        var values: UInt8 = 0
        data.copyBytes(to: &values, count: 1)
        switch values {
        case 0xFF:
            // image/jpeg
            saveImage(data, result: result)
        case 0x89:
            // image/png
            saveImage(data, result: result)
        case 0x47:
            // image/gif
            saveGif(data: data, name: (downloadTask.response as? HTTPURLResponse)?.suggestedFilename, result: result)
        case 0x49, 0x4D:
            // image/tiff
            saveImage(data, result: result)
        case 0x00:
            if data.count >= 12 {
                let testString = String(data: data.subdata(in: 4 ..< 12), encoding: .nonLossyASCII)
                // image/heic
                if testString == "ftypheic"
                    || testString == "ftypheix"
                    || testString == "ftyphevc"
                    || testString == "ftyphevx" {
                    // saved as jpeg
                    let uiImage = UIImage(data: data)!
                    let metadata = MetaDataUtils.getMetaData(imageData: data)
                    let orientation = metadata[String(kCGImagePropertyOrientation)] as? UInt32 ?? 0
                    let newImage = UIImage(cgImage: uiImage.cgImage!, scale: 1.0, orientation: MetaDataUtils.getNormalizedUIImageOrientation(CGImagePropertyOrientation(rawValue: orientation)))
                    let jpegData = newImage.jpegData(compressionQuality: 1.0)!
                    let newData = MetaDataUtils.updateMesataData(metaData: metadata, imageData: jpegData)
                    saveImage(newData, result: result)
                    return
                } else {
                    // movie
                    let contentType = httpResponse?.allHeaderFields["Content-Type"] as? String
                    if let contentType = contentType {
                        if contentType.contains("vide") || contentType == "application/octet-stream" {
                            saveVideo(data: data, name: httpResponse?.suggestedFilename, result: result)
                            return
                        }
                    }
                }
            }
            fallthrough
        default:
            saveImage(data, result: result)
        }
        result = nil
    }
}

extension SwiftImageDownloaderPlugin: UIDocumentInteractionControllerDelegate {
    public func documentInteractionControllerViewControllerForPreview(_: UIDocumentInteractionController) -> UIViewController {
        return (UIApplication.shared.delegate?.window??.rootViewController)!
    }
}
