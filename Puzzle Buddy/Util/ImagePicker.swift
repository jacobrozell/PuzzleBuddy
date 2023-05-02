import SwiftUI

struct ImagePickerView: View {
    @Binding var image: UIImage
    @State private var choosePhotoPresent = false
    @State private var takePhotoPresent = false

    var body: some View {
        VStack {
            Image(uiImage: self.image)
                .resizable()
                .frame(width: 150, height: 150)
                .aspectRatio(contentMode: .fill)
                .background {
                    PuzzleAnimation(.photo, loopMode: .autoReverse)
                        .padding(.horizontal)
                        .opacity(0.65)
                }
                .clipShape(Circle())

            HStack {
                Text("Choose photo")
                    .padding()
                    .font(.subheadline)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .cornerRadius(16)
                    .foregroundColor(.white)
                    .aspectRatio(contentMode: .fill)
                    .onTapGesture {
                        choosePhotoPresent = true
                    }
                
                Text("Take photo")
                    .padding()
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                    .background(Color.accentColor)
                    .cornerRadius(16)
                    .foregroundColor(.white)
                    .onTapGesture {
                        takePhotoPresent = true
                    }
            }

            if image != UIImage() {
                Button(role: .destructive) {
                    image = UIImage()
                } label: {
                    Text("Clear photo")
                        .underline()
                }
                .padding()
            }
        }
        .sheet(isPresented: $choosePhotoPresent) {
            ImagePicker(sourceType: .photoLibrary, selectedImage: self.$image)
        }
        .fullScreenCover(isPresented: $takePhotoPresent) {
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

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {

    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                parent.selectedImage = image
            }

            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ImagePickerPreivew: PreviewProvider {
    static var previews: some View {
        Group {
            ImagePickerView(image: .constant(UIImage()))
        }
    }
}
