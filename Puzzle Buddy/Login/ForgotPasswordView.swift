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
    @Published var password: String = ""

    var isValid: Bool {
        !username.isEmpty
        && !password.isEmpty
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
                
            case .verify:
                Text("A password reset has been sent to \(vm.username)")
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Text("Close")
                }
                .disabled(!vm.isValid)
                .padding(.vertical)
                
            case .error(let error):
                Text("Error")
                    .overlay(Text("\(error.localizedDescription)"))
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct ForgotPassword_Preview: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}
