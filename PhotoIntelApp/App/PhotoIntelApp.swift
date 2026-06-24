import SwiftUI

@main
struct PhotoIntelApp: App {
    var body: some Scene {
        WindowGroup {
            RootView(viewModel: compositionRoot())
        }
    }

    private func compositionRoot() -> PhotoLibraryViewModel {
        let authorization = PhotoLibraryAuthorizationService()
        let assets = PhotoAssetService()
        let resources = PhotoResourceService()
        let embedded = EmbeddedMetadataService()
        let builder = UnifiedPhotoReportBuilder(
            assetProvider: assets,
            resourceProvider: resources,
            metadataProvider: embedded
        )

        return PhotoLibraryViewModel(
            authorizationProvider: authorization,
            assetProvider: assets,
            reportBuilder: builder
        )
    }
}
