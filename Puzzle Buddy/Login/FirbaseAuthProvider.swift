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
        let _ = try await Auth.auth().signIn(withEmail: login, password: password)
    }

    public func createAccount(with name: String, email: String, password: String) async throws {
        try await Auth.auth().createUser(withEmail: email, password: password)
        try await Firestore.firestore().collection("users").document("\(email)").setData(["username": name])
    }

    public func bypassAccount() {
        Auth.auth().signInAnonymously()
        shouldBypassAccount = true
    }

    public func logout() throws {
        try Auth.auth().signOut()
    }

    public func getUser() -> PuzzleUser? {
        return Auth.auth().currentUser
    }
}
