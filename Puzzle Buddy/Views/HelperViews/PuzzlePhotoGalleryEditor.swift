//
//  PuzzlePhotoGalleryEditor.swift
//  Puzzle Buddy
//

import SwiftUI

struct PuzzlePhotoGalleryEditor: View {
    @Binding var photos: [PuzzlePhoto]
    @State private var showLibraryPicker = false
    @State private var showCameraPicker = false
    @State private var pendingImage = UIImage()

    private var sortedPhotos: [PuzzlePhoto] {
        PuzzlePhotoSemantics.sorted(photos)
    }

    private var canAddPhoto: Bool {
        photos.count < PuzzlePhotoLimits.maxCount
    }

    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
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
                }
            }

            HStack(spacing: DS.Spacing.s2) {
                Button {
                    showLibraryPicker = true
                } label: {
                    Label("Add photo", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BrandSecondaryButtonStyle())
                .disabled(!canAddPhoto)
                .optionalAccessibilityIdentifier(A11yID.puzzleFormChoosePhotoButton)

                if isCameraAvailable {
                    Button {
                        showCameraPicker = true
                    } label: {
                        Label("Camera", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(BrandPrimaryButtonStyle())
                    .disabled(!canAddPhoto)
                    .optionalAccessibilityIdentifier(A11yID.puzzleFormTakePhotoButton)
                }
            }
        }
        .padding(.vertical, DS.Spacing.s2)
        .sheet(isPresented: $showLibraryPicker) {
            ImagePicker(sourceType: .photoLibrary, selectedImage: $pendingImage)
                .onDisappear { appendPendingImageIfNeeded() }
        }
        .fullScreenCover(isPresented: $showCameraPicker) {
            ImagePicker(sourceType: .camera, selectedImage: $pendingImage)
                .onDisappear { appendPendingImageIfNeeded() }
        }
    }

    private var emptyPlaceholder: some View {
        HStack {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(Brand.accent.opacity(0.8))
            Spacer()
        }
        .frame(height: 120)
        .background(Brand.cardElevated)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
        .accessibilityLabel("No photos yet")
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
            .accessibilityLabel("Photo \(index + 1) of \(sortedPhotos.count)\(photo.sortOrder == 0 ? ", cover" : "")")

            Button {
                removePhoto(id: photo.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.55))
            }
            .offset(x: 6, y: -6)
            .accessibilityLabel("Remove photo \(index + 1)")
        }
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
        photos = PuzzlePhotoSemantics.normalizedSortOrders(photos)
    }
}

struct PuzzlePhotoGalleryDetail: View {
    let photos: [PuzzlePhoto]
    let puzzleName: String

    private var sortedPhotos: [PuzzlePhoto] {
        PuzzlePhotoSemantics.sorted(photos)
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
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 140, height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))
                                .accessibilityLabel("Photo \(index + 1) of \(sortedPhotos.count) for \(puzzleName)")
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
