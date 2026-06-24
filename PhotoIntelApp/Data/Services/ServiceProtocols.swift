import Foundation

protocol PhotoLibraryAuthorizationProviding {
    func requestAccess() async -> Bool
}

protocol PhotoAssetProviding {
    func fetchAssets(limit: Int) async throws -> [PhotoAssetSummary]
    func fetchAssetsPage(offset: Int, limit: Int) async throws -> [PhotoAssetSummary]
    func totalAssetCount() async -> Int
    func fetchAssetSummary(localIdentifier: String) async -> PhotoAssetSummary?
    func fetchCollectionNames(for localIdentifier: String) async -> [String]
}

protocol PhotoResourceProviding {
    func resources(for localIdentifier: String) async -> [PhotoResourceInfo]
    func copyResourceData(resourceId: String) async throws -> URL
}

protocol EmbeddedMetadataProviding {
    func parseMetadata(from fileURL: URL) async -> EmbeddedMetadataBundle
}

protocol UnifiedPhotoReportProviding {
    func buildReport(for localIdentifier: String) async throws -> UnifiedPhotoReport
}
