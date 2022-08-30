import FirebaseAuth

@MainActor
public class FirebaseAuthProvider: ObservableObject {
    enum FirebaseAuthError: LocalizedError {
        case invalid(String)
        case failure(String)
    }

    @Published var login = ""
    @Published var password = ""
    @Published var user: FirebaseAuth.User?

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
    }

    public func logout() throws {
        try Auth.auth().signOut()
        self.user = nil
    }
}
