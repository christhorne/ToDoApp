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

            assigneeChip
                .onTapGesture { cycleAssignee() }

            Spacer(minLength: 0)
        }
        .contextMenu {
            ForEach(Assignee.all) { assignee in
                Button {
                    item.assigneeId = assignee.id
                } label: {
                    Label("Assign to \(assignee.displayName)", systemImage: "person.crop.circle")
                }
            }
            if item.assigneeId != nil {
                Button(role: .destructive) {
                    item.assigneeId = nil
                } label: {
                    Label("Unassign", systemImage: "person.crop.circle.badge.xmark")
                }
            }
        }
    }

    @ViewBuilder
    private var assigneeChip: some View {
        if let assignee = Assignee.find(id: item.assigneeId) {
            Text(assignee.initial)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(assignee.color, in: Circle())
                .accessibilityLabel("Assigned to \(assignee.displayName)")
        } else {
            Circle()
                .strokeBorder(Color.secondary.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [2.5, 2.5]))
                .frame(width: 24, height: 24)
                .accessibilityLabel("Unassigned")
        }
    }

    private func cycleAssignee() {
        switch item.assigneeId {
        case nil: item.assigneeId = Assignee.alex.id
        case Assignee.alex.id: item.assigneeId = Assignee.sam.id
        default: item.assigneeId = nil
        }
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
