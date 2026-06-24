import Foundation

@MainActor
final class UnifiedPhotoReportBuilder: UnifiedPhotoReportProviding {
    private let assetProvider: PhotoAssetProviding
    private let resourceProvider: PhotoResourceProviding
    private let metadataProvider: EmbeddedMetadataProviding

    init(
        assetProvider: PhotoAssetProviding,
        resourceProvider: PhotoResourceProviding,
        metadataProvider: EmbeddedMetadataProviding
    ) {
        self.assetProvider = assetProvider
        self.resourceProvider = resourceProvider
        self.metadataProvider = metadataProvider
    }

    func buildReport(for localIdentifier: String) async throws -> UnifiedPhotoReport {
        guard let summary = await assetProvider.fetchAssetSummary(localIdentifier: localIdentifier) else {
            throw NSError(domain: "UnifiedPhotoReportBuilder", code: 404, userInfo: [NSLocalizedDescriptionKey: "Asset not found"])
        }

        let collections = await assetProvider.fetchCollectionNames(for: localIdentifier)
        let resources = await resourceProvider.resources(for: localIdentifier)

        var metadataMap: [String: EmbeddedMetadataBundle] = [:]
        for resource in resources {
            do {
                let fileURL = try await resourceProvider.copyResourceData(resourceId: resource.id)
                metadataMap[resource.id] = await metadataProvider.parseMetadata(from: fileURL)
            } catch {
                metadataMap[resource.id] = EmbeddedMetadataBundle(
                    rootProperties: ["error": AnyHashable(error.localizedDescription)],
                    exif: [:],
                    tiff: [:],
                    gps: [:],
                    iptc: [:],
                    makerApple: [:],
                    exifAux: [:]
                )
            }
        }

        return UnifiedPhotoReport(
            id: localIdentifier,
            summary: summary,
            collections: collections,
            resources: resources,
            embeddedMetadataByResourceId: metadataMap,
            generatedAt: Date()
        )
    }
}
