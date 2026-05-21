import SwiftUI
import SwiftData

struct TaskListView: View {
    let scope: TaskScope

    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\TodoItem.sortOrder), SortDescriptor(\TodoItem.createdAt)])
    private var allItems: [TodoItem]
    @State private var showingAddSheet = false
    @State private var showingSettings = false
    @State private var showCompletedSection = false

    private static let todayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f
    }()

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
            Group {
                if openItems.isEmpty && completedThisScope.isEmpty {
                    ContentUnavailableView(
                        "Nothing for \(scope.displayName.lowercased())",
                        systemImage: scope.systemImage,
                        description: Text("Tap + to add your first task.")
                    )
                } else {
                    List {
                        ForEach(openItems) { item in
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
                        .onDelete(perform: deleteOpen)

                        if !completedThisScope.isEmpty {
                            DisclosureGroup(isExpanded: $showCompletedSection) {
                                ForEach(completedThisScope) { item in
                                    TaskRow(item: item)
                                }
                                .onDelete(perform: deleteCompleted)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                    Text(scope.completedSectionLabel)
                                    Text("\(completedThisScope.count)")
                                        .foregroundStyle(.secondary)
                                }
                                .font(.subheadline)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(navigationTitleText)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                    .accessibilityLabel("Settings")
                }
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
            .sheet(isPresented: $showingSettings) {
                SettingsView()
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
