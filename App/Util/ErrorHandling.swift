//
//  ErrorHandling.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 11/3/21.
//

import SwiftUI

struct ErrorAlert: Identifiable {
    var id = UUID()
    var title: String
    var message: String
    var dismissAction: (() -> Void)?
}

@MainActor
class ErrorHandling: ObservableObject {
    @Published var currentAlert: ErrorAlert?

    func handle(error: Error, title: String) {
        self.printError(title: title, message: error.localizedDescription, error: error)
        self.currentAlert = ErrorAlert(title: title, message: error.localizedDescription)
    }

    func handle(title: String, message: String, dismissAction: (() -> Void)?={}) {
        self.currentAlert = ErrorAlert(title: title, message: message, dismissAction: dismissAction)
    }

    private func printError(title: String, message: String, error: Error) {
        #if DEBUG
        print("""
              AppError:
                title: \(title)
                message: \(message)
                🥊 DEVELOPER INFO: \(error)
              """)
        #endif
    }
}

struct HandleErrorsByShowingAlertViewModifier: ViewModifier {
    @StateObject var errorHandling = ErrorHandling()

    func body(content: Content) -> some View {
        content
            .environmentObject(errorHandling)
        // Applying the alert for error handling using a background element
        // is a workaround, if the alert would be applied directly,
        // other .alert modifiers inside of content would not work anymore
            .background(
                EmptyView()
                    .alert(item: $errorHandling.currentAlert) { currentAlert in
                        Alert(
                            title: Text(currentAlert.title),
                            message: Text(currentAlert.message),
                            dismissButton: .default(Text("Ok")) {
                                currentAlert.dismissAction?()
                            }
                        )
                    }
            )
    }
}

extension View {
    func withErrorHandling() -> some View {
        modifier(HandleErrorsByShowingAlertViewModifier())
    }
}
