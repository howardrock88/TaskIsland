import Foundation

public struct TaskWidgetActionRequestStore {
    public static let pendingFocusTaskIDKey = "TaskIslandPendingWidgetFocusTaskID"

    public let appGroupIdentifier: String?

    public init(
        appGroupIdentifier: String? = TaskWidgetSnapshotStore.configuredAppGroupIdentifier()
    ) {
        self.appGroupIdentifier = appGroupIdentifier?.isEmpty == false
            ? appGroupIdentifier
            : nil
    }

    @discardableResult
    public func requestFocus(taskID: UUID) -> Bool {
        guard let defaults else { return false }
        defaults.set(taskID.uuidString, forKey: Self.pendingFocusTaskIDKey)
        defaults.synchronize()
        return true
    }

    public func consumeFocusTaskID() -> UUID? {
        guard let defaults,
              let rawValue = defaults.string(forKey: Self.pendingFocusTaskIDKey),
              let taskID = UUID(uuidString: rawValue) else {
            return nil
        }

        defaults.removeObject(forKey: Self.pendingFocusTaskIDKey)
        return taskID
    }

    private var defaults: UserDefaults? {
        guard let appGroupIdentifier else { return nil }
        return UserDefaults(suiteName: appGroupIdentifier)
    }
}
