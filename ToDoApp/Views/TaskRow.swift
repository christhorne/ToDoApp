import SwiftUI
import SwiftData

struct TaskRow: View {
    @Bindable var item: TodoItem
    @Environment(\.modelContext) private var modelContext

    @State private var showingTimePicker = false
    @State private var timeDraft: Date = .now

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        f.dateTimeStyle = .numeric
        return f
    }()

    private static let timeFormatStyle = Date.FormatStyle.dateTime.hour().minute()

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Button {
                toggleComplete()
            } label: {
                Image(systemName: item.isComplete ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundStyle(item.isComplete ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 1) {
                titleView
                if let completedAt = item.completedAt {
                    Text("Done \(Self.relativeFormatter.localizedString(for: completedAt, relativeTo: .now))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .contextMenu {
            Button {
                timeDraft = item.time ?? defaultTimeDraft()
                showingTimePicker = true
            } label: {
                Label(item.time == nil ? "Set time…" : "Change time…", systemImage: "clock")
            }
            if item.time != nil {
                Button(role: .destructive) {
                    item.time = nil
                } label: {
                    Label("Clear time", systemImage: "clock.badge.xmark")
                }
            }
        }
        .sheet(isPresented: $showingTimePicker) {
            timePickerSheet
        }
    }

    @ViewBuilder
    private var titleView: some View {
        if item.isComplete {
            timedTitle(strikethrough: true)
                .foregroundStyle(.secondary)
        } else if item.time != nil {
            // Time prefix is decorative; not editable inline. Show it adjacent
            // to the editable title so users still see the chip clearly.
            HStack(spacing: 6) {
                Text(item.time!, format: Self.timeFormatStyle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("·")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Task", text: $item.title)
                    .onSubmit(handleTitleSubmit)
            }
        } else {
            TextField("Task", text: $item.title)
                .onSubmit(handleTitleSubmit)
        }
    }

    @ViewBuilder
    private func timedTitle(strikethrough: Bool) -> some View {
        if let time = item.time {
            HStack(spacing: 6) {
                Text(time, format: Self.timeFormatStyle)
                    .font(.caption.weight(.semibold))
                Text("·")
                    .font(.caption)
                Text(item.title)
                    .strikethrough(strikethrough)
            }
        } else {
            Text(item.title)
                .strikethrough(strikethrough)
        }
    }

    private var timePickerSheet: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Time",
                    selection: $timeDraft,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()
                Spacer()
            }
            .navigationTitle("Set Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingTimePicker = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        item.time = timeDraft
                        showingTimePicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func defaultTimeDraft() -> Date {
        // Round 'now' up to the next quarter hour as a friendly starting point.
        let calendar = Calendar.current
        let now = Date.now
        let minute = calendar.component(.minute, from: now)
        let bumpedMinute = ((minute / 15) + 1) * 15
        return calendar.date(
            bySettingHour: calendar.component(.hour, from: now),
            minute: bumpedMinute % 60,
            second: 0,
            of: bumpedMinute >= 60 ? now.addingTimeInterval(3600) : now
        ) ?? now
    }

    private func toggleComplete() {
        withAnimation {
            item.completedAt = item.isComplete ? nil : .now
        }
    }

    private func handleTitleSubmit() {
        if item.title.trimmingCharacters(in: .whitespaces).isEmpty {
            modelContext.delete(item)
        }
    }
}
