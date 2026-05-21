import SwiftUI
import SwiftData

struct TaskListView: View {
    let scope: TaskScope

    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\TodoItem.sortOrder), SortDescriptor(\TodoItem.createdAt)])
    private var allItems: [TodoItem]
    @State private var showingAddSheet = false

    private var items: [TodoItem] {
        allItems.filter { $0.scope == scope && $0.completedAt == nil }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "Nothing for \(scope.displayName.lowercased())",
                        systemImage: scope.systemImage,
                        description: Text("Tap + to add your first task.")
                    )
                } else {
                    List {
                        ForEach(items) { item in
                            TaskRow(item: item)
                                .swipeActions(edge: .leading) {
                                    ForEach(otherScopes(for: item)) { other in
                                        Button {
                                            withAnimation {
                                                item.scope = other
                                            }
                                        } label: {
                                            Label("Move to \(other.displayName)", systemImage: other.systemImage)
                                        }
                                        .tint(tint(for: other))
                                    }
                                }
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(scope.displayName)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add task")
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddTaskSheet(defaultScope: scope)
            }
        }
    }

    private func otherScopes(for item: TodoItem) -> [TaskScope] {
        TaskScope.allCases.filter { $0 != item.scope }
    }

    private func tint(for scope: TaskScope) -> Color {
        switch scope {
        case .daily: .orange
        case .weekly: .blue
        case .weekend: .green
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(items[index])
        }
    }
}
