import SwiftUI
import WidgetKit

struct FridgeWidget: Widget {
    let kind: String = "FridgeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FridgeWidgetProvider()) { entry in
            FridgeWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Tasks")
        .description("Open tasks from your Today list — your fridge in pixels.")
        .supportedFamilies([.systemMedium, .systemLarge, .accessoryRectangular, .accessoryCircular])
    }
}

struct FridgeWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FridgeWidgetEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            VStack(spacing: 0) {
                Text("\(entry.items.count)")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Today")
                    .font(.caption2)
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("Today — \(entry.items.count)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                ForEach(entry.items.prefix(2)) { item in
                    Text("• \(item.title)")
                        .font(.caption2)
                        .lineLimit(1)
                }
            }
        default:
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "sun.max.fill")
                        .foregroundStyle(.orange)
                    Text("Today")
                        .font(.headline)
                    Spacer()
                    Text("\(entry.items.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if entry.items.isEmpty {
                    Text("Nothing on the list.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entry.items.prefix(family == .systemLarge ? 8 : 4)) { item in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(item.title)
                                .font(.callout)
                                .lineLimit(2)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }
}
