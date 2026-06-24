import Foundation
import Photos

@MainActor
final class PhotoLibraryAuthorizationService: PhotoLibraryAuthorizationProviding {
    func requestAccess() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            let newStatus = await withCheckedContinuation { continuation in
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { updated in
                    continuation.resume(returning: updated)
                }
            }
            return newStatus == .authorized || newStatus == .limited
        @unknown default:
            return false
        }
    }
}
