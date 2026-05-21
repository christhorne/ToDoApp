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

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(items[index])
        }
    }
}
