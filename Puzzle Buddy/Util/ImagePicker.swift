import SwiftUI

struct ImagePickerView: View {
    @Binding var image: UIImage
    @State private var showSheet = false
    @State private var showSheet2 = false

    var body: some View {
        VStack {
            Image(uiImage: self.image)
                .resizable()
                .cornerRadius(50)
                .frame(width: 150, height: 150)
                .background(Color.blue.opacity(0.2))
                .aspectRatio(contentMode: .fill)
                .clipShape(Circle())
                .overlay {
                    PuzzleAnimation(.photo, loopMode: .autoReverse)
                        .padding()
                        .opacity(0.65)
                }

            HStack {
                Text("Choose photo")
                    .padding()
                    .font(.headline)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .cornerRadius(16)
                    .foregroundColor(.white)
                    .padding(2)
                    .onTapGesture {
                        showSheet = true
                    }
                
                Text("Take photo")
                    .padding()
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                    .background(Color.accentColor)
                    .cornerRadius(16)
                    .foregroundColor(.white)
                    .padding(2)
                    .onTapGesture {
                        showSheet2 = true
                    }
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
