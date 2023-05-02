//
//  CreateAccount.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/31/22.
//

import SwiftUI

// MARK: - CreateAccount
struct CreateAccount: View {
    @EnvironmentObject var auth: FirebaseAuthProvider
    @EnvironmentObject var eh: ErrorHandling
    @State private var name: String = ""
    @State private var login: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""

    @Binding var isActive: Bool

    var body: some View {
        VStack {
            TextField("Username", text: $name)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 16)

            TextField("Email", text: $login)
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 16)

            SecureInputView("Password", text: $password)
                .padding(.horizontal, 16)
                .textFieldStyle(.roundedBorder)

            SecureInputView("Confirm Password", text: $confirmPassword)
                .padding(.horizontal, 16)
                .textFieldStyle(.roundedBorder)

            if password != confirmPassword {
                Text("Passwords do not match!")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
            }

            Spacer()

            Button {
                Task {
                    do {
                        try await auth.createAccount(with: name, email: login, password: password)
                        isActive = false
                    } catch {
                        eh.handle(title: "Error Creating Account", message: "\(error.localizedDescription)")
                    }
                }
            } label: {
                Text("Submit")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .contentShape(Capsule())
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .disabled((login.isEmpty || password.isEmpty) || (password != confirmPassword)
            )
            .buttonStyle(.plain)
        }
        .padding()
    }
}

struct CreateAccount_Previews: PreviewProvider {
    static var previews: some View {
        CreateAccount(isActive: .constant(true))
    }
}
