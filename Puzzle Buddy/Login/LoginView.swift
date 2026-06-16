//
//  LoginView.swift
//  IAFC
//
//  Created by Justin Sprouse on 4/28/22.
//

import AuthenticationServices
import FirebaseAuth
import SwiftData
import SwiftUI

// MARK: - LoginView
struct LoginView: View {
    @EnvironmentObject var auth: FirebaseAuthProvider
    let modelContext: ModelContext

    var body: some View {
        if auth.shouldBypassAccount || UITestSupport.isBypassAuthEnabled {
            PuzzleView(modelContext: modelContext)
        } else if let user = auth.user {
            PuzzleView(modelContext: modelContext, user: user)
        } else {
            NavigationStack {
                LoginWrapper()
            }
        }
    }
}

// MARK: - LoginWrapper
private struct LoginWrapper: View {
    @State private var loginStatePicker: Int = 0
    @EnvironmentObject var auth: FirebaseAuthProvider
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        Group {
            if AdaptiveLayout.usesWideAuthLayout(
                horizontalSizeClass: horizontalSizeClass,
                verticalSizeClass: verticalSizeClass
            ) {
                HStack(alignment: .center, spacing: DS.Spacing.s6) {
                    loginHero
                        .frame(maxWidth: 280)
                    loginContent
                }
                .readableContentWidth()
            } else {
                VStack {
                    loginHero
                    loginContent
                }
            }
        }
        .padding()
        .adaptiveScrollChrome()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarTitle(loginStatePicker == 0 ? "Login" : "Create Account")
        .padding(.vertical, DS.Spacing.s3)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .brandBackground()
    }

    private var loginHero: some View {
        HStack {
            PuzzleHeroView(size: 88)
                .frame(maxWidth: 100, maxHeight: 100, alignment: .center)
        }
        .frame(maxWidth: .infinity)
    }

    private var loginContent: some View {
        VStack {
            Picker("Login or create account", selection: $loginStatePicker) {
                Text("Login").tag(0)
                Text("Create Account").tag(1)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Account mode")
            .accessibilityValue(loginStatePicker == 0 ? "Log in" : "Create account")
            .padding(.bottom, DS.Spacing.s3)

            switch loginStatePicker {
            case 0:
                LoginStack()
            case 1:
                CreateAccount(isActive: .constant(true))
            default:
                LoginStack()
            }
        }
        .animation(.default, value: loginStatePicker)
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
                    .optionalAccessibilityIdentifier(A11yID.loginEmailField)
                    .accessibilityLabel("Email")

                SecureInputView("Password", text: $auth.password, accessibilityIdentifier: A11yID.loginPasswordField)
                    .padding(.horizontal, 16)
                    .textFieldStyle(.roundedBorder)

                VStack(spacing: DS.Spacing.s3) {
                    Button {
                        isActiveForgotPassword = true
                    } label: {
                        Text("Forgot Password")
                            .italic()
                            .underline()
                            .foregroundColor(.primary)
                            .contentShape(Rectangle())
                    }
                    .optionalAccessibilityIdentifier(A11yID.forgotPasswordButton)
                    .accessibilityLabel("Forgot password")
                    .padding(.top, DS.Spacing.s2)

                    SignInWithAppleButton { request in
                        auth.startSignInWithAppleFlow(request: request)

                    } onCompletion: { result in
                        auth.signInWithAppleCompletion(result: result)
                    }
                    .padding(.top, DS.Spacing.s3)
                    .frame(maxHeight: 50)
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .whiteOutline : .black)
                    .clipShape(Capsule())
                    .accessibilityLabel("Sign in with Apple")

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
                    .buttonStyle(BrandPrimaryButtonStyle())
                    .optionalAccessibilityIdentifier(A11yID.loginSubmitButton)
                    .accessibilityLabel("Log in")
                    .accessibilityHint(auth.login.isEmpty || auth.password.isEmpty ? "Enter email and password to enable" : "Signs in to your account")
                    .disabled(auth.login.isEmpty || auth.password.isEmpty)
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
        LoginView(modelContext: PreviewSupport.modelContext)
    }
}
