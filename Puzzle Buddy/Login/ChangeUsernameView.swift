import FirebaseAuth
import SwiftUI

@MainActor
class ChangeUsernameViewModel: ObservableObject {
    @Published var username: String = ""

    var isValid: Bool {
        !username.isEmpty
    }

    func changeUsername() async throws {
        guard !username.isEmpty else {
            print("Oops")
            return
        }

        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.displayName = username
        try await changeRequest?.commitChanges()
    }
}

struct ChangeUsernameView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var vm = ChangeUsernameViewModel()
    @EnvironmentObject var eh: ErrorHandling

    @State private var success = false

    var body: some View {
        GroupBox {
            TextField("Username", text: $vm.username, prompt: Text("Username"))
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
                        try await vm.changeUsername()
                        dismiss()
                    } catch {
                        eh.handle(title: "Change Username Failed", message: "Please try again.")
                    }
                }
            } label: {
                Text("Submit")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .contentShape(Capsule())
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .padding(.vertical)
            .disabled(vm.username.isEmpty)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .ignoresSafeArea()
    }
}
