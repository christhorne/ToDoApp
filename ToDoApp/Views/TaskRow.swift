import SwiftUI

struct TaskRow: View {
    @Bindable var item: TodoItem

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        f.dateTimeStyle = .numeric
        return f
    }()

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                toggleComplete()
            } label: {
                Image(systemName: item.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isComplete ? item.scope.color : Color.secondary)
                    .padding(.vertical, 2)
                    .padding(.trailing, 2)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .fontWeight(.medium)
                    .strikethrough(item.isComplete)
                    .foregroundStyle(item.isComplete ? .secondary : .primary)
                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let completedAt = item.completedAt {
                    Text("Done \(Self.relativeFormatter.localizedString(for: completedAt, relativeTo: .now))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .contextMenu {
            Section("Move to") {
                ForEach(TaskScope.allCases) { scope in
                    Button {
                        guard scope != item.scope else { return }
                        item.scope = scope
                    } label: {
                        Label(scope.displayName, systemImage: scope.systemImage)
                    }
                    .disabled(scope == item.scope)
                }
            }
        }
    }

    private func toggleComplete() {
        withAnimation {
            item.completedAt = item.isComplete ? nil : .now
        }
    }
}
