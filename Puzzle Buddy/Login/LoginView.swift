//
//  LoginView.swift
//  IAFC
//
//  Created by Justin Sprouse on 4/28/22.
//

import FirebaseAuth
import AuthenticationServices
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
    @State private var loginStatePicker: Int = 0
    @EnvironmentObject var auth: FirebaseAuthProvider

    var body: some View {
        VStack {
            Picker("Login/CreateAccount", selection: $loginStatePicker) {
                Text("Login")
                    .tag(0)

                Text("Create Account")
                    .tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            Image(systemName: "puzzlepiece.fill")
                .resizable()
                .aspectRatio(2/1, contentMode: .fit)
                .padding()
                .foregroundColor(.blue)

            Spacer()

            switch loginStatePicker {
            case 0:
                LoginStack()
            case 1:
                CreateAccount(isActive: .constant(true))

            default:
                Text("Loops lmfaoflmfaofofmsdnw :(((")
            }
        }
        .animation(.default, value: loginStatePicker)
        .padding()
        .ignoresSafeArea(.all, edges: .horizontal)
        .navigationBarTitleDisplayMode(.automatic)
        .navigationBarTitle(loginStatePicker == 0 ? "Login" : "Create Account")
        .padding(.vertical)
    }
}

// MARK: - LoginStack
private struct LoginStack: View {
    @Environment(\.colorScheme) var colorScheme

    @EnvironmentObject var errorHandling: ErrorHandling
    @EnvironmentObject var auth: FirebaseAuthProvider

    @State private var isActive = false
    @State private var isActiveForgotPassword = false

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
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

                    Spacer()

                    // Forgot Password Button
                    VStack {
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
                    }
                    .padding(.vertical)

                    SignInWithAppleButton { request in
                        auth.startSignInWithAppleFlow(request: request)
                        
                    } onCompletion: { result in
                        auth.signInWithAppleCompletion(result: result)
                    }
                    .padding()
                    .frame(minHeight: 60, maxHeight: 80)
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .whiteOutline : .black)
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
