import SwiftUI

// MARK: - SecureInputView
struct SecureInputView: View {
    @Binding private var text: String
    @State private var isSecured: Bool = true
    private var title: String

    init(_ title: String, text: Binding<String>) {
        self.title = title
        self._text = text
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            Group {
                if isSecured {
                    SecureField(title, text: $text)
                        .textContentType(.password)
                        .keyboardType(.default)
//                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                } else {
                    TextField(title, text: $text)
                        .textContentType(.password)
                        .keyboardType(.default)
//                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                }
            }
            .contentShape(Rectangle())

            Button(action: {
                isSecured.toggle()
            }) {
                Image(systemName: self.isSecured ? "eye.slash" : "eye")
                    .accentColor(.gray)
                    .padding(4)
            }
            .frame(width: 50, height: 50, alignment: .center)
        }
    }
}
