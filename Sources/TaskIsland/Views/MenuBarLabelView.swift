import SwiftUI
import TaskIslandCore

struct MenuBarLabelView: View {
    @EnvironmentObject private var store: TaskStore
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: store.incompleteCount == 0 ? "checkmark.circle.fill" : "circle.dashed.inset.filled")
            if settings.showTitleInMenuBar {
                Text(labelText)
                    .lineLimit(1)
            } else {
                Text("\(store.incompleteCount)")
                    .monospacedDigit()
            }
        }
    }

    private var labelText: String {
        if store.incompleteCount == 0 {
            return "完成"
        }

        let title = store.menuBarTitle
        if title.count <= 18 {
            return title
        }
        return "\(title.prefix(17))..."
    }
}
