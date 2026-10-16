// Range entry point; shared typography, QR and footer rendering lives in render.swift.
import Foundation
let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
task.arguments = ["swift", "-module-cache-path", NSTemporaryDirectory()+"himalaya-swift-cache", root.deletingLastPathComponent().appendingPathComponent("render.swift").path, root.lastPathComponent]
try task.run()
task.waitUntilExit()
exit(task.terminationStatus)
