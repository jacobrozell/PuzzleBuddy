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
        case error(Error)
    }

    @Published var state: State = .idle
    @Published var username: String = ""

    var isValid: Bool {
        !username.isEmpty
    }

    func forgotPassword() async throws {
        guard !username.isEmpty else {
            print("Oops")
            return
        }

        try await Auth.auth().sendPasswordReset(withEmail: username)
        state = .verify
    }
}


struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var vm = ForgotPasswordViewModel()
    @EnvironmentObject var eh: ErrorHandling

    var body: some View {
        GroupBox {
            switch vm.state {
            case .idle:
                TextField("Email", text: $vm.username, prompt: Text("Email"))
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .textContentType(.emailAddress)
                    .disableAutocorrection(true)
                    .padding()
                    .accessibilityLabel("Email for password reset")
                
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
                        .frame(maxWidth: .infinity)
                        .padding()
                        .contentShape(Capsule())
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .padding(.vertical)
                .disabled(vm.username.isEmpty)
                .accessibilityLabel("Send password reset email")
                .accessibilityHint(vm.username.isEmpty ? "Enter your email to enable" : "Sends a reset link to your email")
                
            case .verify:
                Text("A password reset has been sent to \(vm.username)")
                    .accessibilityLabel("A password reset has been sent to \(vm.username)")
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Text("Close")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .contentShape(Capsule())
                }
                .disabled(!vm.isValid)
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .padding(.vertical)
                .accessibilityLabel("Close password reset")

            case .error(let error):
                Text("Error")
                    .overlay(Text("\(error.localizedDescription)"))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Error, \(error.localizedDescription)")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .ignoresSafeArea()
    }
}

struct ForgotPassword_Preview: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}
