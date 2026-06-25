import Foundation
import CoreLocation
import UniformTypeIdentifiers

enum MediaKind: String, Codable {
    case image
    case video
    case audio
    case unknown
}

struct PhotoAssetSummary: Identifiable {
    let id: String
    let localIdentifier: String
    let mediaKind: MediaKind
    let contentTypeIdentifier: String?
    let width: Int
    let height: Int
    let duration: TimeInterval
    let isFavorite: Bool
    let isHidden: Bool
    let representsBurst: Bool
    let burstIdentifier: String?
    let burstSelectionTypes: [String]
    let hasAdjustments: Bool
    let addedDate: Date?
    let creationDate: Date?
    let modificationDate: Date?
    let location: CLLocationCoordinate2D?
    let sourceType: String
    let mediaSubtypes: [String]
}

struct EmbeddedMetadataBundle {
    let rootProperties: [String: AnyHashable]
    let exif: [String: AnyHashable]
    let tiff: [String: AnyHashable]
    let gps: [String: AnyHashable]
    let iptc: [String: AnyHashable]
    let makerApple: [String: AnyHashable]
    let exifAux: [String: AnyHashable]
}

struct PhotoResourceInfo: Identifiable {
    let id: String
    let assetLocalIdentifier: String
    let resourceType: String
    let uniformTypeIdentifier: String?
    let originalFilename: String
    let fullSizePhotoDimensions: String?
}

struct UnifiedPhotoReport: Identifiable {
    let id: String
    let summary: PhotoAssetSummary
    let collections: [String]
    let resources: [PhotoResourceInfo]
    let embeddedMetadataByResourceId: [String: EmbeddedMetadataBundle]
    let generatedAt: Date
}
