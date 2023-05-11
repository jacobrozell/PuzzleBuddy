import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseAnalytics

@MainActor
public class FirebaseAuthProvider: ObservableObject {
    enum FirebaseAuthError: LocalizedError {
        case invalid(String)
        case failure(String)
    }

    @Published var login = ""
    @Published var password = ""
    @Published var user: PuzzleUser?
    @Published var shouldBypassAccount = false
    @Published var shouldReauth = false
    @Published var displayName: String = ""

    var currentNonce: String?

    public init() {}

    public func login() async throws {
        guard
            !login.isEmpty,
            !password.isEmpty
        else {
            throw FirebaseAuthError.invalid("Invalid or blank credentials")
        }

        // Attempt to sign user in
        let result = try await Auth.auth().signIn(withEmail: login, password: password)
        self.user = result.user
        try await updateUser()

        Analytics.logEvent("User logged in", parameters: ["email": login, "uid": result.user.uid])
    }

    public func createAccount(with name: String, email: String, password: String) async throws {
        try await Auth.auth().createUser(withEmail: email, password: password)
        try await createUserDetailsDoc(with: name, email: email)
        self.user = Auth.auth().currentUser

        Analytics.logEvent("User created account", parameters: ["email": email, "uid": Auth.auth().currentUser?.uid ?? ""])
    }

    private func createUserDetailsDoc(with name: String, email: String) async throws {
        try await Firestore.firestore().collection("users").document("\(email)").setData(["username": name, "currentVersion": Puzzle_BuddyApp.version])
    }

    public func updateUser() async throws {
        guard let email = user?.email, !email.isEmpty else {
            return
        }

        do {
            try await Firestore.firestore().collection("users").document(email).updateData(["currentVersion": Puzzle_BuddyApp.version, "lastLoggedIn": Date()])
        } catch {
            // Try to create document
            try await createUserDetailsDoc(with: self.login, email: email)
        }

        Analytics.logEvent("User Updated", parameters: ["email": email, "uid": Auth.auth().currentUser?.uid ?? ""])
    }

    public func logout() async throws {
        Analytics.logEvent("User logout", parameters: ["email": user?.email ?? ""])
        try await updateUser()
        self.user = nil
        try Auth.auth().signOut()
    }

    public func deleteAccount(){
        Auth.auth().currentUser?.delete { error in
            if let error = error {
                // An error happened.
                print(error.localizedDescription)
                self.shouldReauth = true

            } else {
                // Account deleted.
                self.user = nil
            }
        }
    }

    public func reauthUser() {
        let user = Auth.auth().currentUser
        let credential = EmailAuthProvider.credential(withEmail: login, password: password)

        user?.reauthenticate(with: credential) { arg, error in
          if let error = error {
            // An error happened.
              print(error.localizedDescription)
          } else {
            // User re-authenticated.
              print("Success.")
          }
        }
    }
}

// MARK: - Sign in with Apple extension
extension FirebaseAuthProvider {
    // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError(
                        "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                    )
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }

    func startSignInWithAppleFlow(request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce

        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    func signInWithAppleCompletion(result: Result<ASAuthorization, Error>) throws {
        switch result {
        case .success(let authResults):
            switch authResults.credential {
            case let appleIDCredential as ASAuthorizationAppleIDCredential:

                guard let nonce = currentNonce else {
                    fatalError("Invalid state: A login callback was received, but no login request was sent.")
                }
                guard let appleIDToken = appleIDCredential.identityToken else {
                    fatalError("Invalid state: A login callback was received, but no login request was sent.")
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                    return
                }

                let credential = OAuthProvider.credential(
                    withProviderID: "apple.com",
                    idToken: idTokenString,
                    rawNonce: nonce
                )

                Auth.auth().signIn(with: credential) { (authResult, error) in
                    guard let authResult = authResult else {
                        return
                    }

                    self.user = authResult.user
                }
            default:
                break
            }
        case .failure(let error):
            print(error.localizedDescription)
            throw error
        }
    }
}
