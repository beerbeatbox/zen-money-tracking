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
        let formatted = formatter.string(from: NSNumber(value: abs(entry.amount))) ?? "฿0"
        // Add minus sign prefix to show spending as negative
        return "-\(formatted)"
    }

    private var formattedBudget: String? {
        guard let budgetRemaining = entry.budgetRemaining else { return nil }
        let hasFraction = abs(budgetRemaining.truncatingRemainder(dividingBy: 1)) > 0.0001
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "THB"
        formatter.currencySymbol = "฿"
        formatter.maximumFractionDigits = hasFraction ? 2 : 0
        formatter.minimumFractionDigits = hasFraction ? 2 : 0
        return formatter.string(from: NSNumber(value: budgetRemaining))
    }

    private var updatedLabel: String? {
        guard let updatedAt = entry.updatedAt else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "Updated \(formatter.string(from: updatedAt))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isSmall ? 10 : 12) {
            Text(dateLabel)
                .font(isSmall ? .subheadline.weight(.semibold) : .title3.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .center)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            HStack(alignment: .lastTextBaseline, spacing: isSmall ? 6 : 8) {
                Text("Spending")
                    .font(isSmall ? .caption.weight(.semibold) : .body.weight(.semibold))
                    .foregroundStyle(Color.black.opacity(0.6))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(formattedAmount)
                    .font(.system(size: isSmall ? 14 : 18, weight: .semibold))
                    .foregroundStyle(Color.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .allowsTightening(true)
                    .layoutPriority(1)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !isSmall, let updatedLabel {
                Text(updatedLabel)
                    .font(.caption)
                    .foregroundStyle(Color.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // Tapping the widget opens the app in "Quick Add" mode.
        // Note the triple slash so the deep-link path becomes `/quick-add`.
        .widgetURL(URL(string: "anti:///quick-add?type=expense")!)
    }
}

struct ThumbySpending: Widget {
    let kind: String = widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                ThumbySpendingEntryView(entry: entry)
                    .containerBackground(Color.white, for: .widget)
            } else {
                ThumbySpendingEntryView(entry: entry)
                    .background(Color.white)
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
