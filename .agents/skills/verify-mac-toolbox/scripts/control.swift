#!/usr/bin/env swift
import AppKit
import ApplicationServices
import Foundation

// Only menu visibility is mutable here. There is deliberately no command for
// toggling display settings, login registration, or Music blocking.
func fail(_ message: String, code: Int32 = 1) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(code)
}
func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else {
        return nil
    }
    return value
}
func children(_ element: AXUIElement) -> [AXUIElement] {
    attribute(element, kAXChildrenAttribute) as? [AXUIElement] ?? []
}
func emit(_ value: [String: Any]) {
    do {
        let data = try JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys])
        print(String(decoding: data, as: UTF8.self))
    } catch { fail("Cannot serialize evidence: \(error)") }
}
func sha256(_ url: URL) -> String? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/shasum")
    process.arguments = ["-a", "256", url.path]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice
    do {
        try process.run()
        let output = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        return String(decoding: output, as: UTF8.self).split(separator: " ").first.map(String.init)
    } catch { return nil }
}

let arguments = Array(CommandLine.arguments.dropFirst())
guard let command = arguments.first,
      ["doctor", "open-menu", "snapshot", "close-menu", "screenshot"].contains(command)
else { fail("Usage: control.swift doctor|open-menu|snapshot|close-menu|screenshot /absolute/path.png") }
let applications = NSRunningApplication.runningApplications(withBundleIdentifier: "local.hojin.MacToolbox")
guard applications.count == 1, let application = applications.first else {
    fail("Expected one running Mac Toolbox instance, found \(applications.count). Do not launch a second instance.")
}
let expectedApp = URL(fileURLWithPath: "/Applications/Mac Toolbox.app")
guard application.bundleURL?.standardizedFileURL == expectedApp.standardizedFileURL else {
    fail("Running app is not /Applications/Mac Toolbox.app; verify the intended bundle before driving it.")
}
let pid = application.processIdentifier
let app = AXUIElementCreateApplication(pid)
AXUIElementSetMessagingTimeout(app, 2)
func menuWindow() -> [String: Any]? {
    (CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []).first {
        ($0[kCGWindowOwnerPID as String] as? Int) == Int(pid) &&
        ($0[kCGWindowLayer as String] as? Int) == 101
    }
}
func statusItem() -> AXUIElement {
    guard AXIsProcessTrusted() else { fail("Accessibility access is absent; no permission request was made.", code: 3) }
    guard let value = attribute(app, kAXExtrasMenuBarAttribute) else {
        fail("Mac Toolbox has no accessible extras menu bar.")
    }
    let bar = unsafeBitCast(value, to: AXUIElement.self)
    guard let item = children(bar).first(where: {
        attribute($0, kAXTitleAttribute) as? String == "Mac Toolbox"
    }) else { fail("The Mac Toolbox status item was not found.") }
    return item
}
func waitForMenu(visible: Bool) -> Bool {
    for _ in 0..<15 {
        if (menuWindow() != nil) == visible { return true }
        Thread.sleep(forTimeInterval: 0.1)
    }
    return false
}

switch command {
case "doctor":
    let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()
    let packaged = root.appendingPathComponent("dist/Mac Toolbox.app/Contents/MacOS/MacToolbox")
    let installed = expectedApp.appendingPathComponent("Contents/MacOS/MacToolbox")
    let packagedHash = sha256(packaged)
    let installedHash = sha256(installed)
    let matches = packagedHash != nil && packagedHash == installedHash
    emit([
        "pid": Int(pid), "bundle": expectedApp.path,
        "packaged_sha256": packagedHash ?? "missing",
        "installed_sha256": installedHash ?? "missing",
        "matches_packaged_build": matches,
        "accessibility_trusted": AXIsProcessTrusted(),
        "screen_capture_allowed": CGPreflightScreenCaptureAccess(),
        "menu_visible": menuWindow() != nil,
        "ready_for_menu_drive": matches && AXIsProcessTrusted()
    ])
    if !matches || !AXIsProcessTrusted() { exit(1) }
case "open-menu", "close-menu":
    let visible = command == "open-menu"
    let wasVisible = menuWindow() != nil
    var actionResult: Int32 = 0
    if wasVisible != visible {
        let item = statusItem()
        if visible {
            actionResult = AXUIElementPerformAction(item, kAXPressAction as CFString).rawValue
        } else {
            guard let menu = children(item).first else { fail("The status item has no menu to close.") }
            actionResult = AXUIElementPerformAction(menu, kAXCancelAction as CFString).rawValue
        }
    }
    // AXPress may time out even though AppKit presents the menu. Verify the
    // observable window instead of treating the action return as proof.
    guard waitForMenu(visible: visible) else {
        fail("Menu did not reach requested visibility; AX action returned \(actionResult). Run doctor before retrying.")
    }
    emit(["command": command, "was_visible": wasVisible, "menu_visible": visible,
          "ax_action_result": actionResult, "pid": Int(pid)])
case "snapshot":
    guard menuWindow() != nil else { fail("Menu is closed; run open-menu before capturing evidence.") }
    guard let menu = children(statusItem()).first else { fail("The status item has no menu.") }
    let items = children(menu).map { item -> [String: Any] in
        let mark = attribute(item, kAXMenuItemMarkCharAttribute) as? String ?? ""
        return ["title": attribute(item, kAXTitleAttribute) as? String ?? "",
                "enabled": attribute(item, kAXEnabledAttribute) as? Bool ?? false,
                "mark": mark]
    }
    emit(["pid": Int(pid), "menu_visible": true, "items": items])
case "screenshot":
    guard arguments.count == 2, arguments[1].hasPrefix("/") else {
        fail("Supply an absolute PNG path for screenshot evidence.")
    }
    guard CGPreflightScreenCaptureAccess() else {
        fail("Screen Recording access is absent. Screenshot blocked; no permission request or settings change was made.", code: 3)
    }
    guard let window = menuWindow(), let number = window[kCGWindowNumber as String] as? Int else {
        fail("Menu is closed; run open-menu before screenshot.")
    }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
    process.arguments = ["-x", "-o", "-l", String(number), arguments[1]]
    do {
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0,
              FileManager.default.fileExists(atPath: arguments[1]) else { fail("Menu capture failed.") }
        emit(["screenshot": arguments[1], "window_id": number, "pid": Int(pid)])
    } catch { fail("Menu capture failed: \(error)") }
default:
    fail("Unsupported command")
}
