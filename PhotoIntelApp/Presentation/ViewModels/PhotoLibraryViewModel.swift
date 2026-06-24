import Foundation
import Combine

@MainActor
final class PhotoLibraryViewModel: ObservableObject {
    private let pageSize = 100

    @Published private(set) var isAuthorized = false
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMoreAssets = true
    @Published private(set) var assets: [PhotoAssetSummary] = []
    @Published var selectedAssetIdentifier: String?
    @Published private(set) var selectedReport: UnifiedPhotoReport?
    @Published private(set) var errorMessage: String?

    private let authorizationProvider: PhotoLibraryAuthorizationProviding
    private let assetProvider: PhotoAssetProviding
    private let reportBuilder: UnifiedPhotoReportProviding
    private var currentOffset = 0
    private var totalAssetCount = 0
    private var reportCache: [String: UnifiedPhotoReport] = [:]

    init(
        authorizationProvider: PhotoLibraryAuthorizationProviding,
        assetProvider: PhotoAssetProviding,
        reportBuilder: UnifiedPhotoReportProviding
    ) {
        self.authorizationProvider = authorizationProvider
        self.assetProvider = assetProvider
        self.reportBuilder = reportBuilder
    }

    func onAppear() {
        Task {
            await authorizeAndLoad()
        }
    }

    func authorizeAndLoad() async {
        isLoading = true
        defer { isLoading = false }

        isAuthorized = await authorizationProvider.requestAccess()
        guard isAuthorized else {
            errorMessage = "Photo Library access was denied or restricted."
            return
        }

        do {
            resetPaginationState()
            totalAssetCount = await assetProvider.totalAssetCount()
            let firstPage = try await assetProvider.fetchAssetsPage(offset: 0, limit: pageSize)
            assets = firstPage
            currentOffset = assets.count
            hasMoreAssets = currentOffset < totalAssetCount

            if selectedAssetIdentifier == nil {
                selectedAssetIdentifier = assets.first?.localIdentifier
            }
            await loadSelectedReport()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMoreAssetsIfNeeded(currentAssetID: String?) async {
        guard let currentAssetID,
              hasMoreAssets,
              !isLoading,
              !isLoadingMore,
              let currentIndex = assets.firstIndex(where: { $0.localIdentifier == currentAssetID }) else {
            return
        }

        let thresholdIndex = max(assets.count - 20, 0)
        guard currentIndex >= thresholdIndex else {
            return
        }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let page = try await assetProvider.fetchAssetsPage(offset: currentOffset, limit: pageSize)
            assets.append(contentsOf: page)
            currentOffset = assets.count
            hasMoreAssets = currentOffset < totalAssetCount
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadSelectedReport() async {
        guard let id = selectedAssetIdentifier else {
            selectedReport = nil
            return
        }

        if let cached = reportCache[id] {
            selectedReport = cached
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let report = try await reportBuilder.buildReport(for: id)
            reportCache[id] = report
            selectedReport = report
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func resetPaginationState() {
        currentOffset = 0
        totalAssetCount = 0
        hasMoreAssets = true
        assets = []
        reportCache = [:]
    }
}
