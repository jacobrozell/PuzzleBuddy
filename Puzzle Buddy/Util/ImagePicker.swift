//
//  ImagePicker.swift
//  Puzzle Buddy
//

import SwiftUI

struct ImagePickerView: View {
    @Binding var image: UIImage
    @State private var showSheet = false
    @State private var showSheet2 = false

    var body: some View {
        VStack(spacing: DS.Spacing.s3) {
            Group {
                if image.cgImage == nil {
                    Image(systemName: "photo.circle.fill")
                        .font(.system(size: 96))
                        .foregroundStyle(Brand.accent, Brand.cardElevated)
                } else {
                    Image(uiImage: self.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(Brand.accent.opacity(0.35), lineWidth: 2))
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)

            HStack(spacing: DS.Spacing.s2) {
                Button {
                    showSheet = true
                } label: {
                    Text("Choose photo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BrandSecondaryButtonStyle())
                .optionalAccessibilityIdentifier(A11yID.puzzleFormChoosePhotoButton)
                .accessibilityLabel("Choose photo from library")

                Button {
                    showSheet2 = true
                } label: {
                    Text("Take photo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BrandPrimaryButtonStyle())
                .optionalAccessibilityIdentifier(A11yID.puzzleFormTakePhotoButton)
                .accessibilityLabel("Take photo with camera")
            }
        }
        .padding()
        .sheet(isPresented: $showSheet) {
            ImagePicker(sourceType: .photoLibrary, selectedImage: self.$image)
        }
        .fullScreenCover(isPresented: $showSheet2) {
            ImagePicker(sourceType: .camera, selectedImage: self.$image)
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Binding var selectedImage: UIImage

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator
        return imagePicker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ImagePickerPreivew: PreviewProvider {
    static var previews: some View {
        ImagePickerView(image: .constant(UIImage()))
    }
}
