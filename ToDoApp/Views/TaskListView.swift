import SwiftUI
import SwiftData

struct TaskListView: View {
    let scope: TaskScope

    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode
    @Query(sort: [SortDescriptor(\TodoItem.sortOrder), SortDescriptor(\TodoItem.createdAt)])
    private var allItems: [TodoItem]
    @State private var showingSettings = false
    @State private var showCompletedSection = false
    @State private var draftTitle = ""
    @FocusState private var addFieldFocused: Bool

    private let rowInsets = EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)

    private static let todayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f
    }()

    private var isEditing: Bool {
        editMode?.wrappedValue.isEditing ?? false
    }

    private var openItems: [TodoItem] {
        allItems.filter { $0.scope == scope && $0.completedAt == nil }
    }

    private var completedThisScope: [TodoItem] {
        allItems
            .filter { $0.scope == scope }
            .filter { item in
                guard let completedAt = item.completedAt else { return false }
                return scope.includesCompletion(at: completedAt)
            }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    private var navigationTitleText: String {
        switch scope {
        case .daily: Self.todayFormatter.string(from: .now)
        case .weekly, .weekend: scope.displayName
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(openItems.enumerated()), id: \.element.id) { index, item in
                    TaskRow(item: item)
                        .listRowInsets(rowInsets)
                        .listRowSeparator(index == 0 ? .hidden : .automatic, edges: .top)
                        .swipeActions(edge: .leading) {
                            ForEach(otherScopes(for: item)) { other in
                                Button {
                                    withAnimation {
                                        item.scope = other
                                    }
                                } label: {
                                    Label("Move to \(other.displayName)", systemImage: other.systemImage)
                                }
                                .tint(other.color)
                            }
                        }
                }
                .onDelete(perform: deleteOpen)
                .onMove(perform: moveOpen)

                if !isEditing {
                    inlineAddRow
                        .listRowInsets(rowInsets)
                        .listRowSeparator(openItems.isEmpty ? .hidden : .automatic, edges: .top)
                }

                if !completedThisScope.isEmpty {
                    DisclosureGroup(isExpanded: $showCompletedSection) {
                        ForEach(completedThisScope) { item in
                            TaskRow(item: item)
                                .listRowInsets(rowInsets)
                        }
                        .onDelete(perform: deleteCompleted)
                    } label: {
                        completedSectionLabel
                    }
                    .listRowInsets(rowInsets)
                }
            }
            .listStyle(.plain)
            .navigationTitle(navigationTitleText)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .tint(scope.color)
    }

    private var inlineAddRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundStyle(scope.color)
            TextField("Add a task", text: $draftTitle)
                .focused($addFieldFocused)
                .submitLabel(.return)
                .onSubmit { commitInline() }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .onTapGesture { addFieldFocused = true }
    }

    private var completedSectionLabel: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.square.fill")
                .foregroundStyle(scope.color)
            Text(scope.completedSectionLabel)
                .fontWeight(.medium)
            Spacer()
            Text("\(completedThisScope.count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(scope.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(scope.color.opacity(0.15), in: Capsule())
        }
        .font(.subheadline)
    }

    private func commitInline() {
        let trimmed = draftTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            addFieldFocused = false
            return
        }
        let nextOrder = (openItems.map(\.sortOrder).max() ?? -1) + 1
        withAnimation {
            modelContext.insert(TodoItem(title: trimmed, scope: scope, sortOrder: nextOrder))
        }
        draftTitle = ""
        // Re-assert focus after the submit resigns it, so Return adds and
        // keeps going — rapid multi-add without reaching for the screen.
        DispatchQueue.main.async {
            addFieldFocused = true
        }
    }

    private func otherScopes(for item: TodoItem) -> [TaskScope] {
        TaskScope.allCases.filter { $0 != item.scope }
    }

    private func moveOpen(from source: IndexSet, to destination: Int) {
        var reordered = openItems
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, item) in reordered.enumerated() {
            item.sortOrder = index
        }
    }

    private func deleteOpen(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(openItems[index])
        }
    }

    private func deleteCompleted(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(completedThisScope[index])
        }
    }
}
