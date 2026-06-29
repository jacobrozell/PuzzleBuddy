//
//  SettingsView.swift
//  Puzzle Buddy
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var ps: PuzzleStore
    @EnvironmentObject var eh: ErrorHandling

    @AppStorage(UserPreferences.appearanceStorageKey) private var appearanceRaw = AppearancePreference.system.rawValue
    @State private var showClearCollectionAlert = false
    @State private var showLoadDemoAlert = false
    @State private var showRemoveDemoAlert = false
    @State private var showIPDbImporter = false
    @State private var showBackupImporter = false
    @State private var backupImportPolicy: PuzzleBackupImportPolicy = .mergeSkipExistingIDs
    @State private var showReplaceBackupConfirmation = false
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
        .fileImporter(
            isPresented: $showIPDbImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText, .utf8PlainText, .data],
            allowsMultipleSelection: false
        ) { result in
            importIPDbCSV(result)
        }
        .fileImporter(
            isPresented: $showBackupImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            importJSONBackup(result, policy: backupImportPolicy)
        }
        .alert("Replace entire collection?", isPresented: $showReplaceBackupConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Choose backup file", role: .destructive) {
                backupImportPolicy = .replaceAll
                showBackupImporter = true
            }
        } message: {
            Text("This permanently removes every puzzle on this device and restores from your JSON backup. This cannot be undone.")
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
            if ProductService.isCollectionImportExportEnabled {
                importExportButtons
            }

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
                if ProductService.isCollectionImportExportEnabled {
                    Text("Import: IPDb CSV for migration, or JSON backup to merge or fully restore your collection. Export: back up as JSON (full restore) or IPDb-compatible CSV. CSV files never include photos.")
                    LegalDisclaimerFooter(
                        text: LegalCopy.ipdbImportDisclaimer,
                        style: .form
                    )
                } else {
                    Text("Backup and IPDb import arrive in a future update. Your collection stays on this device.")
                }
            }
        }
    }

    @ViewBuilder
    private var importExportButtons: some View {
        Button {
            showIPDbImporter = true
        } label: {
            Label("Import from IPDb CSV", systemImage: "square.and.arrow.down")
        }
        .disabled(isImporting || isExporting)
        .optionalAccessibilityIdentifier(A11yID.settingsImportIPDbButton)
        .accessibilityHint("Opens the Files app to choose an IPDb CSV export")

        Button {
            backupImportPolicy = .mergeSkipExistingIDs
            showBackupImporter = true
        } label: {
            Label("Import backup (JSON)", systemImage: "arrow.trianglehead.2.counterclockwise")
        }
        .disabled(isImporting || isExporting)
        .optionalAccessibilityIdentifier(A11yID.settingsImportBackupButton)
        .accessibilityHint("Merges puzzles from a Puzzle Buddy JSON backup; skips puzzles already in your collection")

        Button(role: .destructive) {
            showReplaceBackupConfirmation = true
        } label: {
            Label("Restore from backup…", systemImage: "arrow.counterclockwise")
        }
        .disabled(isImporting || isExporting)
        .optionalAccessibilityIdentifier(A11yID.settingsRestoreBackupButton)
        .accessibilityHint("Replaces your entire collection with a JSON backup")

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
    }

    private var supportSection: some View {
        Section {
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

    private func importJSONBackup(_ result: Result<[URL], Error>, policy: PuzzleBackupImportPolicy) {
        switch result {
        case .failure(let error):
            eh.handle(title: "Could not open file", message: error.localizedDescription)
        case .success(let urls):
            guard let url = urls.first else { return }
            isImporting = true
            Task {
                defer { Task { @MainActor in isImporting = false } }
                do {
                    let summary = try await importJSONBackup(at: url, policy: policy)
                    await MainActor.run {
                        importSummary = summary
                    }
                } catch {
                    await MainActor.run {
                        eh.handle(title: "Restore failed", message: error.localizedDescription)
                    }
                }
            }
        }
    }

    private func importJSONBackup(at url: URL, policy: PuzzleBackupImportPolicy) async throws -> PuzzleImportSummary {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        let parseResult = try PuzzleCollectionJSONImporter.parse(from: data)
        return try await MainActor.run {
            try ps.importBackup(
                parseResult.puzzles,
                policy: policy,
                preSkippedInvalid: parseResult.skippedInvalid
            )
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(ps: PreviewSupport.puzzleStore)
    }
}
