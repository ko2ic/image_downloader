import Foundation

enum MIMEType {
    case png
    case jpeg
    case gif
    case other
}

// TODO: Will be refactored using this class
class MetaDataUtils {
    private init() {}

    static func getImageMIMEType(imageData: Data) -> MIMEType {
        var values: UInt8 = 0
        imageData.copyBytes(to: &values, count: 1)

        switch values {
        case 0xFF:
            return MIMEType.jpeg
        case 0x89:
            return MIMEType.png
        case 0x47:
            return MIMEType.gif
        case 0x00:
            return MIMEType.other
        default:
            return MIMEType.jpeg
        }
    }

    static func getMetaData(imageData: Data) -> NSDictionary {
        let source = CGImageSourceCreateWithData(imageData as CFData, nil)
        let metadata = CGImageSourceCopyPropertiesAtIndex(source!, 0, nil)! as NSDictionary
        return metadata
    }

    static func updateMesataData(metaData: NSDictionary, imageData: Data) -> Data {
        let mutableData = NSMutableData()
        let cgImage: CGImageSource = CGImageSourceCreateWithData(imageData as CFData, nil)!
        let destination = CGImageDestinationCreateWithData(mutableData as CFMutableData, CGImageSourceGetType(cgImage)!, 1, nil)!
        CGImageDestinationAddImageFromSource(destination, cgImage, 0, metaData as CFDictionary)
        CGImageDestinationFinalize(destination)
        return mutableData as Data
    }

    static func getNormalizedUIImageOrientation(_ cgImageOrientation: CGImagePropertyOrientation?) -> UIImage.Orientation {
        guard let cgImageOrientation = cgImageOrientation else {
            return .up
        }
        switch cgImageOrientation {
        case .up:
            return .up
        case .down:
            return .down
        case .left:
            return .left
        case .right:
            return .right
        case .upMirrored:
            return .upMirrored
        case .downMirrored:
            return .downMirrored
        case .leftMirrored:
            return .leftMirrored
        case .rightMirrored:
            return .rightMirrored
        default:
            return .up
        }
    }
}
