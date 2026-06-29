//
//  PuzzlePhotoGalleryEditor.swift
//  Puzzle Buddy
//

import PhotosUI
import SwiftUI

struct PuzzlePhotoGalleryEditor: View {
    @Binding var photos: [PuzzlePhoto]
    @State private var showCameraPicker = false
    @State private var pendingImage = UIImage()
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isImportingPhotos = false
    @State private var pendingPhotoRemovalID: UUID?

    private var sortedPhotos: [PuzzlePhoto] {
        PuzzlePhotoSemantics.photosInOrder(photos)
    }

    private var canAddPhoto: Bool {
        photos.count < PuzzlePhotoLimits.maxCount
    }

    private var remainingPhotoSlots: Int {
        max(PuzzlePhotoLimits.maxCount - photos.count, 0)
    }

    private var photoCountLabel: String {
        "\(photos.count) of \(PuzzlePhotoLimits.maxCount) photos"
    }

    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            if !sortedPhotos.isEmpty {
                HStack(spacing: DS.Spacing.s2) {
                    Text(photoCountLabel)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Brand.textSecondary)

                    if sortedPhotos.count > 1 {
                        Text("Drag to reorder")
                            .font(.caption)
                            .foregroundStyle(Brand.textSecondary)
                    }

                    Spacer()

                    if isImportingPhotos {
                        ProgressView()
                            .controlSize(.small)
                            .accessibilityLabel("Importing photos")
                    }
                }
            }

            if sortedPhotos.isEmpty {
                emptyPlaceholder
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Spacing.s3) {
                        ForEach(Array(sortedPhotos.enumerated()), id: \.element.id) { index, photo in
                            photoTile(photo: photo, index: index)
                        }

                        if sortedPhotos.count > 1 {
                            moveToEndDropZone
                        }
                    }
                    .padding(.horizontal, DS.Spacing.s2)
                }
            }

            HStack(spacing: DS.Spacing.s2) {
                PhotosPicker(
                    selection: $pickerItems,
                    maxSelectionCount: max(remainingPhotoSlots, 1),
                    matching: .images
                ) {
                    Label(
                        remainingPhotoSlots == 1 ? "Add photo" : "Add photos",
                        systemImage: "photo.on.rectangle"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(BrandSecondaryButtonStyle())
                .disabled(!canAddPhoto || isImportingPhotos)
                .optionalAccessibilityIdentifier(A11yID.puzzleFormChoosePhotoButton)
                .accessibilityLabel(remainingPhotoSlots == 1 ? "Add photo" : "Add photos")
                .accessibilityHint("Choose one or more photos from your library")

                if isCameraAvailable {
                    Button {
                        showCameraPicker = true
                    } label: {
                        Label("Camera", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(BrandPrimaryButtonStyle())
                    .disabled(!canAddPhoto || isImportingPhotos)
                    .optionalAccessibilityIdentifier(A11yID.puzzleFormTakePhotoButton)
                }
            }
        }
        .padding(.vertical, DS.Spacing.s2)
        .onChange(of: pickerItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            Task { await appendPhotos(from: newItems) }
        }
        .fullScreenCover(isPresented: $showCameraPicker) {
            ImagePicker(sourceType: .camera, selectedImage: $pendingImage)
                .onDisappear { appendPendingImageIfNeeded() }
        }
        .confirmationDialog(
            "Remove photo?",
            isPresented: Binding(
                get: { pendingPhotoRemovalID != nil },
                set: { if !$0 { pendingPhotoRemovalID = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                if let id = pendingPhotoRemovalID {
                    removePhoto(id: id)
                }
                pendingPhotoRemovalID = nil
            }
            Button("Cancel", role: .cancel) {
                pendingPhotoRemovalID = nil
            }
        } message: {
            Text("This photo will be removed from the puzzle.")
        }
    }

    private var emptyPlaceholder: some View {
        VStack(spacing: DS.Spacing.s2) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(Brand.accent.opacity(0.8))

            Text("Add box art, progress, or finished shots")
                .font(.subheadline)
                .foregroundStyle(Brand.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(Brand.cardElevated)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No photos yet. Add box art, progress, or finished shots.")
    }

    private var moveToEndDropZone: some View {
        RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .foregroundStyle(Brand.textSecondary.opacity(0.45))
            .frame(width: 44, height: 100)
            .overlay {
                Image(systemName: "arrow.right.to.line")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Brand.textSecondary)
            }
            .dropDestination(for: String.self) { items, _ in
                guard let draggedID = items.first.flatMap(UUID.init(uuidString:)) else { return false }
                movePhotoToEnd(draggedID)
                return true
            }
            .accessibilityLabel("Move photo to end")
            .accessibilityHint("Drop a photo here to move it to the end of the gallery")
    }

    @ViewBuilder
    private func photoTile(photo: PuzzlePhoto, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let image = photo.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.clear
                }
            }
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                    .strokeBorder(photo.sortOrder == 0 ? Brand.accent : Color.clear, lineWidth: 2)
            }
            .overlay(alignment: .bottomLeading) {
                photoBadge(for: photo)
            }
            .overlay(alignment: .bottomTrailing) {
                if sortedPhotos.count > 1 {
                    Image(systemName: "line.3.horizontal")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(5)
                        .background(.black.opacity(0.45), in: Circle())
                        .padding(DS.Spacing.s2)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Photo \(index + 1) of \(sortedPhotos.count)\(photo.sortOrder == 0 ? ", cover" : "")")
            .accessibilityHint(sortedPhotos.count > 1 ? "Drag to reorder, or use the actions menu" : "")
            .accessibilityAdjustableAction { direction in
                guard sortedPhotos.count > 1 else { return }
                switch direction {
                case .increment:
                    movePhotoOneStepLater(photo.id)
                case .decrement:
                    movePhotoOneStepEarlier(photo.id)
                @unknown default:
                    break
                }
            }
            .if(sortedPhotos.count > 1) { view in
                view
                    .draggable(photo.id.uuidString) {
                        photoDragPreview(for: photo)
                    }
                    .dropDestination(for: String.self) { items, _ in
                        guard let draggedID = items.first.flatMap(UUID.init(uuidString:)),
                              draggedID != photo.id else {
                            return false
                        }
                        movePhoto(from: draggedID, before: photo.id)
                        return true
                    }
            }
            .contextMenu {
                if photo.sortOrder != 0 {
                    Button("Set as cover") {
                        setAsCover(photo.id)
                    }
                }
                if index > 0 {
                    Button("Move earlier") {
                        movePhotoOneStepEarlier(photo.id)
                    }
                }
                if index < sortedPhotos.count - 1 {
                    Button("Move later") {
                        movePhotoOneStepLater(photo.id)
                    }
                }
                Button("Remove", role: .destructive) {
                    pendingPhotoRemovalID = photo.id
                }
            }

            Button {
                pendingPhotoRemovalID = photo.id
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.55))
            }
            .offset(x: 6, y: -6)
            .accessibilityLabel("Remove photo \(index + 1)")
        }
    }

    @ViewBuilder
    private func photoBadge(for photo: PuzzlePhoto) -> some View {
        if photo.sortOrder == 0 {
            Text("Cover")
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, DS.Spacing.s2)
                .padding(.vertical, 2)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(DS.Spacing.s2)
        }
    }

    @ViewBuilder
    private func photoDragPreview(for photo: PuzzlePhoto) -> some View {
        if let image = photo.image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))
        }
    }

    @MainActor
    private func appendPhotos(from items: [PhotosPickerItem]) async {
        defer { pickerItems = [] }
        guard remainingPhotoSlots > 0 else { return }

        isImportingPhotos = true
        defer { isImportingPhotos = false }

        var imported: [UIImage] = []
        for item in items.prefix(remainingPhotoSlots) {
            if let image = await loadPickerImage(from: item) {
                imported.append(image)
            }
        }
        guard !imported.isEmpty else { return }

        var updated = photos
        let nextOrder = (updated.map(\.sortOrder).max() ?? -1) + 1
        for (offset, image) in imported.enumerated() {
            updated.append(PuzzlePhoto(sortOrder: nextOrder + offset, image: image))
        }
        photos = PuzzlePhotoSemantics.normalizedSortOrders(updated)
    }

    private func loadPickerImage(from item: PhotosPickerItem) async -> UIImage? {
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data),
           image.cgImage != nil {
            return image
        }

        return nil
    }

    private func appendPendingImageIfNeeded() {
        guard pendingImage.cgImage != nil else {
            pendingImage = UIImage()
            return
        }
        let nextOrder = (photos.map(\.sortOrder).max() ?? -1) + 1
        photos.append(PuzzlePhoto(sortOrder: nextOrder, image: pendingImage))
        photos = PuzzlePhotoSemantics.normalizedSortOrders(photos)
        pendingImage = UIImage()
    }

    private func removePhoto(id: UUID) {
        photos.removeAll { $0.id == id }
        photos = PuzzlePhotoSemantics.sortedAndNormalized(photos)
    }

    private func movePhoto(from sourceID: UUID, before destinationID: UUID) {
        photos = PuzzlePhotoSemantics.movingPhoto(id: sourceID, before: destinationID, in: photos)
    }

    private func movePhotoToEnd(_ photoID: UUID) {
        photos = PuzzlePhotoSemantics.movingPhotoToEnd(id: photoID, in: photos)
    }

    private func movePhotoOneStepEarlier(_ photoID: UUID) {
        photos = PuzzlePhotoSemantics.movingPhotoOneStep(id: photoID, direction: .earlier, in: photos)
    }

    private func movePhotoOneStepLater(_ photoID: UUID) {
        photos = PuzzlePhotoSemantics.movingPhotoOneStep(id: photoID, direction: .later, in: photos)
    }

    private func setAsCover(_ photoID: UUID) {
        photos = PuzzlePhotoSemantics.movingPhotoToCover(id: photoID, in: photos)
    }
}

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct PuzzlePhotoGalleryDetail: View {
    let photos: [PuzzlePhoto]
    let puzzleName: String

    private var sortedPhotos: [PuzzlePhoto] {
        PuzzlePhotoSemantics.photosInOrder(photos)
    }

    var body: some View {
        if sortedPhotos.isEmpty {
            placeholder
        } else if sortedPhotos.count == 1, let image = sortedPhotos[0].image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: 200, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
                .padding(.horizontal)
                .accessibilityLabel("Puzzle photo for \(puzzleName)")
        } else {
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: DS.Spacing.s3) {
                    ForEach(Array(sortedPhotos.enumerated()), id: \.element.id) { index, photo in
                        if let image = photo.image {
                            ZStack(alignment: .bottomLeading) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 140, height: 140)
                                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))

                                if photo.sortOrder == 0 {
                                    Text("Cover")
                                        .font(.caption2.weight(.semibold))
                                        .padding(.horizontal, DS.Spacing.s2)
                                        .padding(.vertical, 2)
                                        .background(.ultraThinMaterial, in: Capsule())
                                        .padding(DS.Spacing.s2)
                                }
                            }
                            .accessibilityLabel(
                                "Photo \(index + 1) of \(sortedPhotos.count) for \(puzzleName)\(photo.sortOrder == 0 ? ", cover" : "")"
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var placeholder: some View {
        Image(systemName: "puzzlepiece.extension.fill")
            .resizable()
            .foregroundStyle(Brand.accent)
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: 150, alignment: .center)
            .padding()
            .accessibilityLabel("No puzzle photo")
    }
}
