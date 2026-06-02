import AppKit
import Darwin

let application = NSApplication.shared

if CommandLine.arguments.contains("--render-marketing-assets") {
    application.setActivationPolicy(.accessory)
    Task { @MainActor in
        do {
            try MarketingAssetRenderer.renderAll()
            exit(EXIT_SUCCESS)
        } catch {
            fputs("Marketing asset rendering failed: \(error.localizedDescription)\n", stderr)
            exit(EXIT_FAILURE)
        }
    }
    RunLoop.main.run()
} else {
    let delegate = AppDelegate()
    application.delegate = delegate
    application.run()
}
