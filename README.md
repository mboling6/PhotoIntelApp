# PhotoIntel

PhotoIntel is an iOS-first photo inspection app scaffold that unifies:

- Category 1: PhotoKit asset metadata
- Category 2: Embedded file metadata (EXIF/TIFF/GPS/IPTC/aux)
- Category 3: Asset resources (original/paired/adjustment/depth/matte resources)

## Current status

This folder contains production-style architecture and implementation code, separated into:

- `App/`: app entrypoint and composition root
- `Domain/Models/`: domain models used across layers
- `Data/Services/`: PhotoKit, resources, metadata parsing, report builder
- `Data/Formatting/`: metadata normalization helpers
- `Presentation/`: SwiftUI views and view model

## Create the iOS project in Xcode

1. Open Xcode and create a new iOS App project named `PhotoIntel`.
2. Choose Swift + SwiftUI.
3. Set deployment target to iOS 16 or newer.
4. In the new project, create matching groups and drag in all files from this folder.
5. Ensure `PhotoIntelApp.swift` is the app entrypoint for the target.

## Required iOS capabilities and privacy strings

Add to `Info.plist`:

- `NSPhotoLibraryUsageDescription` = "PhotoIntel needs access to your photos to inspect asset metadata and resources."

If you later add write/export back to library:

- `NSPhotoLibraryAddUsageDescription`

## What this implementation already does

- Requests read/write Photo Library permission
- Fetches latest photo/video assets
- Extracts category 1 summary fields from PhotoKit
- Enumerates category 3 resources with `PHAssetResource`
- Exports resource bytes to temp files for category 2 parsing
- Parses image metadata using ImageIO and basic video metadata with AVFoundation
- Builds a unified asset report shown in SwiftUI detail view
- Uses incremental paging for large libraries
- Caches built reports per selected asset to avoid repeated heavy parsing
- Formats common EXIF/GPS values (exposure, aperture, ISO, focal length, coordinates, altitude)

## TestFlight checklist

1. Configure bundle identifier and signing.
2. Add app privacy strings.
3. Test on real iPhone with:
   - HEIC/JPEG
   - Live Photos
   - RAW pairs
   - Edited assets
   - Portrait/depth captures
4. Archive and upload to App Store Connect.
5. Start with Internal TestFlight.

## Next implementation milestones

1. Pagination and incremental loading for large libraries
2. Rich formatted display for EXIF/GPS and resource diffs
3. JSON export for unified reports
4. Better video track metadata extraction
5. Unit tests for model mapping and report builder behavior
