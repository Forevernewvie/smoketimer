import SwiftUI
import WidgetKit

private enum SmokeTimerWidgetKeys {
    static let appGroupId = "group.com.example.smokeTimer.widget"
    static let launchUrl = "smoketimer://home-widget"
    static let hasRecord = "has_record"
    static let primaryValue = "primary_value"
    static let statusTitle = "status_title"
    static let statusDetail = "status_detail"
    static let nextAlertLabel = "next_alert_label"
    static let nextAlertValue = "next_alert_value"
    static let todayCountLabel = "today_count_label"
    static let todaySpendLabel = "today_spend_label"
}

private enum SmokeTimerWidgetPalette {
    static let surface = Color(red: 17 / 255, green: 24 / 255, blue: 39 / 255)
    static let surfaceBorder = Color(red: 35 / 255, green: 48 / 255, blue: 68 / 255)
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 226 / 255, green: 232 / 255, blue: 240 / 255)
    static let textMuted = Color(red: 148 / 255, green: 163 / 255, blue: 184 / 255)
    static let accent = Color(red: 45 / 255, green: 212 / 255, blue: 191 / 255)
}

struct SmokeTimerWidgetEntry: TimelineEntry {
    let date: Date
    let payload: SmokeTimerWidgetPayload
}

struct SmokeTimerWidgetPayload {
    let hasRecord: Bool
    let primaryValue: String
    let statusTitle: String
    let statusDetail: String
    let nextAlertLabel: String
    let nextAlertValue: String
    let todayCountLabel: String
    let todaySpendLabel: String

    /// Creates a payload from explicitly provided widget fields.
    init(
        hasRecord: Bool,
        primaryValue: String,
        statusTitle: String,
        statusDetail: String,
        nextAlertLabel: String,
        nextAlertValue: String,
        todayCountLabel: String,
        todaySpendLabel: String
    ) {
        self.hasRecord = hasRecord
        self.primaryValue = primaryValue
        self.statusTitle = statusTitle
        self.statusDetail = statusDetail
        self.nextAlertLabel = nextAlertLabel
        self.nextAlertValue = nextAlertValue
        self.todayCountLabel = todayCountLabel
        self.todaySpendLabel = todaySpendLabel
    }

    /// Creates a placeholder payload used before app data is available.
    static let placeholder = SmokeTimerWidgetPayload(
        hasRecord: false,
        primaryValue: "첫 기록 전",
        statusTitle: "기록을 남기면 타이머가 시작돼요",
        statusDetail: "앱을 열어 첫 기록을 남겨보세요",
        nextAlertLabel: "다음 알림",
        nextAlertValue: "첫 기록 후 시작",
        todayCountLabel: "오늘 0개비",
        todaySpendLabel: "가격 설정 필요"
    )

    /// Reads the latest payload persisted by Flutter into the shared App Group.
    init(userDefaults: UserDefaults?) {
        hasRecord = userDefaults?.string(forKey: SmokeTimerWidgetKeys.hasRecord) == "true"
        primaryValue = userDefaults?.string(forKey: SmokeTimerWidgetKeys.primaryValue) ?? Self.placeholder.primaryValue
        statusTitle = userDefaults?.string(forKey: SmokeTimerWidgetKeys.statusTitle) ?? Self.placeholder.statusTitle
        statusDetail = userDefaults?.string(forKey: SmokeTimerWidgetKeys.statusDetail) ?? Self.placeholder.statusDetail
        nextAlertLabel = userDefaults?.string(forKey: SmokeTimerWidgetKeys.nextAlertLabel) ?? Self.placeholder.nextAlertLabel
        nextAlertValue = userDefaults?.string(forKey: SmokeTimerWidgetKeys.nextAlertValue) ?? Self.placeholder.nextAlertValue
        todayCountLabel = userDefaults?.string(forKey: SmokeTimerWidgetKeys.todayCountLabel) ?? Self.placeholder.todayCountLabel
        todaySpendLabel = userDefaults?.string(forKey: SmokeTimerWidgetKeys.todaySpendLabel) ?? Self.placeholder.todaySpendLabel
    }

    /// Builds a concise one-line summary suited for the lock screen inline family.
    var inlineSummary: String {
        "\(primaryValue) · \(nextAlertValue)"
    }

    /// Extracts a compact numeric display for circular lock screen widgets.
    var circularMetric: String {
        guard hasRecord else {
            return "대기"
        }

        let digits = primaryValue.filter { $0.isNumber }
        if digits.count > 3 {
            return "999+"
        }
        return digits.isEmpty ? primaryValue : digits
    }

    /// Returns a short unit or fallback label for circular lock screen widgets.
    var circularCaption: String {
        hasRecord ? "분" : "기록 전"
    }
}

struct SmokeTimerWidgetProvider: TimelineProvider {
    /// Supplies placeholder content for the widget gallery and loading states.
    func placeholder(in context: Context) -> SmokeTimerWidgetEntry {
        SmokeTimerWidgetEntry(date: Date(), payload: .placeholder)
    }

    /// Supplies a snapshot for previews and transient widget rendering.
    func getSnapshot(in context: Context, completion: @escaping (SmokeTimerWidgetEntry) -> Void) {
        completion(loadEntry())
    }

    /// Builds a timeline that refreshes periodically while using shared app data.
    func getTimeline(in context: Context, completion: @escaping (Timeline<SmokeTimerWidgetEntry>) -> Void) {
        let entry = loadEntry()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    /// Loads the current widget payload from the shared App Group store.
    private func loadEntry() -> SmokeTimerWidgetEntry {
        let defaults = UserDefaults(suiteName: SmokeTimerWidgetKeys.appGroupId)
        let payload = SmokeTimerWidgetPayload(userDefaults: defaults)
        return SmokeTimerWidgetEntry(date: Date(), payload: payload)
    }
}

struct SmokeTimerWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: SmokeTimerWidgetProvider.Entry

    /// Renders the selected widget family using the shared calm utility layout.
    var body: some View {
        switch family {
        case .accessoryInline:
            SmokeTimerAccessoryInlineView(payload: entry.payload)
        case .accessoryCircular:
            SmokeTimerAccessoryCircularView(payload: entry.payload)
        case .accessoryRectangular:
            SmokeTimerAccessoryRectangularView(payload: entry.payload)
        default:
            SmokeTimerHomeSurfaceView(entry: entry, family: family)
        }
    }
}

struct SmokeTimerHomeSurfaceView: View {
    let entry: SmokeTimerWidgetProvider.Entry
    let family: WidgetFamily

    /// Renders the standard home screen widget surface for small and medium sizes.
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(SmokeTimerWidgetPalette.surface)

            VStack(alignment: .leading, spacing: 10) {
                Text("지금 상태")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SmokeTimerWidgetPalette.textMuted)

                Text(entry.payload.primaryValue)
                    .font(
                        family == .systemSmall
                            ? .system(size: 26, weight: .bold)
                            : .system(size: 30, weight: .bold)
                    )
                    .monospacedDigit()
                    .foregroundStyle(SmokeTimerWidgetPalette.textPrimary)
                    .lineLimit(1)

                Text(entry.payload.statusTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SmokeTimerWidgetPalette.textSecondary)
                    .lineLimit(family == .systemSmall ? 2 : 1)

                Text(entry.payload.statusDetail)
                    .font(.caption)
                    .foregroundStyle(SmokeTimerWidgetPalette.textMuted)
                    .lineLimit(1)

                Divider()
                    .overlay(SmokeTimerWidgetPalette.surfaceBorder)

                HStack(alignment: .firstTextBaseline) {
                    Text(entry.payload.nextAlertLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SmokeTimerWidgetPalette.textMuted)
                    Spacer(minLength: 8)
                    Text(entry.payload.nextAlertValue)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SmokeTimerWidgetPalette.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                if family != .systemSmall {
                    HStack {
                        Text(entry.payload.todayCountLabel)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(SmokeTimerWidgetPalette.accent)
                        Spacer(minLength: 8)
                        Text(entry.payload.todaySpendLabel)
                            .font(.caption)
                            .foregroundStyle(SmokeTimerWidgetPalette.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
            }
            .padding(16)
        }
        .widgetURL(URL(string: SmokeTimerWidgetKeys.launchUrl))
    }
}

struct SmokeTimerAccessoryInlineView: View {
    let payload: SmokeTimerWidgetPayload

    /// Renders the inline lock screen family with compressed status text.
    var body: some View {
        Text(payload.inlineSummary)
            .widgetURL(URL(string: SmokeTimerWidgetKeys.launchUrl))
    }
}

struct SmokeTimerAccessoryCircularView: View {
    let payload: SmokeTimerWidgetPayload

    /// Renders the circular lock screen family with a compact elapsed metric.
    var body: some View {
        ZStack {
            Circle()
                .stroke(SmokeTimerWidgetPalette.surfaceBorder, lineWidth: 1.5)
            VStack(spacing: 0) {
                Text(payload.circularMetric)
                    .font(.system(size: payload.hasRecord ? 18 : 14, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(payload.circularCaption)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(SmokeTimerWidgetPalette.textMuted)
                    .lineLimit(1)
            }
            .padding(8)
        }
        .widgetURL(URL(string: SmokeTimerWidgetKeys.launchUrl))
    }
}

struct SmokeTimerAccessoryRectangularView: View {
    let payload: SmokeTimerWidgetPayload

    /// Renders the rectangular lock screen family with elapsed time and next alert.
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(payload.primaryValue)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .monospacedDigit()
                .lineLimit(1)

            Text(payload.statusTitle)
                .font(.caption.weight(.semibold))
                .lineLimit(1)

            HStack(spacing: 4) {
                Text(payload.nextAlertLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(payload.nextAlertValue)
                    .font(.caption2.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Text(payload.todayCountLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .widgetURL(URL(string: SmokeTimerWidgetKeys.launchUrl))
    }
}

struct SmokeTimerWidget: Widget {
    let kind = "SmokeTimerWidget"

    /// Configures the main smoke timer widget for home and lock screen families.
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SmokeTimerWidgetProvider()) { entry in
            SmokeTimerWidgetView(entry: entry)
        }
        .configurationDisplayName("Smoke Timer")
        .description("경과 시간, 다음 알림, 오늘 기록을 홈과 잠금화면에서 빠르게 확인합니다.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular,
        ])
    }
}
