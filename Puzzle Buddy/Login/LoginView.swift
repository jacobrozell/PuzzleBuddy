//
//  LoginView.swift
//  IAFC
//
//  Created by Justin Sprouse on 4/28/22.
//

import FirebaseAuth
import SwiftUI

// MARK: - LoginView
struct LoginView: View {
    @EnvironmentObject var auth: FirebaseAuthProvider
    
    var body: some View {
        NavigationView {
            if let user = auth.user {
                PuzzleView(user: user)
            } else {
                VStack {
                    Image(systemName: "puzzlepiece.fill")
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .padding(.vertical)

                    Text("Login")
                        .italic()
                        .font(.title)
                        .foregroundColor(.primary)
                        .frame(alignment: .bottom)

                    Spacer()

                    LoginStack()
                }
                .padding()
                .ignoresSafeArea(.all, edges: .horizontal)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarTitle("Login")
                .padding(.vertical)
            }
        }
    }
}

// MARK: - LoginStack
private struct LoginStack: View {
    @EnvironmentObject var errorHandling: ErrorHandling
    @EnvironmentObject var auth: FirebaseAuthProvider

    @State private var isActive = false
    @State private var isActiveForgotPassword = false

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            TextField("Email / Login ID", text: $auth.login)
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 16)

            SecureInputView("Password", text: $auth.password)
                .padding(.horizontal, 16)
                .textFieldStyle(.roundedBorder)

//            Toggle("Remember me:", isOn: $rememberMe)
//                .padding(.horizontal, 16)
//                .frame(alignment: .leading)

            VStack {
                Button {
                    Task {
                        do {
                            try await auth.login()
                        } catch {
                            errorHandling.handle(title: "Login Failed", message: "\(error.localizedDescription)")
                        }
                    }
                } label: {
                    Text("Log in")
                }

                Spacer()

                VStack {
                    // Forgot Password Button
                    Button {
                        isActiveForgotPassword = true
                    } label: {
                        Text("Forgot Password")
                            .italic()
                            .underline()
                            .foregroundColor(.primary)
                            .contentShape(Rectangle())
                            .padding(2)
                    }

                    // Create Account
                    NavigationLink(isActive: $isActive) {
//                        CreateAccountView(isActive: $isActive)
                        Text("Create Account View")
                    } label: {
                        Text("Create Account")
                            .italic()
                            .underline()
                            .foregroundColor(.primary)
                            .contentShape(Rectangle())
                            .padding(2)
                    }
                }
                .padding(.vertical)
            }
        }
        .sheet(isPresented: $isActiveForgotPassword) {
            ForgotPasswordView()
        }
        .padding(16)
    }
}

// MARK: - Previews
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
