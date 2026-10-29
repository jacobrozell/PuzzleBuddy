#!/usr/bin/env swift
// Press Device Hub pose / rotate buttons via Accessibility.
// Usage: devicehub-pose.swift closed|book|open|rotate

import AppKit
import ApplicationServices
import Foundation

let want = CommandLine.arguments.dropFirst().first?.lowercased() ?? ""
let labels: [String: String] = [
    "closed": "Closed",
    "book": "Book",
    "open": "Open",
    "rotate": "Rotate Right",
]
guard let target = labels[want] else {
    fputs("Usage: devicehub-pose.swift closed|book|open|rotate\n", stderr)
    exit(2)
}

func attr(_ el: AXUIElement, _ name: String) -> AnyObject? {
    var value: AnyObject?
    AXUIElementCopyAttributeValue(el, name as CFString, &value)
    return value
}

func findButton(in el: AXUIElement, description: String) -> AXUIElement? {
    let role = attr(el, kAXRoleAttribute) as? String ?? ""
    let desc = attr(el, kAXDescriptionAttribute) as? String ?? ""
    if role == "AXButton", desc == description {
        return el
    }
    guard let kids = attr(el, kAXChildrenAttribute) as? [AXUIElement] else { return nil }
    for kid in kids {
        if let hit = findButton(in: kid, description: description) {
            return hit
        }
    }
    return nil
}

func deviceHubPID() -> pid_t? {
    let running = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dt.Devices")
    if let app = running.first, app.processIdentifier > 0 {
        return app.processIdentifier
    }
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
    task.arguments = ["-f", "DeviceHub.app/Contents/MacOS/DeviceHub"]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = FileHandle.nullDevice
    try? task.run()
    task.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    guard let text = String(data: data, encoding: .utf8) else { return nil }
    for line in text.split(separator: "\n") {
        if let pid = pid_t(line.trimmingCharacters(in: .whitespaces)) {
            return pid
        }
    }
    return nil
}

NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/Xcode.app/Contents/Applications/DeviceHub.app"))
Thread.sleep(forTimeInterval: 0.8)

guard let pid = deviceHubPID() else {
    fputs("Device Hub is not running.\n", stderr)
    exit(1)
}

if let app = NSRunningApplication(processIdentifier: pid) {
    app.activate(options: [.activateIgnoringOtherApps])
    Thread.sleep(forTimeInterval: 0.4)
}

let axApp = AXUIElementCreateApplication(pid)
guard let windows = attr(axApp, kAXWindowsAttribute) as? [AXUIElement] else {
    fputs("No Device Hub windows.\n", stderr)
    exit(1)
}

for window in windows {
    if let button = findButton(in: window, description: target) {
        let err = AXUIElementPerformAction(button, kAXPressAction as CFString)
        if err != .success {
            fputs("Could not press \(target) (AX error \(err.rawValue)).\n", stderr)
            exit(1)
        }
        print("Pressed \(target)")
        exit(0)
    }
}

fputs("No \(target) button in Device Hub.\n", stderr)
exit(1)
