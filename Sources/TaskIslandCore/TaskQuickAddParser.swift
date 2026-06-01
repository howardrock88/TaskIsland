import Foundation

public struct ParsedTaskInput: Equatable {
    public var title: String
    public var priority: TaskPriority
    public var dueAt: Date?
    public var reminderAt: Date?
    public var repeatRule: TaskRepeatRule?
    public var tags: [String]
    public var projectName: String?
    public var estimatedMinutes: Int?
    public var isToday: Bool
}

public enum TaskQuickAddParser {
    public static func parse(
        _ rawInput: String,
        fallbackPriority: TaskPriority = .medium,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> ParsedTaskInput {
        var working = rawInput
        var priority = fallbackPriority
        var tags: [String] = []
        var projectName: String?
        var estimatedMinutes: Int?
        var dueAt: Date?
        var reminderAt: Date?
        var repeatRule: TaskRepeatRule?
        var isToday = false

        let priorityMatches = matches(in: working, pattern: #"(?i)(^|\s)(!高|!high|!p1|p1|优先级高|高优|!中|!medium|!p2|p2|中优|!低|!low|!p3|p3|低优)(?=\s|$)"#)
        for match in priorityMatches.reversed() {
            let token = substring(working, range: match.range(at: 2)).lowercased()
            if token.contains("高") || token.contains("high") || token.contains("p1") {
                priority = .high
            } else if token.contains("低") || token.contains("low") || token.contains("p3") {
                priority = .low
            } else {
                priority = .medium
            }
            working = removeRange(match.range(at: 2), from: working)
        }

        let tagMatches = matches(in: working, pattern: #"(?<!\S)#([\p{L}\p{N}_-]+)"#)
        for match in tagMatches.reversed() {
            let tag = substring(working, range: match.range(at: 1))
            if !tags.contains(tag) {
                tags.insert(tag, at: 0)
            }
            working = removeRange(match.range, from: working)
        }

        let projectMatches = matches(in: working, pattern: #"(?<!\S)\+([\p{L}\p{N}_-]+)"#)
        if let match = projectMatches.last {
            projectName = substring(working, range: match.range(at: 1))
            working = removeRange(match.range, from: working)
        }

        let durationPatterns = [
            #"(?<!\S)/(\d{1,3})m(?=\s|$)"#,
            #"(?<!\S)/(\d{1,2})h(?=\s|$)"#,
            #"(?<!\S)(\d{1,3})\s*分钟(?=\s|$)"#,
            #"(?<!\S)(\d{1,2})\s*小时(?=\s|$)"#
        ]
        for pattern in durationPatterns {
            guard estimatedMinutes == nil,
                  let match = matches(in: working, pattern: pattern).last else {
                continue
            }
            let number = Int(substring(working, range: match.range(at: 1))) ?? 0
            if pattern.contains("h") || pattern.contains("小时") {
                estimatedMinutes = number * 60
            } else {
                estimatedMinutes = number
            }
            working = removeRange(match.range, from: working)
        }

        let dateResult = parsedDate(in: working, now: now, calendar: calendar)
        let time = parsedTime(in: working)
        let repeatResult = parsedRepeatRule(in: working)

        if let date = dateResult.date {
            dueAt = applying(time: time.components, to: date, calendar: calendar)
            reminderAt = dueAt
            isToday = calendar.isDate(dueAt ?? date, inSameDayAs: now)
        } else if let components = time.components {
            let today = calendar.startOfDay(for: now)
            dueAt = applying(time: components, to: today, calendar: calendar)
            reminderAt = dueAt
            isToday = true
        }

        if working.localizedStandardContains("今天") {
            isToday = true
        }

        if let rule = repeatResult.rule {
            repeatRule = rule
        }

        let metadataRanges = nonOverlappingRanges([
            dateResult.range,
            time.range,
            repeatResult.range
        ])
        for range in metadataRanges.sorted(by: { $0.location > $1.location }) {
            working = removeRange(range, from: working)
        }

        let title = normalizedTitle(working)
        return ParsedTaskInput(
            title: title.isEmpty ? normalizedTitle(rawInput) : title,
            priority: priority,
            dueAt: dueAt,
            reminderAt: reminderAt,
            repeatRule: repeatRule,
            tags: tags,
            projectName: projectName,
            estimatedMinutes: estimatedMinutes,
            isToday: isToday
        )
    }

    private static func parsedDate(
        in text: String,
        now: Date,
        calendar: Calendar
    ) -> (date: Date?, range: NSRange?) {
        let startOfToday = calendar.startOfDay(for: now)
        let simpleDates: [(String, Int)] = [
            ("今天", 0),
            ("今晚", 0),
            ("明天", 1),
            ("明晚", 1),
            ("后天", 2)
        ]

        for (token, offset) in simpleDates {
            if let range = nsRange(of: token, in: text),
               let date = calendar.date(byAdding: .day, value: offset, to: startOfToday) {
                return (date, range)
            }
        }

        for weekday in WeekdayToken.allCases {
            if let range = nsRange(of: "每\(weekday.title)", in: text) {
                let target = nextDate(
                    matchingWeekday: weekday.calendarWeekday,
                    after: now,
                    calendar: calendar
                )
                return (target, range)
            }

            guard let range = nsRange(of: weekday.title, in: text) else { continue }
            let target = nextDate(
                matchingWeekday: weekday.calendarWeekday,
                after: now,
                calendar: calendar
            )
            return (target, range)
        }

        return (nil, nil)
    }

    private static func parsedRepeatRule(in text: String) -> (rule: TaskRepeatRule?, range: NSRange?) {
        let tokens: [(String, TaskRepeatRule)] = [
            ("每天", .daily),
            ("每日", .daily),
            ("每周", .weekly),
            ("每星期", .weekly),
            ("每月", .monthly),
            ("每年", .yearly)
        ]

        for (token, rule) in tokens {
            if let range = nsRange(of: token, in: text) {
                return (rule, range)
            }
        }

        return (nil, nil)
    }

    private static func parsedTime(in text: String) -> (components: DateComponents?, range: NSRange?) {
        let clockPatterns = [
            #"(\d{1,2})[:：](\d{2})"#,
            #"(\d{1,2})\s*点半"#,
            #"(\d{1,2})\s*点"#
        ]

        for pattern in clockPatterns {
            guard let match = matches(in: text, pattern: pattern).first else { continue }
            var hour = Int(substring(text, range: match.range(at: 1))) ?? 0
            let minute: Int
            if match.numberOfRanges > 2, match.range(at: 2).location != NSNotFound {
                minute = Int(substring(text, range: match.range(at: 2))) ?? 0
            } else if pattern.contains("点半") {
                minute = 30
            } else {
                minute = 0
            }
            if text.contains("下午") || text.contains("晚上") || text.contains("今晚") || text.contains("明晚") {
                if hour < 12 { hour += 12 }
            }
            return (DateComponents(hour: min(hour, 23), minute: min(minute, 59)), match.range)
        }

        if let range = nsRange(of: "今晚", in: text) ?? nsRange(of: "晚上", in: text) {
            return (DateComponents(hour: 20, minute: 0), range)
        }
        if let range = nsRange(of: "明早", in: text) ?? nsRange(of: "早上", in: text) {
            return (DateComponents(hour: 9, minute: 0), range)
        }

        return (nil, nil)
    }

    private static func applying(
        time components: DateComponents?,
        to date: Date,
        calendar: Calendar
    ) -> Date {
        guard let components else { return date }
        return calendar.date(
            bySettingHour: components.hour ?? 9,
            minute: components.minute ?? 0,
            second: 0,
            of: date
        ) ?? date
    }

    private static func nextDate(
        matchingWeekday weekday: Int,
        after date: Date,
        calendar: Calendar
    ) -> Date {
        let startOfToday = calendar.startOfDay(for: date)
        let currentWeekday = calendar.component(.weekday, from: startOfToday)
        var offset = weekday - currentWeekday
        if offset <= 0 { offset += 7 }
        return calendar.date(byAdding: .day, value: offset, to: startOfToday) ?? startOfToday
    }

    private static func normalizedTitle(_ text: String) -> String {
        text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func matches(in text: String, pattern: String) -> [NSTextCheckingResult] {
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return [] }
        return expression.matches(
            in: text,
            range: NSRange(text.startIndex..<text.endIndex, in: text)
        )
    }

    private static func substring(_ text: String, range: NSRange) -> String {
        guard range.location != NSNotFound,
              let stringRange = Range(range, in: text) else {
            return ""
        }
        return String(text[stringRange])
    }

    private static func removeRange(_ range: NSRange, from text: String) -> String {
        guard range.location != NSNotFound,
              let stringRange = Range(range, in: text) else {
            return text
        }
        var copy = text
        copy.removeSubrange(stringRange)
        return copy
    }

    private static func nonOverlappingRanges(_ ranges: [NSRange?]) -> [NSRange] {
        var accepted: [NSRange] = []
        for range in ranges.compactMap({ $0 }).filter({ $0.location != NSNotFound }) {
            let overlapsExisting = accepted.contains { existing in
                NSIntersectionRange(existing, range).length > 0
            }
            if !overlapsExisting {
                accepted.append(range)
            }
        }
        return accepted
    }

    private static func nsRange(of token: String, in text: String) -> NSRange? {
        guard let range = text.range(of: token) else { return nil }
        return NSRange(range, in: text)
    }
}

private enum WeekdayToken: CaseIterable {
    case sunday
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday

    var title: String {
        switch self {
        case .sunday:
            return "周日"
        case .monday:
            return "周一"
        case .tuesday:
            return "周二"
        case .wednesday:
            return "周三"
        case .thursday:
            return "周四"
        case .friday:
            return "周五"
        case .saturday:
            return "周六"
        }
    }

    var calendarWeekday: Int {
        switch self {
        case .sunday:
            return 1
        case .monday:
            return 2
        case .tuesday:
            return 3
        case .wednesday:
            return 4
        case .thursday:
            return 5
        case .friday:
            return 6
        case .saturday:
            return 7
        }
    }
}
