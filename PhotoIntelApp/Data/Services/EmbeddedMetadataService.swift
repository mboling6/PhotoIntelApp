import Foundation
import ImageIO
import AVFoundation

final class EmbeddedMetadataService: EmbeddedMetadataProviding {
    private let extractedImageMetadataKeys: Set<String> = [
        kCGImagePropertyExifDictionary as String,
        kCGImagePropertyTIFFDictionary as String,
        kCGImagePropertyGPSDictionary as String,
        kCGImagePropertyIPTCDictionary as String,
        kCGImagePropertyMakerAppleDictionary as String,
        kCGImagePropertyExifAuxDictionary as String
    ]

    func parseMetadata(from fileURL: URL) async -> EmbeddedMetadataBundle {
        if let imageMetadata = parseImageMetadata(from: fileURL) {
            return imageMetadata
        }

        return await parseVideoMetadata(from: fileURL)
    }

    private func parseImageMetadata(from fileURL: URL) -> EmbeddedMetadataBundle? {
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return nil
        }

        return EmbeddedMetadataBundle(
            rootProperties: MetadataNormalization.dictionary(filteredRootProperties(from: properties)),
            exif: MetadataNormalization.dictionary(properties[kCGImagePropertyExifDictionary as String]),
            tiff: MetadataNormalization.dictionary(properties[kCGImagePropertyTIFFDictionary as String]),
            gps: MetadataNormalization.dictionary(properties[kCGImagePropertyGPSDictionary as String]),
            iptc: MetadataNormalization.dictionary(properties[kCGImagePropertyIPTCDictionary as String]),
            makerApple: MetadataNormalization.dictionary(properties[kCGImagePropertyMakerAppleDictionary as String]),
            exifAux: MetadataNormalization.dictionary(properties[kCGImagePropertyExifAuxDictionary as String])
        )
    }

    private func filteredRootProperties(from properties: [String: Any]) -> [String: Any] {
        properties.filter { !extractedImageMetadataKeys.contains($0.key) }
    }

    private func parseVideoMetadata(from fileURL: URL) async -> EmbeddedMetadataBundle {
        let asset = AVURLAsset(url: fileURL)
        var root: [String: AnyHashable] = [:]

        do {
            let duration = try await asset.load(.duration)
            root["duration"] = duration.seconds
        } catch {
            root["durationError"] = AnyHashable(error.localizedDescription)
        }

        do {
            root["playable"] = try await asset.load(.isPlayable)
        } catch {
            root["playableError"] = AnyHashable(error.localizedDescription)
        }

        do {
            root["hasProtectedContent"] = try await asset.load(.hasProtectedContent)
        } catch {
            root["hasProtectedContentError"] = AnyHashable(error.localizedDescription)
        }

        do {
            let commonMetadata = try await asset.load(.commonMetadata)
            for item in commonMetadata {
                let key = item.commonKey?.rawValue ?? "unknown"
                if let value = try await item.load(.stringValue) {
                    root[key] = AnyHashable(value)
                } else if let number = try await item.load(.numberValue) {
                    root[key] = AnyHashable(number.doubleValue)
                }
            }
        } catch {
            root["commonMetadataError"] = AnyHashable(error.localizedDescription)
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
