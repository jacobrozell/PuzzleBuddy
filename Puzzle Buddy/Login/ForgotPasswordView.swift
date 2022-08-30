//
//  ForgotPasswordView.swift
//  IAFC
//
//  Created by Jacob Rozell on 8/2/22.
//

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
    }

    public func resendCode(for username: String) async {}

    func confirmsResetPassword(completion: @escaping (Bool) -> Void) async throws {}
}


struct ForgotPasswordView: View {
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
            Text("Verification code sent to \(vm.username)")

            TextField("Verification Code", text: $vm.verificationCode, prompt: Text("Verification Code"))
                .textFieldStyle(.roundedBorder)
                .padding()

            Section {
                SecureInputView("Password", text: $vm.password)
                    .textContentType(.newPassword)
                VStack {
                    SecureInputView("Re-Enter Password", text: $vm.passwordConfirm)
                        .textContentType(.newPassword)

                    if !vm.password.isEmpty && vm.password != vm.passwordConfirm {
                        Text("Passwords must match")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            } header: {
                Text("Account Info")
            } footer: {
                Text("Password must have at least eight characters and must contain a lower-case letter, upper-case letter, a number, and a symbol. Make your password strong and secure.")
            }

            Spacer()

            Button {
                Task {
                    do {
                        try await vm.confirmsResetPassword { success in
                            if success {
                                print("VERIFCATIONCODE: SUCCESS")
                            } else {
                                eh.handle(title: "Invalid Verification Code", message: "Please resend and try again.")
                            }
                        }
                    } catch {
                        eh.handle(title: "Invalid Verification Code", message: "Please resend and try again.")
                    }
                }
            } label: {
                Text("Submit")
            }
            .disabled(!vm.isValid)
            .padding(.vertical)


//            IAFCStandardButton(labelText: "Resend Verification Code") {
//                Task {
//                    await vm.resendCode(for: vm.username)
//                }
//            }
//            .padding(.vertical)
        }
    }
}

struct ForgotPassword_Preview: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}
