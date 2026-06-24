import Foundation
import SwiftUI
import CoreLocation

struct RootView: View {
    @StateObject private var viewModel: PhotoLibraryViewModel

    init(viewModel: PhotoLibraryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $viewModel.selectedAssetIdentifier) {
                ForEach(viewModel.assets, id: \.localIdentifier) { asset in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(asset.mediaKind.rawValue.capitalized)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(asset.localIdentifier)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .tag(asset.localIdentifier)
                    .onAppear {
                        Task {
                            await viewModel.loadMoreAssetsIfNeeded(currentAssetID: asset.localIdentifier)
                        }
                    }
                }

                if viewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            }
            .navigationTitle("Assets")
            .toolbar {
                Button("Reload") {
                    Task { await viewModel.authorizeAndLoad() }
                }
            }
            .onChange(of: viewModel.selectedAssetIdentifier) { _, _ in
                Task { await viewModel.loadSelectedReport() }
            }
        } detail: {
            if let report = viewModel.selectedReport {
                ReportDetailView(report: report)
            } else if viewModel.isLoading {
                ProgressView("Loading...")
            } else {
                ContentUnavailableView("No Selection", systemImage: "photo.on.rectangle")
            }
        }
        .task {
            viewModel.onAppear()
        }
        .alert("Error", isPresented: Binding(get: {
            viewModel.errorMessage != nil
        }, set: { _ in
            viewModel.clearError()
        })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }
}

private struct ReportDetailView: View {
    let report: UnifiedPhotoReport

    var body: some View {
        List {
            Section("Category 1 - PhotoKit") {
                kv("Identifier", report.summary.localIdentifier)
                kv("Media Kind", report.summary.mediaKind.rawValue)
                kv("Dimensions", "\(report.summary.width)x\(report.summary.height)")
                kv("Duration", report.summary.duration > 0 ? String(format: "%.2f s", report.summary.duration) : "-")
                kv("Favorite", report.summary.isFavorite ? "Yes" : "No")
                kv("Hidden", report.summary.isHidden ? "Yes" : "No")
                kv("Created", MetadataDisplayFormatter.dateString(report.summary.creationDate))
                kv("Modified", MetadataDisplayFormatter.dateString(report.summary.modificationDate))
                if let location = report.summary.location {
                    kv("Location", String(format: "%.6f, %.6f", location.latitude, location.longitude))
                }
                kv("Source", report.summary.sourceType)
                kv("Subtypes", report.summary.mediaSubtypes.joined(separator: ", "))
                kv("Collections", report.collections.joined(separator: ", "))
            }

            Section("Category 3 - Resources") {
                ForEach(report.resources, id: \.id) { resource in
                    VStack(alignment: .leading) {
                        Text(resource.resourceType)
                            .fontWeight(.semibold)
                        Text(resource.originalFilename)
                            .foregroundStyle(.secondary)
                        if let uti = resource.uniformTypeIdentifier {
                            Text(uti)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Category 2 - Embedded Metadata") {
                ForEach(report.resources, id: \.id) { resource in
                    if let metadata = report.embeddedMetadataByResourceId[resource.id] {
                        DisclosureGroup(resource.originalFilename) {
                            MetadataDictionaryView(title: "Root", dictionary: metadata.rootProperties)
                            MetadataDictionaryView(title: "EXIF", dictionary: metadata.exif)
                            MetadataDictionaryView(title: "TIFF", dictionary: metadata.tiff)
                            MetadataDictionaryView(title: "GPS", dictionary: metadata.gps)
                            MetadataDictionaryView(title: "IPTC", dictionary: metadata.iptc)
                            MetadataDictionaryView(title: "MakerApple", dictionary: metadata.makerApple)
                            MetadataDictionaryView(title: "ExifAux", dictionary: metadata.exifAux)
                        }
                    }
                }
            }
        }
        .navigationTitle("Asset Report")
    }

    private func kv(_ key: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(key)
                .fontWeight(.medium)
            Spacer()
            Text(value.isEmpty ? "-" : value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct MetadataDictionaryView: View {
    let title: String
    let dictionary: [String: AnyHashable]

    var body: some View {
        if !dictionary.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                ForEach(dictionary.keys.sorted(), id: \.self) { key in
                    HStack(alignment: .top) {
                        Text(key)
                        Spacer()
                        Text(
                            dictionary[key].map { MetadataDisplayFormatter.metadataValue(forKey: key, value: $0) }
                            ?? ""
                        )
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                    .font(.caption)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
