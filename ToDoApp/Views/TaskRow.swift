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
                    .foregroundStyle(item.isComplete ? item.scope.color : Color.secondary)
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
            Spacer(minLength: 0)
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
