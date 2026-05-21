import SwiftUI

struct TaskRow: View {
    @Bindable var item: TodoItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                toggleComplete()
            } label: {
                Image(systemName: item.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isComplete ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .strikethrough(item.isComplete)
                    .foregroundStyle(item.isComplete ? .secondary : .primary)
                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func toggleComplete() {
        item.completedAt = item.isComplete ? nil : .now
    }
}
