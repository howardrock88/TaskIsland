import SwiftUI
import TaskIslandCore

struct QuickAddView: View {
    @EnvironmentObject private var settings: AppSettings

    let onSubmit: (String, TaskPriority) -> Void
    let onCancel: () -> Void
    private let shouldAutoFocus: Bool

    @FocusState private var isFocused: Bool
    @State private var title = ""
    @State private var selectedPriority: TaskPriority = .medium

    init(
        initialTitle: String = "",
        initialPriority: TaskPriority = .medium,
        shouldAutoFocus: Bool = true,
        onSubmit: @escaping (String, TaskPriority) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.onSubmit = onSubmit
        self.onCancel = onCancel
        self.shouldAutoFocus = shouldAutoFocus
        _title = State(initialValue: initialTitle)
        _selectedPriority = State(initialValue: initialPriority)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.tint)

                TextField(t("明天 10点 发周报 #工作 !高 /30m", "Tomorrow 10am weekly report #work !high /30m"), text: $title)
                    .textFieldStyle(.plain)
                    .font(.system(size: 22, weight: .semibold))
                    .focused($isFocused)
                    .onSubmit(submit)

                Button {
                    onCancel()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(QuickAddCloseButtonStyle())
                .help(t("关闭", "Close"))
            }

            HStack(spacing: 8) {
                ForEach(TaskPriority.allCases) { priority in
                    Button {
                        selectedPriority = priority
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(priority.tintColor(settings: settings))
                                .frame(width: 8, height: 8)
                            Text(priority.localizedShortTitle(settings: settings))
                        }
                    }
                    .buttonStyle(PriorityChoiceButtonStyle(isSelected: selectedPriority == priority, tint: priority.tintColor(settings: settings)))
                }
            }

            HStack {
                Text(t("支持日期、标签、优先级和预计时长", "Supports dates, tags, priorities, and duration"))
                Spacer()
                Text(t("Esc 取消", "Esc to cancel"))
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .frame(width: 500, height: 156)
        .taskIslandGlass(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .background(quickAddTint)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            if settings.darkGlassMode {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.26),
                                Color(red: 0.03, green: 0.07, blue: 0.10).opacity(0.26),
                                Color.black.opacity(0.34)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .allowsHitTesting(false)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(settings.darkGlassMode ? 0.34 : 0.26), lineWidth: 1)
        }
        .preferredColorScheme(settings.darkGlassMode ? .dark : nil)
        .onAppear {
            if shouldAutoFocus {
                isFocused = true
            }
        }
        .onExitCommand(perform: onCancel)
    }

    private var quickAddTint: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    colors: settings.darkGlassMode
                        ? [
                            Color.black.opacity(0.36),
                            Color(red: 0.10, green: 0.17, blue: 0.24).opacity(0.30),
                            Color(red: 0.12, green: 0.28, blue: 0.34).opacity(0.18)
                        ]
                        : [
                            Color.white.opacity(0.08),
                            Color(red: 0.55, green: 0.92, blue: 1.0).opacity(0.05),
                            Color.green.opacity(0.04)
                        ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private func submit() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        onSubmit(trimmedTitle, selectedPriority)
    }

    private func t(_ chinese: String, _ english: String) -> String {
        settings.localized(chinese, english)
    }
}

private struct PriorityChoiceButtonStyle: ButtonStyle {
    let isSelected: Bool
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? tint.opacity(0.22) : Color.white.opacity(0.05), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(isSelected ? tint.opacity(0.55) : .white.opacity(0.16), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.16), value: isSelected)
    }
}

private struct QuickAddCloseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.secondary)
            .background(.ultraThinMaterial, in: Circle())
            .overlay {
                Circle()
                    .stroke(.white.opacity(configuration.isPressed ? 0.20 : 0.34), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}
