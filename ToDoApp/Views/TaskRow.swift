import SwiftUI
import SwiftData

struct TaskRow: View {
    @Bindable var item: TodoItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @State private var expanded = false
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
        VStack(alignment: .leading, spacing: 6) {
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

                if item.recurrenceRuleId != nil {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Repeats")
                }

                VStack(alignment: .leading, spacing: 1) {
                    titleView
                    if let completedAt = item.completedAt {
                        Text("Done \(Self.relativeFormatter.localizedString(for: completedAt, relativeTo: .now))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)

                attachmentBadge
            }

            if case .list(let items) = item.attachment, expanded {
                checklist(items: items)
            }
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
            Section("Repeat") {
                Button("Daily") { setRecurrence(kind: .daily, intervalDays: 1) }
                Button("Weekly") { setRecurrence(kind: .weekly, intervalDays: 7) }
                Button("Every 3 days") { setRecurrence(kind: .everyN, intervalDays: 3) }
                if item.recurrenceRuleId != nil {
                    Button("Don't repeat", role: .destructive) { clearRecurrence() }
                }
            }
        }
        .sheet(isPresented: $showingTimePicker) {
            timePickerSheet
        }
    }

    // MARK: - Attachment badge (trailing)

    @ViewBuilder
    private var attachmentBadge: some View {
        switch item.attachment {
        case .map(let label, let address):
            Button {
                openMap(address: address)
            } label: {
                Label(label, systemImage: "mappin.circle.fill")
                    .labelStyle(.iconOnly)
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open \(label) in Maps")

        case .list(let items):
            Button {
                withAnimation(.snappy) { expanded.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Text("\(items.filter(\.done).count)/\(items.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(.quaternary, in: Capsule())
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(items.filter(\.done).count) of \(items.count) checked")
            .accessibilityHint(expanded ? "Collapse list" : "Expand list")

        case .none:
            EmptyView()
        }
    }

    // MARK: - Title rendering

    @ViewBuilder
    private var titleView: some View {
        if item.isComplete {
            timedTitle(strikethrough: true)
                .foregroundStyle(.secondary)
        } else if item.time != nil {
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

    // MARK: - Time picker sheet

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

    // MARK: - Inline checklist

    private func checklist(items: [ChecklistItem]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(items) { entry in
                Button {
                    toggle(entry, in: items)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: entry.done ? "checkmark.square.fill" : "square")
                            .font(.body)
                            .foregroundStyle(entry.done ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                        Text(entry.text)
                            .font(.subheadline)
                            .strikethrough(entry.done)
                            .foregroundStyle(entry.done ? .secondary : .primary)
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, 34)
        .padding(.top, 2)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Actions

    private func toggleComplete() {
        withAnimation {
            if !item.isComplete {
                if let ruleId = item.recurrenceRuleId,
                   let rule = fetchRule(id: ruleId) {
                    let nextDay = rule.nextDate(after: item.day)
                    let next = TodoItem(
                        title: item.title,
                        day: nextDay,
                        sortOrder: item.sortOrder,
                        assigneeId: item.assigneeId,
                        time: item.time,
                        recurrenceRuleId: item.recurrenceRuleId,
                        recurrenceParentId: item.recurrenceParentId
                    )
                    modelContext.insert(next)
                }
            }
            item.completedAt = item.isComplete ? nil : .now
        }
    }

    private func handleTitleSubmit() {
        if item.title.trimmingCharacters(in: .whitespaces).isEmpty {
            modelContext.delete(item)
        }
    }

    private func setRecurrence(kind: RecurrenceKind, intervalDays: Int) {
        let rule: RecurrenceRule
        if let existingId = item.recurrenceRuleId, let existing = fetchRule(id: existingId) {
            existing.kindRaw = kind.rawValue
            existing.intervalDays = intervalDays
            rule = existing
        } else {
            let newRule = RecurrenceRule(kind: kind, intervalDays: intervalDays)
            modelContext.insert(newRule)
            rule = newRule
        }
        item.recurrenceRuleId = rule.id
        if item.recurrenceParentId == nil {
            item.recurrenceParentId = UUID()
        }
    }

    private func clearRecurrence() {
        item.recurrenceRuleId = nil
        item.recurrenceParentId = nil
    }

    private func fetchRule(id: UUID) -> RecurrenceRule? {
        let descriptor = FetchDescriptor<RecurrenceRule>(predicate: #Predicate { $0.id == id })
        return try? modelContext.fetch(descriptor).first
    }

    private func openMap(address: String) {
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "http://maps.apple.com/?address=\(encoded)") else { return }
        openURL(url)
    }

    private func toggle(_ entry: ChecklistItem, in items: [ChecklistItem]) {
        var updated = items
        guard let index = updated.firstIndex(where: { $0.id == entry.id }) else { return }
        withAnimation(.snappy) {
            updated[index].done.toggle()
            item.attachment = .list(items: updated)
        }
    }
}
