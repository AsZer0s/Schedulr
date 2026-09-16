import Foundation
import Intents
import SwiftUI
import WidgetKit

private enum WidgetConstants {
    static let appGroup = "group.app.schedulr.shared"
    static let legacySnapshotKey = "schedulr.widget.snapshot.v1"
    static let catalogKey = "schedulr.widget.snapshot.v2"
    static let kind = "SchedulrWidget"
    static let deepLink = URL(string: "schedulr://home?homeWidget")!
    static let staleInterval: TimeInterval = 18 * 60 * 60
}

private struct CourseItem: Identifiable {
    let id: String
    let title: String
    let start: Date?
    let end: Date?
    let timeText: String
    let location: String
    let teacher: String
    let detail: String
    let color: String

    var secondaryText: String {
        [timeText, location, teacher, detail]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: " · ")
    }
}

private struct DayProjection {
    let date: Date
    let weekday: Int?
    let teachingWeek: String?
    let courses: [CourseItem]

    var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "M月d日"
        return "\(formatter.string(from: date)) \(Self.weekdayText(for: date, storedWeekday: weekday))"
    }

    var weekText: String {
        guard let teachingWeek else { return "" }
        return teachingWeek.contains("周") ? teachingWeek : "第 \(teachingWeek) 周"
    }

    private static func weekdayText(for date: Date, storedWeekday: Int?) -> String {
        let calendarWeekday = Calendar.autoupdatingCurrent.component(.weekday, from: date)
        switch calendarWeekday {
        case 1: return "周日"
        case 2: return "周一"
        case 3: return "周二"
        case 4: return "周三"
        case 5: return "周四"
        case 6: return "周五"
        case 7: return "周六"
        default:
            switch storedWeekday {
            case 1: return "周一"
            case 2: return "周二"
            case 3: return "周三"
            case 4: return "周四"
            case 5: return "周五"
            case 6: return "周六"
            case 7: return "周日"
            default: return ""
            }
        }
    }
}

private struct ScheduleProjection {
    let generatedAt: Date?
    let expiresAt: Date?
    let declaredStale: Bool
    let timetableName: String
    let semesterName: String
    let days: [DayProjection]

    func isStale(at date: Date) -> Bool {
        if declaredStale { return true }
        if let expiresAt {
            return date >= expiresAt
        }
        guard let generatedAt else { return false }
        return date.timeIntervalSince(generatedAt) > WidgetConstants.staleInterval
    }

    func selectedDay(at date: Date) -> DayProjection? {
        let calendar = Calendar.autoupdatingCurrent
        return days.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func nextDay(after day: DayProjection) -> DayProjection? {
        let calendar = Calendar.autoupdatingCurrent
        guard let nextDate = calendar.date(byAdding: .day, value: 1, to: day.date) else { return nil }
        return days.first { calendar.isDate($0.date, inSameDayAs: nextDate) }
    }

    func currentCourse(in day: DayProjection, at date: Date) -> CourseItem? {
        day.courses.first { course in
            guard let start = course.start, let end = course.end else { return false }
            return start <= date && date < end
        }
    }

    func nextCourse(in day: DayProjection, at date: Date) -> CourseItem? {
        day.courses.first { course in
            guard let start = course.start else { return false }
            return start > date
        }
    }

    /// Pure fallback policy: when today has no current or upcoming course,
    /// show only tomorrow's first course instead of leaking the rest of tomorrow's schedule.
    func fallbackCourse(after day: DayProjection) -> CourseItem? {
        nextDay(after: day)?.courses.first
    }

    func nextDaySummary(after day: DayProjection) -> String {
        guard let nextDay = nextDay(after: day) else {
            return "明天无课 · 好好休息"
        }
        guard !nextDay.courses.isEmpty else {
            return "明天无课 · 好好休息"
        }
        guard nextDay.teachingWeek != nil else {
            return "次日不在教学周"
        }
        return "明天 \(nextDay.courses.count) 节课"
    }
}

private enum SnapshotState {
    case noData
    case corrupt
    case data(ScheduleProjection)
}

private struct SchedulrEntry: TimelineEntry {
    let date: Date
    let state: SnapshotState

    static let placeholder = SchedulrEntry(
        date: Date(),
        state: .data(
            ScheduleProjection(
                generatedAt: Date(),
                expiresAt: nil,
                declaredStale: false,
                timetableName: "主课表",
                semesterName: "2026 秋季学期",
                days: [
                    DayProjection(
                        date: Date(),
                        weekday: nil,
                        teachingWeek: "3",
                        courses: [
                            CourseItem(
                                id: "preview-current",
                                title: "高等数学",
                                start: Calendar.autoupdatingCurrent.date(byAdding: .minute, value: -30, to: Date()),
                                end: Calendar.autoupdatingCurrent.date(byAdding: .minute, value: 60, to: Date()),
                                timeText: "08:00–09:40",
                                location: "教学楼 A201",
                                teacher: "",
                                detail: "",
                                color: ""
                            ),
                            CourseItem(
                                id: "preview-next",
                                title: "大学英语",
                                start: Calendar.autoupdatingCurrent.date(byAdding: .minute, value: 90, to: Date()),
                                end: Calendar.autoupdatingCurrent.date(byAdding: .minute, value: 180, to: Date()),
                                timeText: "10:00–11:40",
                                location: "综合楼 305",
                                teacher: "",
                                detail: "",
                                color: ""
                            ),
                        ]
                    ),
                    DayProjection(
                        date: Calendar.autoupdatingCurrent.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                        weekday: nil,
                        teachingWeek: "3",
                        courses: []
                    ),
                ]
            )
        )
    )
}

private struct SchedulrProvider: IntentTimelineProvider {
    typealias Intent = SelectTimetableIntent

    func placeholder(in context: Context) -> SchedulrEntry {
        .placeholder
    }

    func getSnapshot(for configuration: SelectTimetableIntent, in context: Context, completion: @escaping (SchedulrEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
        } else {
            completion(SchedulrEntry(date: Date(), state: SnapshotLoader.load(timetableId: configuration.timetable?.identifier)))
        }
    }

    func getTimeline(for configuration: SelectTimetableIntent, in context: Context, completion: @escaping (Timeline<SchedulrEntry>) -> Void) {
        let now = Date()
        let state = SnapshotLoader.load(timetableId: configuration.timetable?.identifier)
        let dates = TimelineDates.make(now: now, state: state)
        let entries = dates.map { SchedulrEntry(date: $0, state: state) }
        completion(Timeline(entries: entries, policy: .after(TimelineDates.reloadDate(now: now))))
    }
}

private enum TimelineDates {
    static func make(now: Date, state: SnapshotState) -> [Date] {
        let calendar = Calendar.autoupdatingCurrent
        let nextMidnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now) ?? now)
        var candidates = [now, nextMidnight]

        if case let .data(snapshot) = state {
            let coursePoints = snapshot.days
                .flatMap { $0.courses }
                .flatMap { [$0.start, $0.end] }
                .compactMap { $0 }
            candidates.append(contentsOf: coursePoints.filter { $0 > now && $0 < nextMidnight })
            if let expiresAt = snapshot.expiresAt, expiresAt > now {
                candidates.append(expiresAt)
            }
        }

        let sorted = candidates.sorted()
        var result: [Date] = []
        for date in sorted {
            if let last = result.last, abs(date.timeIntervalSince(last)) < 1 {
                continue
            }
            result.append(date)
        }
        return result.isEmpty ? [now] : result
    }

    static func reloadDate(now: Date) -> Date {
        let calendar = Calendar.autoupdatingCurrent
        let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now) ?? now)
        return calendar.date(byAdding: .minute, value: 5, to: midnight) ?? now.addingTimeInterval(60 * 60)
    }
}

private enum SnapshotLoader {
    static func load(timetableId: String?) -> SnapshotState {
        guard let defaults = UserDefaults(suiteName: WidgetConstants.appGroup) else {
            return .noData
        }
        if let timetableId {
            guard let storedCatalog = defaults.object(forKey: WidgetConstants.catalogKey),
                  let data = jsonData(from: storedCatalog),
                  let object = try? JSONSerialization.jsonObject(with: data),
                  let catalog = object as? [String: Any],
                  let timetables = value(catalog, keys: ["timetables"]) as? [[String: Any]],
                  let selected = timetables.first(where: { string(from: value($0, keys: ["timetableId"])) == timetableId }),
                  let snapshot = dictionary(selected, keys: ["snapshot"]),
                  let state = loadProjection(snapshot) else {
                return .noData
            }
            return state
        }
        if let storedCatalog = defaults.object(forKey: WidgetConstants.catalogKey),
           let data = jsonData(from: storedCatalog),
           let object = try? JSONSerialization.jsonObject(with: data),
           let catalog = object as? [String: Any] {
            let selectedId = timetableId ?? string(from: value(catalog, keys: ["defaultTimetableId"]))
            if let selectedId,
               let timetables = value(catalog, keys: ["timetables"]) as? [[String: Any]],
               let selected = timetables.first(where: { string(from: value($0, keys: ["timetableId"])) == selectedId }),
               let snapshot = dictionary(selected, keys: ["snapshot"]),
               let state = loadProjection(snapshot) {
                return state
            }
        }
        guard let stored = defaults.object(forKey: WidgetConstants.legacySnapshotKey) else {
            return .noData
        }
        guard let data = jsonData(from: stored),
              let object = try? JSONSerialization.jsonObject(with: data),
              let rawRoot = object as? [String: Any] else {
            return .corrupt
        }
        return loadProjection(rawRoot) ?? .corrupt
    }

    private static func loadProjection(_ rawRoot: [String: Any]) -> SnapshotState? {
        let root = dictionary(rawRoot, keys: ["snapshot", "projection", "data"]) ?? rawRoot
        let rootState = string(from: value(root, keys: ["state"]))?.lowercased() ?? ""
        if ["nodata", "no_data", "notimetable", "no_timetable", "empty", "unavailable"].contains(rootState) {
            return .noData
        }
        if ["corrupt", "invalid"].contains(rootState) {
            return .corrupt
        }
        guard let projection = parseProjection(root) else {
            return nil
        }
        return .data(projection)
    }

    private static func jsonData(from stored: Any) -> Data? {
        if let data = stored as? Data { return data }
        if let text = stored as? String { return text.data(using: .utf8) }
        if JSONSerialization.isValidJSONObject(stored) {
            return try? JSONSerialization.data(withJSONObject: stored)
        }
        return nil
    }

    private static func parseProjection(_ root: [String: Any]) -> ScheduleProjection? {
        guard let todayObject = dictionary(root, keys: ["today", "todaySchedule", "todayProjection"]),
              let today = day(from: todayObject) else {
            return nil
        }

        var days = [today]
        if let tomorrowObject = dictionary(root, keys: ["tomorrow", "tomorrowSchedule", "tomorrowProjection"]),
           let tomorrow = day(from: tomorrowObject) {
            days.append(tomorrow)
        }
        if let futureDayValues = value(root, keys: ["futureDays"]) as? [Any] {
            days.append(contentsOf: futureDayValues.compactMap { payload in
                guard let object = payload as? [String: Any] else { return nil }
                return day(from: object)
            })
        }

        let calendar = Calendar.autoupdatingCurrent
        days.sort { $0.date < $1.date }
        var uniqueDays: [DayProjection] = []
        for candidate in days where !uniqueDays.contains(where: { calendar.isDate($0.date, inSameDayAs: candidate.date) }) {
            uniqueDays.append(candidate)
        }

        let generatedAt = date(from: value(root, keys: ["generatedAt", "updatedAt", "createdAt", "timestamp"]))
        let expiresAt = date(from: value(root, keys: ["expiresAt", "validUntil"]))
        let schemaVersion = int(from: value(root, keys: ["schemaVersion", "version"]))
        guard schemaVersion == nil || schemaVersion == 1 else {
            return nil
        }
        let state = string(from: value(root, keys: ["state"]))?.lowercased() ?? ""
        let timetableName = string(from: value(root, keys: ["timetableName"])) ?? "课表"
        let semesterName = string(from: value(root, keys: ["semesterName"])) ?? ""

        return ScheduleProjection(
            generatedAt: generatedAt,
            expiresAt: expiresAt,
            declaredStale: ["stale", "expired"].contains(state),
            timetableName: timetableName,
            semesterName: semesterName,
            days: uniqueDays
        )
    }

    private static func day(from raw: [String: Any]) -> DayProjection? {
        guard let date = date(from: value(raw, keys: ["date"])) else { return nil }
        let courses = courses(from: value(raw, keys: ["courses", "items"]), day: date)
        return DayProjection(
            date: date,
            weekday: int(from: value(raw, keys: ["weekday"])),
            teachingWeek: string(from: value(raw, keys: ["teachingWeek"])),
            courses: courses
        )
    }

    private static func courses(from value: Any?, day: Date?) -> [CourseItem] {
        guard let values = value as? [Any] else { return [] }
        return values.compactMap { course(from: $0, day: day) }.sorted { lhs, rhs in
            (lhs.start ?? .distantFuture) < (rhs.start ?? .distantFuture)
        }
    }

    private static func course(from payload: Any?, day: Date?) -> CourseItem? {
        guard let raw = payload as? [String: Any],
              let title = string(from: value(raw, keys: ["title", "name", "courseName"])),
              !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let explicitTime = string(from: value(raw, keys: ["timeText", "time", "periodText"]))
        let timeBounds = timeRangeBounds(explicitTime, day: day)
        let start = date(from: value(raw, keys: ["start", "startAt", "startTime", "beginsAt"])) ?? timeBounds.start
        let end = date(from: value(raw, keys: ["end", "endAt", "endTime", "endsAt"])) ?? timeBounds.end
        let periodText = periodRange(
            start: string(from: value(raw, keys: ["startPeriod"])),
            end: string(from: value(raw, keys: ["endPeriod"]))
        )
        let timeText = explicitTime ?? periodText ?? formattedRange(start: start, end: end)
        let location = string(from: value(raw, keys: ["location", "classroom", "room"])) ?? ""
        let teacher = string(from: value(raw, keys: ["teacher", "instructor"])) ?? ""
        let detail = string(from: value(raw, keys: ["detail", "details", "note", "period"])) ?? ""
        let color = string(from: value(raw, keys: ["color"])) ?? ""
        let id = string(from: value(raw, keys: ["id", "sessionId", "courseId"]))
            ?? [title, timeText, location].joined(separator: "|")

        return CourseItem(
            id: id,
            title: title,
            start: start,
            end: end,
            timeText: timeText,
            location: location,
            teacher: teacher,
            detail: detail,
            color: color
        )
    }

    private static func value(_ dictionary: [String: Any], keys: [String]) -> Any? {
        for key in keys {
            if let value = dictionary[key], !(value is NSNull) { return value }
        }
        return nil
    }

    private static func dictionary(_ dictionary: [String: Any], keys: [String]) -> [String: Any]? {
        value(dictionary, keys: keys) as? [String: Any]
    }

    private static func string(from value: Any?) -> String? {
        if let string = value as? String { return string }
        if let number = value as? NSNumber { return number.stringValue }
        return nil
    }

    private static func int(from value: Any?) -> Int? {
        if let integer = value as? Int { return integer }
        if let number = value as? NSNumber { return number.intValue }
        if let text = value as? String { return Int(text) }
        return nil
    }

    private static func date(from value: Any?) -> Date? {
        if let seconds = value as? Double {
            return Date(timeIntervalSince1970: seconds > 10_000_000_000 ? seconds / 1000 : seconds)
        }
        if let number = value as? NSNumber {
            let seconds = number.doubleValue
            return Date(timeIntervalSince1970: seconds > 10_000_000_000 ? seconds / 1000 : seconds)
        }
        guard let text = value as? String else { return nil }
        for formatter in isoFormatters {
            if let parsed = formatter.date(from: text) { return parsed }
        }
        for formatter in localDateFormatters {
            if let parsed = formatter.date(from: text) { return parsed }
        }
        return nil
    }

    private static let isoFormatters: [ISO8601DateFormatter] = {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]
        return [fractional, standard]
    }()

    private static let localDateFormatters: [DateFormatter] = {
        ["yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd'T'HH:mm", "yyyy-MM-dd HH:mm", "yyyy-MM-dd"].map { format in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.dateFormat = format
            return formatter
        }
    }()

    private static func formattedRange(start: Date?, end: Date?) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.autoupdatingCurrent
        formatter.dateFormat = "HH:mm"
        if let start, let end {
            return "\(formatter.string(from: start))–\(formatter.string(from: end))"
        }
        if let start { return formatter.string(from: start) }
        return ""
    }

    private static func periodRange(start: String?, end: String?) -> String? {
        guard let start, !start.isEmpty else { return nil }
        if let end, !end.isEmpty, end != start {
            return "第\(start)–\(end)节"
        }
        return "第\(start)节"
    }

    private static func timeRangeBounds(_ text: String?, day: Date?) -> (start: Date?, end: Date?) {
        guard let text, let day,
              let expression = try? NSRegularExpression(pattern: "(?<![0-9])(?:[01]?[0-9]|2[0-3]):[0-5][0-9]") else {
            return (nil, nil)
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = expression.matches(in: text, range: range).compactMap { match -> String? in
            guard let swiftRange = Range(match.range, in: text) else { return nil }
            return String(text[swiftRange])
        }
        guard let first = matches.first else { return (nil, nil) }
        let calendar = Calendar.autoupdatingCurrent
        func date(for clock: String) -> Date? {
            let parts = clock.split(separator: ":").compactMap { Int($0) }
            guard parts.count == 2 else { return nil }
            return calendar.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: day)
        }
        return (date(for: first), matches.dropFirst().first.flatMap(date(for:)))
    }
}

private struct SchedulrWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SchedulrEntry

    var body: some View {
        Group {
            switch entry.state {
            case .noData:
                StatusView(title: "暂无课表", detail: "打开 Schedulr 后将课表同步到桌面组件")
            case .corrupt:
                StatusView(title: "课表数据异常", detail: "请打开 Schedulr 刷新桌面组件")
            case let .data(snapshot):
                if let selectedDay = snapshot.selectedDay(at: entry.date) {
                    if selectedDay.teachingWeek == nil {
                        StatusView(title: "当日不在教学周", detail: "点击打开 Schedulr 查看学期设置")
                    } else {
                        scheduleView(snapshot, selectedDay: selectedDay)
                    }
                } else {
                    StatusView(title: "当日课表不可用", detail: "请打开 Schedulr 刷新桌面组件")
                }
            }
        }
        .widgetURL(WidgetConstants.deepLink)
        .schedulrWidgetBackground()
    }

    @ViewBuilder
    private func scheduleView(_ snapshot: ScheduleProjection, selectedDay: DayProjection) -> some View {
        let current = snapshot.currentCourse(in: selectedDay, at: entry.date)
        let next = snapshot.nextCourse(in: selectedDay, at: entry.date)
        let fallback = current == nil && next == nil ? snapshot.fallbackCourse(after: selectedDay) : nil
        let featured = current ?? next ?? fallback
        let featuredLabel: String = {
            if current != nil { return "正在上课" }
            if next != nil { return "下一节" }
            if fallback != nil { return "明天第一节" }
            return "明天无课"
        }()
        let featuredEmptyTitle = fallback == nil ? "明天无课 · 好好休息" : "当日暂无课程"
        let featuredEmptyDetail = fallback == nil ? "" : "享受空闲时间"
        let nextDaySummary = snapshot.nextDaySummary(after: selectedDay)
        VStack(alignment: .leading, spacing: family == .systemSmall ? 7 : 9) {
            HeaderView(
                dateText: selectedDay.dateText,
                weekText: selectedDay.weekText,
                stale: snapshot.isStale(at: entry.date)
            )

            if family == .systemSmall {
                FeaturedCourseView(
                    label: featuredLabel,
                    course: featured,
                    emptyTitle: featuredEmptyTitle,
                    emptyDetail: featuredEmptyDetail
                )
                Spacer(minLength: 0)
                Text(nextDaySummary)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            } else {
                HStack(alignment: .top, spacing: 12) {
                    FeaturedCourseView(
                        label: featuredLabel,
                        course: featured,
                        emptyTitle: featuredEmptyTitle,
                        emptyDetail: featuredEmptyDetail
                    )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let next, next.id != current?.id {
                        FeaturedCourseView(label: "接下来", course: next)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Divider()

                if family == .systemLarge {
                    Text("当日课程")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    let displayed = Array(selectedDay.courses.prefix(3))
                    if displayed.isEmpty {
                        Text("当日暂无其他课程")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(displayed) { CourseRow(course: $0) }
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 5) {
                    Image(systemName: "sunrise")
                    Text(nextDaySummary)
                        .lineLimit(1)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

private struct HeaderView: View {
    let dateText: String
    let weekText: String
    let stale: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(dateText)
                .font(.caption.bold())
                .lineLimit(1)
            Spacer(minLength: 4)
            Text(weekText)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
            if stale {
                Image(systemName: "exclamationmark.arrow.triangle.2.circlepath")
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .accessibilityLabel("数据可能已过期")
            }
        }
    }
}

private struct FeaturedCourseView: View {
    let label: String
    let course: CourseItem?
    let emptyTitle: String
    let emptyDetail: String

    init(
        label: String,
        course: CourseItem?,
        emptyTitle: String = "当日暂无课程",
        emptyDetail: String = "享受空闲时间"
    ) {
        self.label = label
        self.course = course
        self.emptyTitle = emptyTitle
        self.emptyDetail = emptyDetail
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            if let course {
                Text(course.title)
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                if !course.secondaryText.isEmpty {
                    Text(course.secondaryText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
            } else {
                Text(emptyTitle)
                    .font(.headline)
                    .lineLimit(2)
                if !emptyDetail.isEmpty {
                    Text(emptyDetail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

private struct CourseRow: View {
    let course: CourseItem

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(course.timeText.isEmpty ? "--:--" : course.timeText)
                .font(.caption.monospacedDigit())
                .foregroundColor(.accentColor)
                .frame(width: 78, alignment: .leading)
                .lineLimit(1)
            VStack(alignment: .leading, spacing: 1) {
                Text(course.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                let details = [course.location, course.teacher, course.detail]
                    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                    .joined(separator: " · ")
                if !details.isEmpty {
                    Text(details)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

private struct StatusView: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "calendar.badge.clock")
                .font(.title2)
                .foregroundColor(.accentColor)
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
            Spacer(minLength: 0)
        }
        .padding()
    }
}

private extension View {
    @ViewBuilder
    func schedulrWidgetBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(Color.clear, for: .widget)
        } else {
            background(Color.white)
        }
    }
}

@main
struct SchedulrWidget: Widget {
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: WidgetConstants.kind, intent: SelectTimetableIntent.self, provider: SchedulrProvider()) { entry in
            SchedulrWidgetView(entry: entry)
        }
        .configurationDisplayName("SchedulrWidget")
        .description("查看当前、下一节课程和当日课表摘要。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
