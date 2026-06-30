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
                        Text("Use arrows to reorder")
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
                    }
                    .padding(.horizontal, DS.Spacing.s2)
                    .padding(.top, DS.Spacing.s2)
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
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(BrandSecondaryButtonStyle(expandHorizontally: true))
                .disabled(!canAddPhoto || isImportingPhotos)
                .optionalAccessibilityIdentifier(A11yID.puzzleFormChoosePhotoButton)
                .accessibilityLabel(remainingPhotoSlots == 1 ? "Add photo" : "Add photos")
                .accessibilityHint("Choose one or more photos from your library")

                if isCameraAvailable {
                    Button {
                        showCameraPicker = true
                    } label: {
                        Label("Camera", systemImage: "camera")
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(BrandPrimaryButtonStyle(expandHorizontally: true))
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
            .contentShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Photo \(index + 1) of \(sortedPhotos.count)\(photo.sortOrder == 0 ? ", cover" : "")")
            .accessibilityHint(sortedPhotos.count > 1 ? "Use the reorder buttons, adjustable action, or actions menu" : "")
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

            if sortedPhotos.count > 1 {
                HStack(spacing: DS.Spacing.s2) {
                    reorderButton(
                        systemImage: "chevron.left",
                        label: "Move photo \(index + 1) earlier",
                        disabled: index == 0
                    ) {
                        movePhotoOneStepEarlier(photo.id)
                    }

                    reorderButton(
                        systemImage: "chevron.right",
                        label: "Move photo \(index + 1) later",
                        disabled: index == sortedPhotos.count - 1
                    ) {
                        movePhotoOneStepLater(photo.id)
                    }
                }
                .padding(DS.Spacing.s2)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }

            Button {
                pendingPhotoRemovalID = photo.id
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.55))
            }
            .padding(DS.Spacing.s2)
            .accessibilityLabel("Remove photo \(index + 1)")
        }
    }

    private func reorderButton(
        systemImage: String,
        label: String,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(.black.opacity(disabled ? 0.25 : 0.55), in: Circle())
        }
        .disabled(disabled)
        .accessibilityLabel(label)
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
