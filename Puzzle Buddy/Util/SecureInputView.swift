import SwiftUI

// MARK: - SecureInputView
struct SecureInputView: View {
    @Binding private var text: String
    @State private var isSecured: Bool = true
    private var title: String
    private var accessibilityIdentifier: String?

    init(_ title: String, text: Binding<String>, accessibilityIdentifier: String? = nil) {
        self.title = title
        self._text = text
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    var body: some View {
        HStack(spacing: DS.Spacing.s2) {
            Group {
                if isSecured {
                    SecureField(title, text: $text)
                        .textContentType(.password)
                        .keyboardType(.default)
                        .autocapitalization(.none)
                        .optionalAccessibilityIdentifier(accessibilityIdentifier)
                } else {
                    TextField(title, text: $text)
                        .textContentType(.password)
                        .keyboardType(.default)
                        .autocapitalization(.none)
                        .optionalAccessibilityIdentifier(accessibilityIdentifier)
                }
            }
            .accessibilityLabel("Password")

            Button {
                isSecured.toggle()
            } label: {
                Image(systemName: isSecured ? "eye.slash" : "eye")
                    .foregroundStyle(Brand.textSecondary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(isSecured ? "Show password" : "Hide password")
            .accessibilityIdentifier(A11yID.passwordVisibilityToggle)
        }
    }
}
