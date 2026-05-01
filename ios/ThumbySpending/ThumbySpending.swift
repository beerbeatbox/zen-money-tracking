//
//  ThumbySpending.swift
//  ThumbySpending
//
//  Created by Woraprot Dechrut on 10/12/25.
//

import WidgetKit
import SwiftUI

private let appGroupIdentifier = "group.com.dopaminelab.thumby"
private let spendingAmountKey = "today_spending_amount"
private let spendingUpdatedAtKey = "today_spending_updated_at"
private let budgetRemainingKey = "today_budget_remaining"
private let budgetUpdatedAtKey = "today_budget_updated_at"
private let widgetKind = "ThumbySpending"

// MARK: - Theme

private enum ThumbySpendingTheme {
    static let background = Color(red: 0.11, green: 0.32, blue: 0.30)
    static let pillBackground = Color(red: 0.16, green: 0.38, blue: 0.36)
    static let blob = Color(red: 0.42, green: 0.72, blue: 0.68).opacity(0.28)
    static let dot = Color(red: 0.55, green: 0.82, blue: 0.78).opacity(0.45)
    static let squiggleStroke = Color(red: 0.50, green: 0.78, blue: 0.74)
}

private struct ThumbySpendingBackground: View {
    var body: some View {
        ZStack {
            ThumbySpendingTheme.background
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack(alignment: .topTrailing) {
                    // Large circle blob clipped at top-right corner
                    Circle()
                        .fill(ThumbySpendingTheme.blob)
                        .frame(width: w * 0.58, height: w * 0.58)
                        .offset(x: w * 0.16, y: -h * 0.10)
                    // Small dot near the blob
                    Circle()
                        .fill(ThumbySpendingTheme.dot)
                        .frame(width: 5, height: 5)
                        .offset(x: -w * 0.26, y: h * 0.20)
                    // Small dot lower right
                    Circle()
                        .fill(ThumbySpendingTheme.dot.opacity(0.75))
                        .frame(width: 5, height: 5)
                        .offset(x: -w * 0.08, y: h * 0.50)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
    }
}

/// Hand-drawn-style flourish under the spending amount.
private struct SpendingSquiggle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: 0, y: h * 0.55))
        path.addCurve(
            to: CGPoint(x: w * 0.32, y: h * 0.35),
            control1: CGPoint(x: w * 0.08, y: h * 0.15),
            control2: CGPoint(x: w * 0.20, y: h * 0.12)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.62, y: h * 0.58),
            control1: CGPoint(x: w * 0.42, y: h * 0.55),
            control2: CGPoint(x: w * 0.52, y: h * 0.72)
        )
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.38),
            control1: CGPoint(x: w * 0.74, y: h * 0.42),
            control2: CGPoint(x: w * 0.88, y: h * 0.22)
        )
        return path
    }
}

struct TodaySpendingData {
    let amount: Double
    let updatedAt: Date?
    let budgetRemaining: Double?
    let budgetUpdatedAt: Date?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TodaySpendingEntry {
        TodaySpendingEntry(date: Date(), amount: 0, updatedAt: nil, budgetRemaining: nil, budgetUpdatedAt: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodaySpendingEntry) -> Void) {
        completion(entry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodaySpendingEntry>) -> Void) {
        let currentDate = Date()
        let entry = entry(for: currentDate)
        let startOfTomorrow = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: Calendar.current.startOfDay(for: currentDate)
        ) ?? currentDate.addingTimeInterval(60 * 60 * 6)

        let timeline = Timeline(entries: [entry], policy: .after(startOfTomorrow))
        completion(timeline)
    }

    private func entry(for date: Date) -> TodaySpendingEntry {
        let data = loadTodaySpending(referenceDate: date)
        return TodaySpendingEntry(
            date: date,
            amount: data.amount,
            updatedAt: data.updatedAt,
            budgetRemaining: data.budgetRemaining,
            budgetUpdatedAt: data.budgetUpdatedAt
        )
    }

    private func loadTodaySpending(referenceDate: Date) -> TodaySpendingData {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return TodaySpendingData(amount: 0, updatedAt: nil, budgetRemaining: nil, budgetUpdatedAt: nil)
        }

        let storedAmount = defaults.object(forKey: spendingAmountKey) as? Double ?? 0
        let timestamp = defaults.object(forKey: spendingUpdatedAtKey) as? Double
        let updatedAt = timestamp.map { Date(timeIntervalSince1970: $0) }

        let budgetTimestamp = defaults.object(forKey: budgetUpdatedAtKey) as? Double
        let budgetUpdatedAt = budgetTimestamp.map { Date(timeIntervalSince1970: $0) }

        var budgetRemaining: Double? = nil
        if let budgetUpdatedAt = budgetUpdatedAt,
           Calendar.current.isDate(budgetUpdatedAt, inSameDayAs: referenceDate) {
            budgetRemaining = defaults.object(forKey: budgetRemainingKey) as? Double
        }

        guard let updatedAt, Calendar.current.isDate(updatedAt, inSameDayAs: referenceDate) else {
            return TodaySpendingData(amount: 0, updatedAt: updatedAt, budgetRemaining: budgetRemaining, budgetUpdatedAt: budgetUpdatedAt)
        }

        return TodaySpendingData(amount: storedAmount, updatedAt: updatedAt, budgetRemaining: budgetRemaining, budgetUpdatedAt: budgetUpdatedAt)
    }
}

struct TodaySpendingEntry: TimelineEntry {
    let date: Date
    let amount: Double
    let updatedAt: Date?
    let budgetRemaining: Double?
    let budgetUpdatedAt: Date?
}

struct ThumbySpendingEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: TodaySpendingEntry

    private var isSmall: Bool {
        family == .systemSmall
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEE d MMM yyyy"
        return formatter.string(from: entry.date)
    }

    private var formattedAmount: String {
        let hasFraction = abs(entry.amount.truncatingRemainder(dividingBy: 1)) > 0.0001
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "THB"
        formatter.currencySymbol = "฿"
        formatter.maximumFractionDigits = hasFraction ? 2 : 0
        formatter.minimumFractionDigits = hasFraction ? 2 : 0
        return formatter.string(from: NSNumber(value: abs(entry.amount))) ?? "฿0"
    }

    private var updatedLabel: String? {
        guard let updatedAt = entry.updatedAt else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "Updated \(formatter.string(from: updatedAt))"
    }

    private var datePill: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.caption.weight(.semibold))
                .imageScale(.small)
            Text(dateLabel)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(ThumbySpendingTheme.pillBackground, in: Capsule())
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }

    @ViewBuilder
    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            datePill
            Spacer(minLength: 10)
            Text("Spending")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.white.opacity(0.95))
            Spacer(minLength: 8)
            Text(formattedAmount)
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .minimumScaleFactor(0.45)
                .allowsTightening(true)
            SpendingSquiggle()
                .stroke(ThumbySpendingTheme.squiggleStroke, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                .frame(width: 76, height: 16)
                .padding(.top, 6)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(EdgeInsets(top: 6, leading: 14, bottom: 13, trailing: 12))
    }

    @ViewBuilder
    private var mediumLargeLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            datePill
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                Text("Spending")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.95))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(formattedAmount)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .allowsTightening(true)
            }
            HStack(spacing: 0) {
                SpendingSquiggle()
                    .stroke(ThumbySpendingTheme.squiggleStroke, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                    .frame(width: 88, height: 18)
                Spacer(minLength: 0)
            }
            if let updatedLabel {
                Text(updatedLabel)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16))
    }

    var body: some View {
        Group {
            if isSmall {
                smallLayout
            } else {
                mediumLargeLayout
            }
        }
        // Tapping the widget opens the app in "Quick Add" mode.
        // Note the triple slash so the deep-link path becomes `/quick-add`.
        .widgetURL(URL(string: "baht:///quick-add?type=expense")!)
    }
}

struct ThumbySpending: Widget {
    let kind: String = widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                ThumbySpendingEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        ThumbySpendingBackground()
                    }
            } else {
                ZStack(alignment: .topLeading) {
                    ThumbySpendingBackground()
                    ThumbySpendingEntryView(entry: entry)
                }
            }
        }
        .configurationDisplayName("Your spending today")
        .description("See today's spending right from your Home Screen.")
    }
}

#Preview(as: .systemSmall) {
    ThumbySpending()
} timeline: {
    TodaySpendingEntry(date: .now, amount: 42.50, updatedAt: .now, budgetRemaining: 157.50, budgetUpdatedAt: .now)
    TodaySpendingEntry(date: .now, amount: 0, updatedAt: nil, budgetRemaining: nil, budgetUpdatedAt: nil)
}

#Preview(as: .systemMedium) {
    ThumbySpending()
} timeline: {
    TodaySpendingEntry(date: .now, amount: 1_250, updatedAt: .now, budgetRemaining: 500, budgetUpdatedAt: .now)
}
