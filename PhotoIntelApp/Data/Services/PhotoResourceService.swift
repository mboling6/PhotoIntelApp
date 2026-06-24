import Foundation
import Photos

@MainActor
final class PhotoResourceService: PhotoResourceProviding {
    private var resourceLookup: [String: PHAssetResource] = [:]

    func resources(for localIdentifier: String) async -> [PhotoResourceInfo] {
        guard let asset = fetchAsset(localIdentifier: localIdentifier) else { return [] }

        let resources = PHAssetResource.assetResources(for: asset)
        var items: [PhotoResourceInfo] = []
        items.reserveCapacity(resources.count)

        for (index, resource) in resources.enumerated() {
            let id = makeResourceId(assetId: localIdentifier, index: index, resource: resource)
            resourceLookup[id] = resource

            items.append(
                PhotoResourceInfo(
                    id: id,
                    assetLocalIdentifier: localIdentifier,
                    resourceType: stringForType(resource.type),
                    uniformTypeIdentifier: resource.uniformTypeIdentifier,
                    originalFilename: resource.originalFilename,
                    fullSizePhotoDimensions: nil
                )
            )
        }

        return items
    }

    func copyResourceData(resourceId: String) async throws -> URL {
        guard let resource = resourceLookup[resourceId] else {
            throw NSError(domain: "PhotoResourceService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Resource not found in lookup cache"])
        }

        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("PhotoIntel", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil)

        let outputURL = tempDirectory.appendingPathComponent(UUID().uuidString + "_" + resource.originalFilename)
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHAssetResourceManager.default().writeData(for: resource, toFile: outputURL, options: nil) { error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: ())
            }
        }

        return outputURL
    }

    private func fetchAsset(localIdentifier: String) -> PHAsset? {
        let fetch = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        return fetch.firstObject
    }

    private func makeResourceId(assetId: String, index: Int, resource: PHAssetResource) -> String {
        "\(assetId)|\(index)|\(resource.type.rawValue)|\(resource.originalFilename)"
    }

    private func stringForType(_ type: PHAssetResourceType) -> String {
        switch type {
        case .photo:
            return "photo"
        case .video:
            return "video"
        case .audio:
            return "audio"
        case .alternatePhoto:
            return "alternatePhoto"
        case .fullSizePhoto:
            return "fullSizePhoto"
        case .fullSizeVideo:
            return "fullSizeVideo"
        case .adjustmentData:
            return "adjustmentData"
        case .adjustmentBasePhoto:
            return "adjustmentBasePhoto"
        case .pairedVideo:
            return "pairedVideo"
        case .fullSizePairedVideo:
            return "fullSizePairedVideo"
        case .adjustmentBasePairedVideo:
            return "adjustmentBasePairedVideo"
        default:
            return "unknown(\(type.rawValue))"
        }
    }
}
