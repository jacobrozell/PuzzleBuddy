//
//  CSVTable.swift
//  Puzzle Buddy
//

import Foundation

enum CSVTable {
    static func parse(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var index = text.startIndex
        var inQuotes = false

        while index < text.endIndex {
            let character = text[index]

            if inQuotes {
                if character == "\"" {
                    let next = text.index(after: index)
                    if next < text.endIndex, text[next] == "\"" {
                        field.append("\"")
                        index = text.index(after: next)
                        continue
                    }
                    inQuotes = false
                } else {
                    field.append(character)
                }
            } else if character == "\"" {
                inQuotes = true
            } else if character == "," || character == ";" {
                row.append(field)
                field = ""
            } else if character == "\n" || character == "\r" {
                if character == "\r", text.index(after: index) < text.endIndex, text[text.index(after: index)] == "\n" {
                    index = text.index(after: index)
                }
                row.append(field)
                field = ""
                if !row.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                    rows.append(row)
                }
                row = []
            } else {
                field.append(character)
            }

            index = text.index(after: index)
        }

        row.append(field)
        if !row.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            rows.append(row)
        }

        return rows
    }

    static func delimiter(for rows: [[String]]) -> Character {
        guard let header = rows.first, header.count == 1, let line = header.first else {
            return ","
        }
        return line.contains(";") && !line.contains(",") ? ";" : ","
    }

    static func parseDelimitedRows(_ text: String) -> (headers: [String], records: [[String: String]]) {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\u{FEFF}", with: "")

        var rows = parse(normalized)
        if let header = rows.first, header.count == 1, header[0].contains(";") {
            rows = normalized
                .split(whereSeparator: \.isNewline)
                .map { line in
                    String(line).split(separator: ";", omittingEmptySubsequences: false).map(String.init)
                }
        }

        guard let headerRow = rows.first else {
            return ([], [])
        }

        let headers = headerRow.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let records: [[String: String]] = rows.dropFirst().map { values in
            var record: [String: String] = [:]
            for (offset, header) in headers.enumerated() where !header.isEmpty {
                let value = offset < values.count ? values[offset] : ""
                record[header] = value.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return record
        }

        return (headers, records)
    }
}
