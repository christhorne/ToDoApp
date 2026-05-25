import SwiftUI
import SwiftData

struct TaskRow: View {
    @Bindable var item: TodoItem
    @Environment(\.modelContext) private var modelContext

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        f.dateTimeStyle = .numeric
        return f
    }()

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

            if item.recurrenceRuleId != nil {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Repeats")
            }

            VStack(alignment: .leading, spacing: 1) {
                if item.isComplete {
                    Text(item.title)
                        .strikethrough()
                        .foregroundStyle(.secondary)
                } else {
                    TextField("Task", text: $item.title)
                        .onSubmit(handleTitleSubmit)
                }
                if let completedAt = item.completedAt {
                    Text("Done \(Self.relativeFormatter.localizedString(for: completedAt, relativeTo: .now))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .contextMenu {
            Section("Repeat") {
                Button("Daily") { setRecurrence(kind: .daily, intervalDays: 1) }
                Button("Weekly") { setRecurrence(kind: .weekly, intervalDays: 7) }
                Button("Every 3 days") { setRecurrence(kind: .everyN, intervalDays: 3) }
                if item.recurrenceRuleId != nil {
                    Button("Don't repeat", role: .destructive) { clearRecurrence() }
                }
            }
        }
    }

    private func toggleComplete() {
        withAnimation {
            if !item.isComplete {
                // about to mark complete — materialize next instance if recurring
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
        // First time we mark a task recurring, it becomes its own family root.
        // TodoItem has no UUID, so we mint one to link future instances back.
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
}
