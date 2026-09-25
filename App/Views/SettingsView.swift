//
//  SettingsView.swift
//  Puzzle Buddy
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var ps: PuzzleStore
    @EnvironmentObject var eh: ErrorHandling
    @Environment(\.openURL) private var openURL

    @AppStorage(UserPreferences.appearanceStorageKey) private var appearanceRaw = AppearancePreference.system.rawValue
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
            Text("Adds \(DemoDataCatalog.puzzleCount) sample puzzles so you can explore the app. Your existing puzzles stay in the collection.")
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
                PuzzleHeroView(size: 100)
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

    private var appearanceSection: some View {
        Section {
            Picker("Appearance", selection: appearance) {
                ForEach(AppearancePreference.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            .accessibilityHint("Choose light, dark, or match your device setting")
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
            .accessibilityIdentifier(A11yID.settingsLoadDemoButton)
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
            Text("Your collection stays on this device. Demo data is optional sample puzzles for exploring the app.")
        }
    }

    private var supportSection: some View {
        Section {
            Button {
                StoreReviewPrompt.recordSettingsLinkOpened()
                openURL(AppLinks.appStoreWriteReview)
            } label: {
                Text("Write a Review")
            }
            .optionalAccessibilityIdentifier(A11yID.settingsWriteReviewButton)
            .accessibilityHint("Opens the App Store so you can rate Puzzle Buddy")

            Link("Privacy Policy", destination: AppLinks.privacyPolicy)
            Link("Support", destination: AppLinks.support)
            Link("Accessibility", destination: AppLinks.accessibility)
        } header: {
            Text("Help & Legal")
        } footer: {
            VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                Text("Barcodes work offline. The barcode icon on your puzzle list checks for duplicates while shopping. Scanning to add can suggest details from puzzles you already saved — always review before saving.")
                    .font(.footnote)
                    .foregroundStyle(Brand.textSecondary)
                LegalDisclaimerFooter(
                    text: LegalCopy.brandTrademarkDisclaimer,
                    accessibilityIdentifier: A11yID.settingsBrandDisclaimerFooter
                )
            }
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: PuzzleBuddyApp.version)
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
