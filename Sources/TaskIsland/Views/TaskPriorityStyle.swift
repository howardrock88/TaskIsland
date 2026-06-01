import AppKit
import SwiftUI
import TaskIslandCore

extension TaskPriority {
    var defaultColorHex: String {
        switch self {
        case .high:
            return "#FF404D"
        case .medium:
            return "#FFB82E"
        case .low:
            return "#3DC766"
        }
    }

    var tintColor: Color {
        defaultTintColor
    }

    var defaultTintColor: Color {
        Color(taskIslandHex: defaultColorHex) ?? Color.accentColor
    }

    @MainActor
    func tintColor(settings: AppSettings) -> Color {
        Color(taskIslandHex: settings.priorityColorHex(for: self)) ?? defaultTintColor
    }

    var symbolName: String {
        switch self {
        case .high:
            return "flame.fill"
        case .medium:
            return "circle.lefthalf.filled"
        case .low:
            return "leaf.fill"
        }
    }
}

extension Color {
    init?(taskIslandHex hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if sanitized.hasPrefix("#") {
            sanitized.removeFirst()
        }

        guard sanitized.count == 6,
              let value = Int(sanitized, radix: 16) else {
            return nil
        }

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }

    var taskIslandHexString: String? {
        guard let rgbColor = NSColor(self).usingColorSpace(.sRGB) else {
            return nil
        }

        let red = Int((rgbColor.redComponent * 255).rounded())
        let green = Int((rgbColor.greenComponent * 255).rounded())
        let blue = Int((rgbColor.blueComponent * 255).rounded())
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
