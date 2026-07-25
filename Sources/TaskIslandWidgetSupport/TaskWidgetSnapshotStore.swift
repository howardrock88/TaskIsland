import Foundation

public enum TaskWidgetSnapshotStoreError: Error {
    case cannotCreateDirectory(URL)
}

public struct TaskWidgetSnapshotStore {
    public static let appGroupInfoKey = "TaskIslandAppGroupIdentifier"
    public static let widgetBundleIdentifierInfoKey = "TaskIslandWidgetBundleIdentifier"
    public static let snapshotFileName = "widget-snapshot.json"

    public let appGroupIdentifier: String?
    public let widgetBundleIdentifier: String?
    public let fileManager: FileManager

    public init(
        appGroupIdentifier: String? = Self.configuredAppGroupIdentifier(),
        widgetBundleIdentifier: String? = Self.configuredWidgetBundleIdentifier(),
        fileManager: FileManager = .default
    ) {
        self.appGroupIdentifier = appGroupIdentifier?.isEmpty == false ? appGroupIdentifier : nil
        self.widgetBundleIdentifier = widgetBundleIdentifier?.isEmpty == false ? widgetBundleIdentifier : nil
        self.fileManager = fileManager
    }

    public static func configuredAppGroupIdentifier(bundle: Bundle = .main) -> String? {
        if let value = bundle.object(forInfoDictionaryKey: appGroupInfoKey) as? String,
           !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return value
        }

        let environmentValue = ProcessInfo.processInfo.environment["TASKISLAND_APP_GROUP_ID"]
        guard let environmentValue,
              !environmentValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return environmentValue
    }

    public static func configuredWidgetBundleIdentifier(bundle: Bundle = .main) -> String? {
        if let value = bundle.object(forInfoDictionaryKey: widgetBundleIdentifierInfoKey) as? String,
           !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return value
        }

        let environmentValue = ProcessInfo.processInfo.environment["TASKISLAND_WIDGET_BUNDLE_ID"]
        guard let environmentValue,
              !environmentValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return environmentValue
    }

    public func write(_ snapshot: TaskWidgetSnapshot) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(snapshot)
        var wroteSnapshot = false
        var lastError: Error?

        for directory in writableSnapshotDirectories() {
            do {
                try ensureDirectoryExists(directory)
                try write(data, to: directory)
                wroteSnapshot = true
            } catch {
                lastError = error
            }
        }

        if !wroteSnapshot {
            if let lastError {
                throw lastError
            }
            throw TaskWidgetSnapshotStoreError.cannotCreateDirectory(try fallbackSnapshotDirectory())
        }
    }

    private func write(_ data: Data, to directory: URL) throws {
        let destinationURL = directory.appendingPathComponent(Self.snapshotFileName)
        let temporaryURL = directory.appendingPathComponent(".\(Self.snapshotFileName).tmp")
        try data.write(to: temporaryURL, options: [.atomic])

        if fileManager.fileExists(atPath: destinationURL.path) {
            _ = try fileManager.replaceItemAt(destinationURL, withItemAt: temporaryURL)
        } else {
            try fileManager.moveItem(at: temporaryURL, to: destinationURL)
        }
    }

    public func read() -> TaskWidgetSnapshot? {
        let urls = candidateSnapshotDirectories().map {
            $0.appendingPathComponent(Self.snapshotFileName)
        }

        for url in urls {
            guard let data = try? Data(contentsOf: url) else {
                continue
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let snapshot = try? decoder.decode(TaskWidgetSnapshot.self, from: data) {
                return snapshot
            }
        }

        return nil
    }

    public func snapshotURL() throws -> URL {
        try snapshotDirectory().appendingPathComponent(Self.snapshotFileName)
    }

    public func snapshotDirectory() throws -> URL {
        if let appGroupIdentifier,
           let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            return containerURL.appendingPathComponent("Widget", isDirectory: true)
        }

        let supportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return supportURL
            .appendingPathComponent("TaskIsland", isDirectory: true)
            .appendingPathComponent("Widget", isDirectory: true)
    }

    private func writableSnapshotDirectories() -> [URL] {
        let fallbackURL = try? fallbackSnapshotDirectory()

        var urls: [URL] = []

        if let appGroupIdentifier {
            urls.append(contentsOf: [
                fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
                    .appendingPathComponent("Widget", isDirectory: true),
                literalAppGroupSnapshotDirectory(identifier: appGroupIdentifier)
            ].compactMap { $0 })
        }

        if let widgetBundleIdentifier,
           let widgetContainerURL = localWidgetContainerSnapshotDirectory(identifier: widgetBundleIdentifier) {
            urls.append(widgetContainerURL)
        }

        if let fallbackURL {
            urls.append(fallbackURL)
        }

        var seenPaths: Set<String> = []
        return urls.filter { url in
            if seenPaths.contains(url.path) {
                return false
            }
            seenPaths.insert(url.path)
            return true
        }
    }

    private func candidateSnapshotDirectories() -> [URL] {
        var urls: [URL] = []
        if let appGroupIdentifier,
           let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            urls.append(containerURL.appendingPathComponent("Widget", isDirectory: true))
        }
        if let appGroupIdentifier,
           let literalURL = literalAppGroupSnapshotDirectory(identifier: appGroupIdentifier) {
            urls.append(literalURL)
        }
        if let widgetBundleIdentifier,
           let widgetContainerURL = localWidgetContainerSnapshotDirectory(identifier: widgetBundleIdentifier) {
            urls.append(widgetContainerURL)
        }
        if let fallbackURL = try? fallbackSnapshotDirectory() {
            urls.append(fallbackURL)
        }
        return urls
    }

    private func literalAppGroupSnapshotDirectory(identifier: String) -> URL? {
#if os(macOS)
        guard !identifier.isEmpty else { return nil }
        return fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Group Containers", isDirectory: true)
            .appendingPathComponent(identifier, isDirectory: true)
            .appendingPathComponent("Widget", isDirectory: true)
#else
        return nil
#endif
    }

    private func localWidgetContainerSnapshotDirectory(identifier: String) -> URL? {
#if os(macOS)
        guard !identifier.isEmpty else { return nil }
        return fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Containers", isDirectory: true)
            .appendingPathComponent(identifier, isDirectory: true)
            .appendingPathComponent("Data", isDirectory: true)
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("TaskIsland", isDirectory: true)
            .appendingPathComponent("Widget", isDirectory: true)
#else
        return nil
#endif
    }

    private func fallbackSnapshotDirectory() throws -> URL {
        let supportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return supportURL
            .appendingPathComponent("TaskIsland", isDirectory: true)
            .appendingPathComponent("Widget", isDirectory: true)
    }

    private func ensureDirectoryExists(_ directory: URL) throws {
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: directory.path, isDirectory: &isDirectory), isDirectory.boolValue {
            return
        }

        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            throw TaskWidgetSnapshotStoreError.cannotCreateDirectory(directory)
        }
    }
}
