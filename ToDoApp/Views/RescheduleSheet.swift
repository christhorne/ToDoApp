import SwiftUI

struct RescheduleSheet: View {
    @Bindable var item: TodoItem
    @Environment(\.dismiss) private var dismiss
    @State private var picked: Date = .now

    private static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f
    }()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    quickButton(
                        "Tomorrow",
                        systemImage: "arrow.right.circle",
                        date: CalendarHelper.tomorrow
                    )
                    quickButton(
                        "This Weekend",
                        systemImage: "beach.umbrella",
                        date: CalendarHelper.upcomingSaturday
                    )
                }

                Section("Pick a date") {
                    DatePicker(
                        "Date",
                        selection: $picked,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()

                    Button("Move to \(Self.shortDate.string(from: picked))") {
                        apply(picked)
                    }
                }
            }
            .navigationTitle("Move task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear { picked = item.day }
    }

    private func quickButton(_ title: String, systemImage: String, date: Date) -> some View {
        Button {
            apply(date)
        } label: {
            HStack {
                Label(title, systemImage: systemImage)
                Spacer()
                Text(Self.shortDate.string(from: date))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func apply(_ date: Date) {
        item.day = CalendarHelper.weekCalendar.startOfDay(for: date)
        dismiss()
    }
}
