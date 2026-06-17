//
//  SettingsView.swift
//  Puzzle Buddy
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var ps: PuzzleStore
    @EnvironmentObject var auth: FirebaseAuthProvider
    @EnvironmentObject var eh: ErrorHandling

    @AppStorage(UserPreferences.appearanceStorageKey) private var appearanceRaw = AppearancePreference.system.rawValue
    @AppStorage(UserPreferences.barcodeLookupStorageKey) private var barcodeLookupEnabled = false
    @State private var showClearCollectionAlert = false
    @State private var showLoadDemoAlert = false
    @State private var showRemoveDemoAlert = false
    @State private var showIPDbImporter = false
    @State private var isImporting = false
    @State private var importSummary: PuzzleImportSummary?
    @State private var exportShareURL: URL?
    @State private var isExporting = false

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
            collectionSection
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
        .fileImporter(
            isPresented: $showIPDbImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText, .utf8PlainText, .data],
            allowsMultipleSelection: false
        ) { result in
            importIPDbCSV(result)
        }
        .sheet(item: $importSummary) { summary in
            IPDbImportSummarySheet(summary: summary)
        }
        .sheet(isPresented: Binding(
            get: { exportShareURL != nil },
            set: { if !$0 { exportShareURL = nil } }
        )) {
            if let exportShareURL {
                FileShareSheet(url: exportShareURL)
            }
        }
        .overlay {
            if isImporting || isExporting {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView(isImporting ? "Importing puzzles…" : "Preparing export…")
                        .padding()
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
                }
                .accessibilityLabel(isImporting ? "Importing puzzles from CSV file" : "Preparing collection export")
            }
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
        } header: {
            Text("Display")
        }
    }

    private var collectionSection: some View {
        Section {
            Toggle("Look up product from barcode", isOn: $barcodeLookupEnabled)
                .accessibilityHint("When on, tries online product lookup after checking puzzles you have already saved on this device.")

            Label {
                Text("Duplicate checks always work offline.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
            } icon: {
                Image(systemName: "wifi.slash")
                    .foregroundStyle(Brand.accent)
            }
        } header: {
            Text("Barcode & cataloging")
        } footer: {
            Text("Shopping duplicate check never needs the internet. When lookup is on, barcode digits are sent to a third-party product database (UPCitemdb) after checking puzzles saved on this device. See Privacy Policy.")
        }
    }

    private var dataSection: some View {
        Section {
            Button {
                showIPDbImporter = true
            } label: {
                Label("Import from IPDb CSV", systemImage: "square.and.arrow.down")
            }
            .disabled(isImporting || isExporting)
            .optionalAccessibilityIdentifier(A11yID.settingsImportIPDbButton)
            .accessibilityHint("Opens the Files app to choose an IPDb CSV export")

            Menu {
                Button {
                    exportCollection(format: .json)
                } label: {
                    Label("Export as JSON", systemImage: "doc.text")
                }
                Button {
                    exportCollection(format: .csv)
                } label: {
                    Label("Export as IPDb CSV", systemImage: "tablecells")
                }
            } label: {
                Label("Export collection", systemImage: "square.and.arrow.up")
            }
            .disabled(ps.puzzles.isEmpty || isImporting || isExporting)
            .optionalAccessibilityIdentifier(A11yID.settingsExportCollectionButton)
            .accessibilityHint("Creates a backup file you can save or share")

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
            VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                Text("Import: export a CSV from IPDb (Listview toolbar → Export → CSV). Export: back up as JSON or IPDb-compatible CSV for re-import here or in IPDb. Images are not included in CSV files.")
                LegalDisclaimerFooter(
                    text: LegalCopy.ipdbImportDisclaimer,
                    style: .form
                )
            }
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
        } footer: {
            LegalDisclaimerFooter(
                text: LegalCopy.brandTrademarkDisclaimer,
                accessibilityIdentifier: A11yID.settingsBrandDisclaimerFooter
            )
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

    private func exportCollection(format: PuzzleCollectionExportFormat) {
        guard !ps.puzzles.isEmpty else {
            eh.handle(title: "Nothing to export", message: PuzzleCollectionExportError.emptyCollection.localizedDescription)
            return
        }

        isExporting = true
        Task {
            defer { Task { @MainActor in isExporting = false } }
            do {
                let url = try PuzzleCollectionExporter.writeTemporaryFile(from: ps.puzzles, format: format)
                await MainActor.run {
                    exportShareURL = url
                }
                AppLog.shared.info(
                    .ui,
                    eventName: "settings_collection_exported",
                    message: "User exported collection.",
                    metadata: ["format": format.rawValue, "puzzle_count": "\(ps.puzzles.count)"]
                )
            } catch {
                await MainActor.run {
                    eh.handle(title: "Export failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func importIPDbCSV(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            eh.handle(title: "Could not open file", message: error.localizedDescription)
        case .success(let urls):
            guard let url = urls.first else { return }
            isImporting = true
            Task {
                defer { Task { @MainActor in isImporting = false } }
                do {
                    let summary = try await importIPDbCSV(at: url)
                    await MainActor.run {
                        importSummary = summary
                    }
                } catch {
                    await MainActor.run {
                        eh.handle(title: "Import failed", message: error.localizedDescription)
                    }
                }
            }
        }
    }

    private func importIPDbCSV(at url: URL) async throws -> PuzzleImportSummary {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        let puzzles = try IPDbCSVImporter.puzzles(from: data)
        return try await MainActor.run {
            try ps.importPuzzles(puzzles)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(ps: PreviewSupport.puzzleStore)
    }
}
