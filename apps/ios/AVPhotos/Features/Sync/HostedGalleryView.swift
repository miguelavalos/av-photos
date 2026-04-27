import SwiftUI
import UIKit

struct HostedGalleryView: View {
    @EnvironmentObject private var hostedSyncController: HostedSyncController

    @State private var assetPendingDeletion: HostedPhotoAsset?
    @State private var selectedAsset: HostedPhotoAsset?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hostedStatusCard

                    if hostedSyncController.assets.isEmpty {
                        ContentUnavailableView(
                            L10n.string("sync.hosted.gallery.empty.title"),
                            systemImage: "photo.stack",
                            description: Text(L10n.string("sync.hosted.gallery.empty.detail"))
                        )
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(hostedSyncController.assets) { asset in
                                Button {
                                    selectedAsset = asset
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HostedAssetThumbnailView(asset: asset, size: 112, cornerRadius: 18)

                                        Text(asset.originalFilename)
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(AVPhotosTheme.textPrimary)
                                            .lineLimit(1)

                                        Text("\(asset.pixelWidth)x\(asset.pixelHeight)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .scrollContentBackground(.hidden)
            .background(AVPhotosTheme.shellBackground.ignoresSafeArea())
            .navigationTitle(L10n.string("tab.remote"))
            .task {
                await hostedSyncController.refresh()
            }
            .sheet(item: $selectedAsset) { asset in
                HostedGalleryDetailSheet(
                    assets: hostedSyncController.assets,
                    selectedAsset: asset,
                    onSelect: { selectedAsset = $0 },
                    onDelete: { assetPendingDeletion = $0 }
                )
                .environmentObject(hostedSyncController)
            }
            .alert(
                L10n.string("sync.hosted.delete.confirm.title"),
                isPresented: deleteAlertPresentedBinding,
                presenting: assetPendingDeletion
            ) { asset in
                Button(L10n.string("action.cancel"), role: .cancel) {
                    assetPendingDeletion = nil
                }
                Button(L10n.string("sync.hosted.delete"), role: .destructive) {
                    Task {
                        do {
                            try await hostedSyncController.deleteAsset(asset)
                        } catch {
                            await hostedSyncController.refresh()
                        }

                        if selectedAsset?.assetId == asset.assetId {
                            selectedAsset = nil
                        }
                        assetPendingDeletion = nil
                    }
                }
            } message: { asset in
                Text(L10n.string("sync.hosted.delete.confirm.message", asset.originalFilename))
            }
        }
    }

    private var hostedStatusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(statusTitle)
                .font(.headline)
                .foregroundStyle(AVPhotosTheme.textPrimary)

            Text(statusDetail)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(L10n.string("sync.hosted.refresh")) {
                Task {
                    await hostedSyncController.refresh()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AVPhotosTheme.cardSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AVPhotosTheme.borderSubtle.opacity(0.45), lineWidth: 1)
        )
    }

    private var statusTitle: String {
        switch hostedSyncController.hostedState {
        case .notConfigured:
            L10n.string("sync.hosted.status.notConfigured")
        case .checking:
            L10n.string("sync.hosted.status.checking")
        case .authRequired:
            L10n.string("sync.hosted.status.authRequired")
        case .forbidden:
            L10n.string("sync.hosted.status.forbidden")
        case .ready(let assetCount):
            assetCount == 0
                ? L10n.string("sync.hosted.status.readyEmpty")
                : L10n.string("sync.hosted.status.readyCount", assetCount)
        case .failed:
            L10n.string("sync.hosted.status.failed")
        }
    }

    private var statusDetail: String {
        switch hostedSyncController.hostedState {
        case .notConfigured:
            L10n.string("sync.hosted.detail.notConfigured")
        case .checking:
            L10n.string("sync.hosted.detail.checking")
        case .authRequired:
            L10n.string("sync.hosted.detail.authRequired")
        case .forbidden(let message):
            message
        case .ready:
            L10n.string("sync.hosted.gallery.detail.ready")
        case .failed(let message):
            message
        }
    }

    private var deleteAlertPresentedBinding: Binding<Bool> {
        Binding(
            get: { assetPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    assetPendingDeletion = nil
                }
            }
        )
    }
}

struct HostedGalleryDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var hostedSyncController: HostedSyncController

    let assets: [HostedPhotoAsset]
    let selectedAsset: HostedPhotoAsset
    let onSelect: (HostedPhotoAsset) -> Void
    let onDelete: (HostedPhotoAsset) -> Void

    @State private var selectedAssetID: String

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    init(
        assets: [HostedPhotoAsset],
        selectedAsset: HostedPhotoAsset,
        onSelect: @escaping (HostedPhotoAsset) -> Void,
        onDelete: @escaping (HostedPhotoAsset) -> Void
    ) {
        self.assets = assets
        self.selectedAsset = selectedAsset
        self.onSelect = onSelect
        self.onDelete = onDelete
        _selectedAssetID = State(initialValue: selectedAsset.assetId)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    TabView(selection: $selectedAssetID) {
                        ForEach(assets) { asset in
                            HostedAssetHeroView(asset: asset)
                                .tag(asset.assetId)
                        }
                    }
                    .frame(height: 420)
                    .tabViewStyle(.page(indexDisplayMode: .automatic))

                    VStack(alignment: .leading, spacing: 8) {
                        Text(activeAsset.originalFilename)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(AVPhotosTheme.textPrimary)

                        Text(assetMetadata(activeAsset))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Button(role: .destructive) {
                        onDelete(activeAsset)
                        dismiss()
                    } label: {
                        Label(L10n.string("sync.hosted.delete"), systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(hostedSyncController.deletingAssetID != nil)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.string("sync.hosted.gallery.more"))
                            .font(.headline)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(assets) { asset in
                                Button {
                                    selectedAssetID = asset.assetId
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HostedAssetThumbnailView(asset: asset, size: 104, cornerRadius: 18)

                                        Text(asset.originalFilename)
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(AVPhotosTheme.textPrimary)
                                            .lineLimit(1)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle(L10n.string("sync.hosted.gallery.title"))
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedAssetID) { _, newValue in
                guard let nextAsset = assets.first(where: { $0.assetId == newValue }) else { return }
                onSelect(nextAsset)
            }
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.string("action.done")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var activeAsset: HostedPhotoAsset {
        assets.first(where: { $0.assetId == selectedAssetID }) ?? selectedAsset
    }

    private func assetMetadata(_ asset: HostedPhotoAsset) -> String {
        "\(asset.pixelWidth)x\(asset.pixelHeight) • \(asset.byteSize) bytes • \(asset.syncStatus)"
    }
}

struct HostedAssetHeroView: View {
    let asset: HostedPhotoAsset

    var body: some View {
        ZoomableHostedAssetView(asset: asset)
            .frame(maxWidth: .infinity)
    }
}

private struct ZoomableHostedAssetView: View {
    let asset: HostedPhotoAsset

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.black)

                HostedAssetThumbnailView(asset: asset, size: max(proxy.size.width, proxy.size.height), cornerRadius: 28)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(dragGesture)
                    .simultaneousGesture(magnificationGesture)
                    .simultaneousGesture(doubleTapGesture)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .onChange(of: asset.assetId) { _, _ in
                resetTransform()
            }
        }
    }

    private var magnificationGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let nextScale = lastScale * value.magnification
                scale = min(max(nextScale, 1), 4)
                if scale <= 1.01 {
                    offset = .zero
                }
            }
            .onEnded { _ in
                lastScale = scale
                if scale <= 1.01 {
                    resetTransform()
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else { return }
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                guard scale > 1 else {
                    resetTransform()
                    return
                }
                lastOffset = offset
            }
    }

    private var doubleTapGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded {
                if scale > 1 {
                    resetTransform()
                } else {
                    scale = 2
                    lastScale = 2
                }
            }
    }

    private func resetTransform() {
        scale = 1
        lastScale = 1
        offset = .zero
        lastOffset = .zero
    }
}

struct HostedAssetThumbnailView: View {
    @EnvironmentObject private var hostedSyncController: HostedSyncController

    let asset: HostedPhotoAsset
    let size: CGFloat
    let cornerRadius: CGFloat

    @State private var image: UIImage?
    @State private var isLoading = false

    init(asset: HostedPhotoAsset, size: CGFloat = 56, cornerRadius: CGFloat = 12) {
        self.asset = asset
        self.size = size
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(AVPhotosTheme.cardSurface)

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if isLoading {
                ProgressView()
                    .tint(AVPhotosTheme.highlight)
            } else {
                Image(systemName: "photo")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(AVPhotosTheme.borderSubtle.opacity(0.5), lineWidth: 1)
        )
        .task(id: asset.previewPath ?? asset.assetId) {
            guard image == nil else { return }
            isLoading = true
            defer { isLoading = false }

            do {
                image = try await hostedSyncController.previewImage(for: asset)
            } catch {
                image = nil
            }
        }
    }
}
