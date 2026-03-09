#!/usr/bin/env swift
// ghostty-navigator: Intercepts Ctrl+hjkl when Ghostty is focused.
// If nvim is active (flag file with live PID exists), passes the key through.
// If not, suppresses the key and navigates Ghostty splits via AppleScript.
//
// Requires: Accessibility permissions (System Settings > Privacy > Accessibility)

import Cocoa

let ghosttyBundleId = "com.mitchellh.ghostty"
let flagFile = "/tmp/ghostty-nvim-active"

// macOS virtual key codes: H=0x04, J=0x26, K=0x28, L=0x25
let keyDirections: [Int64: String] = [
  0x04: "left",
  0x26: "bottom",
  0x28: "top",
  0x25: "right",
]

func isGhosttyFocused() -> Bool {
  NSWorkspace.shared.frontmostApplication?.bundleIdentifier == ghosttyBundleId
}

func isNvimActive() -> Bool {
  guard let data = FileManager.default.contents(atPath: flagFile),
    let pidStr = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
    let pid = pid_t(pidStr)
  else { return false }
  return kill(pid, 0) == 0
}

func gotoSplit(_ direction: String) {
  let script = NSAppleScript(source: """
    tell application "Ghostty"
      set t to focused terminal of selected tab of front window
      perform action "goto_split:\(direction)" on t
    end tell
  """)
  var error: NSDictionary?
  script?.executeAndReturnError(&error)
}

let eventCallback: CGEventTapCallBack = { _, type, event, _ in
  guard type == .keyDown else { return Unmanaged.passRetained(event) }

  let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
  let flags = event.flags

  guard flags.contains(.maskControl),
    !flags.contains(.maskCommand),
    !flags.contains(.maskAlternate),
    !flags.contains(.maskShift),
    let direction = keyDirections[keyCode]
  else {
    return Unmanaged.passRetained(event)
  }

  guard isGhosttyFocused() else {
    return Unmanaged.passRetained(event)
  }

  if isNvimActive() {
    return Unmanaged.passRetained(event)
  } else {
    gotoSplit(direction)
    return nil
  }
}

guard
  let tap = CGEvent.tapCreate(
    tap: .cghidEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
    callback: eventCallback,
    userInfo: nil
  )
else {
  fputs("ghostty-navigator: failed to create event tap — grant Accessibility permissions\n", stderr)
  exit(1)
}

let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
CGEvent.tapEnable(tap: tap, enable: true)

fputs("ghostty-navigator: running\n", stderr)
NSApplication.shared.run()
