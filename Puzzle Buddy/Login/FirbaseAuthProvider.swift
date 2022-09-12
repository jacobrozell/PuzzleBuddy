import FirebaseAuth
import FirebaseFirestore

@MainActor
public class FirebaseAuthProvider: ObservableObject {
    enum FirebaseAuthError: LocalizedError {
        case invalid(String)
        case failure(String)
    }

    @Published var login = ""
    @Published var password = ""
    @Published var user: FirebaseAuth.User?
    @Published var shouldBypassAccount = false
    @Published var displayName: String = ""

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

    public func createAccount(with name: String, email: String, password: String) async throws {
        try await Auth.auth().createUser(withEmail: email, password: password)
        try await Firestore.firestore().collection("users").document("\(email)").setData(["username": name, "currentVersion": Puzzle_BuddyApp.version])
        self.user = Auth.auth().currentUser
    }

    public func updateUser() async throws {
        guard let email = user?.email, !email.isEmpty else {
            return
        }

        try await Firestore.firestore().collection("users").document(email).updateData(["currentVersion": Puzzle_BuddyApp.version, "lastLoggedIn": Date()])
    }

    public func logout() throws {
        try Auth.auth().signOut()
        self.user = nil
    }
}
