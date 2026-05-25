import SwiftUI
import SwiftData

struct TaskRow: View {
    @Bindable var item: TodoItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @State private var expanded = false

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        f.dateTimeStyle = .numeric
        return f
    }()

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

                attachmentBadge
            }

            if case .list(let items) = item.attachment, expanded {
                checklist(items: items)
            }
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

    // MARK: - Inline checklist

    private func checklist(items: [ChecklistItem]) -> some View {
        // Indent so the checklist visually aligns under the title, past the
        // task checkbox + spacing.
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
            item.completedAt = item.isComplete ? nil : .now
        }
    }

    private func handleTitleSubmit() {
        if item.title.trimmingCharacters(in: .whitespaces).isEmpty {
            modelContext.delete(item)
        }
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
