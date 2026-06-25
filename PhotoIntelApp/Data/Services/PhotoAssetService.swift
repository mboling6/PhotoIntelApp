import Foundation
import Photos
import CoreLocation

@MainActor
final class PhotoAssetService: PhotoAssetProviding {
    private var cachedFetchResult: PHFetchResult<PHAsset>?
    private var cachedSummaryByIdentifier: [String: PhotoAssetSummary] = [:]

    func fetchAssets(limit: Int) async throws -> [PhotoAssetSummary] {
        try await fetchAssetsPage(offset: 0, limit: limit)
    }

    func fetchAssetsPage(offset: Int, limit: Int) async throws -> [PhotoAssetSummary] {
        let result = loadOrCreateFetchResult()
        guard offset < result.count else { return [] }

        let end = min(offset + limit, result.count)
        guard end > offset else { return [] }

        var items: [PhotoAssetSummary] = []
        items.reserveCapacity(end - offset)

        for index in offset..<end {
            let asset = result.object(at: index)
            let summary = mapAsset(asset)
            cachedSummaryByIdentifier[summary.localIdentifier] = summary
            items.append(summary)
        }

        return items
    }

    func totalAssetCount() async -> Int {
        loadOrCreateFetchResult().count
    }

    func fetchAssetSummary(localIdentifier: String) async -> PhotoAssetSummary? {
        if let cached = cachedSummaryByIdentifier[localIdentifier] {
            return cached
        }

        guard let asset = fetchAsset(localIdentifier: localIdentifier) else {
            return nil
        }

        let summary = mapAsset(asset)
        cachedSummaryByIdentifier[summary.localIdentifier] = summary
        return summary
    }

    private func loadOrCreateFetchResult() -> PHFetchResult<PHAsset> {
        if let cachedFetchResult {
            return cachedFetchResult
        }

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let results = PHAsset.fetchAssets(with: options)
        cachedFetchResult = results
        return results
    }

    func fetchCollectionNames(for localIdentifier: String) async -> [String] {
        guard let asset = fetchAsset(localIdentifier: localIdentifier) else { return [] }

        var names: [String] = []

        let addCollectionName: (PHAssetCollection) -> Void = { collection in
            let fetch = PHAsset.fetchAssets(in: collection, options: nil)
            fetch.enumerateObjects { candidate, _, stop in
                if candidate.localIdentifier == asset.localIdentifier {
                    names.append(collection.localizedTitle ?? "Untitled Collection")
                    stop.pointee = true
                }
            }
        }

        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
        smartAlbums.enumerateObjects { collection, _, _ in
            addCollectionName(collection)
        }

        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        userAlbums.enumerateObjects { collection, _, _ in
            addCollectionName(collection)
        }

        return Array(Set(names)).sorted()
    }

    private func fetchAsset(localIdentifier: String) -> PHAsset? {
        let fetch = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        return fetch.firstObject
    }

    private func mapAsset(_ asset: PHAsset) -> PhotoAssetSummary {
        let mediaKind: MediaKind
        switch asset.mediaType {
        case .image:
            mediaKind = .image
        case .video:
            mediaKind = .video
        case .audio:
            mediaKind = .audio
        default:
            mediaKind = .unknown
        }

        let location = asset.location?.coordinate
        return PhotoAssetSummary(
            id: asset.localIdentifier,
            localIdentifier: asset.localIdentifier,
            mediaKind: mediaKind,
            contentTypeIdentifier: asset.contentType.identifier,
            width: asset.pixelWidth,
            height: asset.pixelHeight,
            duration: asset.duration,
            isFavorite: asset.isFavorite,
            isHidden: asset.isHidden,
            representsBurst: asset.representsBurst,
            burstIdentifier: asset.burstIdentifier,
            burstSelectionTypes: burstSelectionTypesDescription(asset.burstSelectionTypes),
            hasAdjustments: asset.hasAdjustments,
            addedDate: asset.addedDate,
            creationDate: asset.creationDate,
            modificationDate: asset.modificationDate,
            location: location,
            sourceType: sourceDescription(asset.sourceType),
            mediaSubtypes: subtypesDescription(asset.mediaSubtypes)
        )
    }

    private func sourceDescription(_ sourceType: PHAssetSourceType) -> String {
        var parts: [String] = []
        if sourceType.contains(.typeUserLibrary) { parts.append("UserLibrary") }
        if sourceType.contains(.typeCloudShared) { parts.append("CloudShared") }
        if sourceType.contains(.typeiTunesSynced) { parts.append("iTunesSynced") }
        return parts.isEmpty ? "Unknown" : parts.joined(separator: ", ")
    }

    private func subtypesDescription(_ subtypes: PHAssetMediaSubtype) -> [String] {
        var values: [String] = []
        if subtypes.contains(.photoPanorama) { values.append("Panorama") }
        if subtypes.contains(.photoHDR) { values.append("HDR") }
        if subtypes.contains(.photoLive) { values.append("Live") }
        if subtypes.contains(.photoDepthEffect) { values.append("DepthEffect") }
        if subtypes.contains(.photoScreenshot) { values.append("Screenshot") }
        if subtypes.contains(.videoHighFrameRate) { values.append("HighFrameRate") }
        if subtypes.contains(.videoTimelapse) { values.append("Timelapse") }
        if subtypes.contains(.videoCinematic) { values.append("Cinematic") }
        return values
    }

    private func burstSelectionTypesDescription(_ types: PHAssetBurstSelectionType) -> [String] {
        var values: [String] = []
        if types.contains(.autoPick) { values.append("AutoPick") }
        if types.contains(.userPick) { values.append("UserPick") }
        return values
    }
}
