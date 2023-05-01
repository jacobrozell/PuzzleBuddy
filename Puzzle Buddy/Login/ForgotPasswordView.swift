//
//  ForgotPasswordView.swift
//  IAFC
//
//  Created by Jacob Rozell on 8/2/22.
//

import FirebaseAuth
import SwiftUI

@MainActor
class ForgotPasswordViewModel: ObservableObject {
    enum State {
        case idle
        case verify
        case success
        case error(Error)
    }

    @Published var state: State = .idle
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var passwordConfirm: String = ""
    @Published var verificationCode: String = ""

    var isValid: Bool {
        !username.isEmpty
        && !verificationCode.isEmpty
        && !password.isEmpty
        && !passwordConfirm.isEmpty
        && password == passwordConfirm
    }

    func forgotPassword() async throws {
        guard !username.isEmpty else {
            //            throw AmplifyError.authError(title: "Empty Username", error: .)
            print("Oops")
            return
        }

        try await Auth.auth().sendPasswordReset(withEmail: username)
        state = .verify
    }

    func confirmsResetPassword(completion: @escaping (Bool) -> Void) async throws {
        try await Auth.auth().verifyPasswordResetCode(verificationCode)
        self.state = .success
    }
}


struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var vm = ForgotPasswordViewModel()
    @EnvironmentObject var eh: ErrorHandling

    var body: some View {
        switch vm.state {
        case .idle:
            idle

        case .verify:
            verify

        case .error(let error):
            Text("Error")
                .overlay(Text("\(error.localizedDescription)"))

        case .success:
            Text("Success")
        }
    }

    private var idle: some View {
        GroupBox {
            TextField("Email", text: $vm.username, prompt: Text("Email"))
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .textContentType(.emailAddress)
                .disableAutocorrection(true)
                .padding()

            Spacer()

            Button {
                Task {
                    do {
                        try await vm.forgotPassword()
                    } catch {
                        eh.handle(title: "Forgot Password Failed", message: "Please try again.")
                    }
                }
            } label: {
                Text("Submit")
            }
            .padding(.vertical)
        }
    }

    private var verify: some View {
        GroupBox {
            Text("A password reset has been sent to \(vm.username)")

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Close")
            }
            .disabled(!vm.isValid)
            .padding(.vertical)
        }
    }
}

struct ForgotPassword_Preview: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}
