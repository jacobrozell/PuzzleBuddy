//
//  SettingsView.swift
//  Puzzle Buddy
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var ps: PuzzleStore
    @EnvironmentObject var auth: FirebaseAuthProvider
    @EnvironmentObject var eh: ErrorHandling

    @AppStorage(UserPreferences.appearanceStorageKey) private var appearanceRaw = AppearancePreference.system.rawValue
    @AppStorage(UserPreferences.barcodeLookupStorageKey) private var barcodeLookupEnabled = false
    @State private var showClearCollectionAlert = false
    @State private var showLoadDemoAlert = false
    @State private var showRemoveDemoAlert = false

    private var appearance: Binding<AppearancePreference> {
        Binding(
            get: { AppearancePreference(rawValue: appearanceRaw) ?? .system },
            set: { appearanceRaw = $0.rawValue }
        )
    }

    var body: some View {
        List {
            settingsHeader

            if ProductService.isLoginEnabled {
                accountSection
            }

            appearanceSection
            dataSection
            supportSection
            aboutSection
        }
        .readableBrandScreenChrome()
        .alert("Load demo puzzles?", isPresented: $showLoadDemoAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Load Demo Data") {
                loadDemoData()
            }
        } message: {
            Text("Adds four sample puzzles so you can explore the app. Your existing puzzles stay in the collection.")
        }
        .alert("Remove demo puzzles?", isPresented: $showRemoveDemoAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Remove Demo Data", role: .destructive) {
                removeDemoData()
            }
        } message: {
            Text("Removes \(ps.demoPuzzleCount) sample puzzles. Your own puzzles are not affected.")
        }
        .alert("Delete all puzzles?", isPresented: $showClearCollectionAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete All", role: .destructive) {
                clearCollection()
            }
        } message: {
            Text("This permanently removes every puzzle on this device. This cannot be undone.")
        }
    }

    private var settingsHeader: some View {
        Section {
            VStack(spacing: DS.Spacing.s3) {
                BrandMark(size: 72)
                Text(AppInfo.displayName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Brand.textPrimary)
                Text("Track your puzzle collection")
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private var accountSection: some View {
        Section {
            if auth.user != nil {
                Button {
                    do {
                        try auth.logout()
                    } catch {
                        eh.handle(title: "Logout failed", message: error.localizedDescription)
                    }
                } label: {
                    Text("Sign Out")
                        .foregroundStyle(Brand.accentWarm)
                }
                .optionalAccessibilityIdentifier(A11yID.settingsSignOutButton)
                .accessibilityLabel("Sign out")
                .accessibilityHint("Signs out of your Puzzle Buddy account")
            }
        } header: {
            Text("Account")
        }
    }

    private var appearanceSection: some View {
        Section {
            Picker("Appearance", selection: appearance) {
                ForEach(AppearancePreference.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            .accessibilityHint("Choose light, dark, or match your device setting")

            Toggle("Look up product from barcode", isOn: $barcodeLookupEnabled)
                .accessibilityHint("When on, scans try to fetch puzzle title and brand online. Off by default — uses your saved puzzles first, then optional UPC lookup.")
        } header: {
            Text("Display")
        }
    }

    private var dataSection: some View {
        Section {
            Button {
                showLoadDemoAlert = true
            } label: {
                Label("Load Demo Data", systemImage: "square.stack.3d.up")
            }
            .accessibilityHint("Adds sample puzzles for exploring the app")

            Button(role: .destructive) {
                showRemoveDemoAlert = true
            } label: {
                Label("Remove Demo Data", systemImage: "square.stack.3d.down")
            }
            .disabled(ps.demoPuzzleCount == 0)
            .optionalAccessibilityIdentifier(A11yID.settingsRemoveDemoButton)
            .accessibilityHint(
                ps.demoPuzzleCount == 0
                    ? "No demo puzzles to remove"
                    : "Removes \(ps.demoPuzzleCount) sample puzzles from your collection"
            )

            Button(role: .destructive) {
                showClearCollectionAlert = true
            } label: {
                Label("Delete All Puzzles", systemImage: "trash")
            }
            .disabled(ps.puzzles.isEmpty)
            .accessibilityHint(ps.puzzles.isEmpty ? "No puzzles to delete" : "Removes every puzzle from this device")
        } header: {
            Text("Collection")
        } footer: {
            Text("Demo data is useful for screenshots and trying features. Remove demo data only deletes sample puzzles. Delete all removes every puzzle on this device.")
        }
    }

    private var supportSection: some View {
        Section {
            Link(destination: AppLinks.tipJar) {
                Label("Buy Me a Coffee", systemImage: "cup.and.saucer.fill")
            }
            .accessibilityHint("Opens the tip jar in your browser")

            Link("Privacy Policy", destination: AppLinks.privacyPolicy)
            Link("Support", destination: AppLinks.support)
            Link("Accessibility", destination: AppLinks.accessibility)
        } header: {
            Text("Help & Legal")
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: Puzzle_BuddyApp.version)
            LabeledContent("Puzzles", value: "\(ps.puzzles.count)")
            if ps.demoPuzzleCount > 0 {
                LabeledContent("Demo puzzles", value: "\(ps.demoPuzzleCount)")
            }
        } header: {
            Text("About")
        }
    }

    private func loadDemoData() {
        do {
            try ps.loadDemoPuzzles()
        } catch {
            eh.handle(title: "Could not load demo data", message: error.localizedDescription)
        }
    }

    private func removeDemoData() {
        do {
            try ps.removeDemoPuzzles()
        } catch {
            eh.handle(title: "Could not remove demo data", message: error.localizedDescription)
        }
    }

    private func clearCollection() {
        do {
            try ps.clearAllPuzzles()
        } catch {
            eh.handle(title: "Could not delete puzzles", message: error.localizedDescription)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(ps: PreviewSupport.puzzleStore)
    }
}
