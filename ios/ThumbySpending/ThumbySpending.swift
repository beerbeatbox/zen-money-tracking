//
//  ThumbySpending.swift
//  ThumbySpending
//
//  Created by Woraprot Dechrut on 10/12/25.
//

import WidgetKit
import SwiftUI

private let appGroupIdentifier = "group.com.beerlab.thumby"
private let spendingAmountKey = "today_spending_amount"
private let spendingUpdatedAtKey = "today_spending_updated_at"
private let widgetKind = "ThumbySpending"

struct TodaySpendingData {
    let amount: Double
    let updatedAt: Date?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TodaySpendingEntry {
        TodaySpendingEntry(date: Date(), amount: 0, updatedAt: nil)
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
        return TodaySpendingEntry(date: date, amount: data.amount, updatedAt: data.updatedAt)
    }

    private func loadTodaySpending(referenceDate: Date) -> TodaySpendingData {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return TodaySpendingData(amount: 0, updatedAt: nil)
        }

        let storedAmount = defaults.object(forKey: spendingAmountKey) as? Double ?? 0
        let timestamp = defaults.object(forKey: spendingUpdatedAtKey) as? Double
        let updatedAt = timestamp.map { Date(timeIntervalSince1970: $0) }

        guard let updatedAt, Calendar.current.isDate(updatedAt, inSameDayAs: referenceDate) else {
            return TodaySpendingData(amount: 0, updatedAt: updatedAt)
        }

        return TodaySpendingData(amount: storedAmount, updatedAt: updatedAt)
    }
}

struct TodaySpendingEntry: TimelineEntry {
    let date: Date
    let amount: Double
    let updatedAt: Date?
}

struct ThumbySpendingEntryView: View {
    var entry: TodaySpendingEntry

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: entry.amount)) ?? "$0.00"
    }

    private var updatedLabel: String? {
        guard let updatedAt = entry.updatedAt else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "Updated \(formatter.string(from: updatedAt))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your spending today")
                .font(.headline)
                .foregroundStyle(.primary)

            Text(formattedAmount)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.primary)

            if let updatedLabel {
                Text(updatedLabel)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

struct ThumbySpending: Widget {
    let kind: String = widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                ThumbySpendingEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                ThumbySpendingEntryView(entry: entry)
                    .background()
            }
        }
        .configurationDisplayName("Your spending today")
        .description("See today's spending right from your Home Screen.")
    }
}

#Preview(as: .systemSmall) {
    ThumbySpending()
} timeline: {
    TodaySpendingEntry(date: .now, amount: 42.50, updatedAt: .now)
    TodaySpendingEntry(date: .now, amount: 0, updatedAt: nil)
}
