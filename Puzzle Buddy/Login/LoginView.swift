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
        if let user = auth.user {
            PuzzleView(user: user)
        } else {
            LoginWrapper()
        }
    }
}

// MARK: - LoginWrapper
private struct LoginWrapper: View {
    @EnvironmentObject var auth: FirebaseAuthProvider

    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "puzzlepiece.fill")
                    .resizable()
                    .aspectRatio(2/1, contentMode: .fit)
                    .padding()
                    .foregroundColor(.blue)

                Spacer()

                LoginStack()
            }
            .padding()
            .ignoresSafeArea(.all, edges: .horizontal)
            .navigationBarTitleDisplayMode(.automatic)
            .navigationBarTitle("Sign-Up/Sign-In")
            .padding(.vertical)
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
            Section {
                TextField("Display Name", text: $auth.displayName)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .keyboardType(.namePhonePad)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 16)
            }

            Section {
                TextField("Email", text: $auth.login)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 16)

                SecureInputView("Password", text: $auth.password)
                    .padding(.horizontal, 16)
                    .textFieldStyle(.roundedBorder)

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
                            .frame(maxWidth: .infinity)
                            .padding()
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .disabled(auth.login.isEmpty || auth.password.isEmpty)

                    NavigationLink {
                        PuzzleView()
                            .task {
                                auth.bypassAccount()
                            }
                    } label: {
                        Text("Bypass Account")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .contentShape(Capsule())
                            .foregroundColor(.red)
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
                            CreateAccount(isActive: $isActive)
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
