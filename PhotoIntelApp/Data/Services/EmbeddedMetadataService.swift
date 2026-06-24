import Foundation
import ImageIO
import AVFoundation

final class EmbeddedMetadataService: EmbeddedMetadataProviding {
    func parseMetadata(from fileURL: URL) async -> EmbeddedMetadataBundle {
        if let imageMetadata = parseImageMetadata(from: fileURL) {
            return imageMetadata
        }

        return parseVideoMetadata(from: fileURL)
    }

    private func parseImageMetadata(from fileURL: URL) -> EmbeddedMetadataBundle? {
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return nil
        }

        return EmbeddedMetadataBundle(
            rootProperties: MetadataNormalization.dictionary(properties),
            exif: MetadataNormalization.dictionary(properties[kCGImagePropertyExifDictionary as String]),
            tiff: MetadataNormalization.dictionary(properties[kCGImagePropertyTIFFDictionary as String]),
            gps: MetadataNormalization.dictionary(properties[kCGImagePropertyGPSDictionary as String]),
            iptc: MetadataNormalization.dictionary(properties[kCGImagePropertyIPTCDictionary as String]),
            makerApple: MetadataNormalization.dictionary(properties[kCGImagePropertyMakerAppleDictionary as String]),
            exifAux: MetadataNormalization.dictionary(properties[kCGImagePropertyExifAuxDictionary as String])
        )
    }

    private func parseVideoMetadata(from fileURL: URL) -> EmbeddedMetadataBundle {
        let asset = AVURLAsset(url: fileURL)
        var root: [String: AnyHashable] = [
            "duration": asset.duration.seconds,
            "playable": asset.isPlayable,
            "hasProtectedContent": asset.hasProtectedContent
        ]

        let commonMetadata = asset.commonMetadata
        for item in commonMetadata {
            let key = item.commonKey?.rawValue ?? "unknown"
            if let value = item.stringValue {
                root[key] = AnyHashable(value)
            } else if let number = item.numberValue {
                root[key] = AnyHashable(number.doubleValue)
            }
        }

        return EmbeddedMetadataBundle(
            rootProperties: root,
            exif: [:],
            tiff: [:],
            gps: [:],
            iptc: [:],
            makerApple: [:],
            exifAux: [:]
        )
    }
}
