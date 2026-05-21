import SwiftUI
import SwiftData

struct PlannerView: View {
    let scope: TaskScope

    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode
    @Query(sort: [SortDescriptor(\TodoItem.sortOrder), SortDescriptor(\TodoItem.createdAt)])
    private var allItems: [TodoItem]

    @State private var showingSettings = false
    @State private var reschedulingItem: TodoItem?
    @State private var drafts: [Date: String] = [:]
    @FocusState private var focusedAddDay: Date?

    private let rowInsets = EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)

    private static let titleFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f
    }()

    private static let dayHeaderFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE d"
        return f
    }()

    private var isEditing: Bool {
        editMode?.wrappedValue.isEditing ?? false
    }

    private var dayGroups: [Date] {
        switch scope {
        case .daily: [CalendarHelper.today]
        case .weekly: CalendarHelper.daysOfCurrentWeek()
        case .weekend: CalendarHelper.weekendDays()
        }
    }

    private var overdueItems: [TodoItem] {
        let today = CalendarHelper.today
        return allItems.filter { $0.completedAt == nil && $0.day < today }
    }

    private var navigationTitleText: String {
        switch scope {
        case .daily: Self.titleFormatter.string(from: .now)
        case .weekly: "This Week"
        case .weekend: "This Weekend"
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if scope == .daily && !overdueItems.isEmpty {
                    Section {
                        ForEach(overdueItems) { item in
                            taskRow(item)
                        }
                        .onDelete { deleteItems(overdueItems, at: $0) }
                    } header: {
                        sectionHeader("Earlier", highlighted: false)
                    }
                }

                ForEach(dayGroups, id: \.self) { day in
                    if scope == .daily {
                        Section { dayRows(day) }
                    } else {
                        Section {
                            dayRows(day)
                        } header: {
                            dayHeader(day)
                        }
                    }
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
            .sheet(item: $reschedulingItem) { item in
                RescheduleSheet(item: item)
            }
        }
        .tint(scope.color)
    }

    @ViewBuilder
    private func dayRows(_ day: Date) -> some View {
        let open = openItems(on: day)
        let completed = completedItems(on: day)

        ForEach(Array(open.enumerated()), id: \.element.id) { index, item in
            taskRow(item)
                .listRowSeparator(scope == .daily && index == 0 ? .hidden : .automatic, edges: .top)
        }
        .onDelete { deleteItems(open, at: $0) }
        .onMove { moveItems(on: day, from: $0, to: $1) }

        ForEach(completed) { item in
            taskRow(item)
        }
        .onDelete { deleteItems(completed, at: $0) }

        if !isEditing {
            addRow(for: day)
                .listRowSeparator(
                    scope == .daily && open.isEmpty && completed.isEmpty ? .hidden : .automatic,
                    edges: .top
                )
        }
    }

    private func taskRow(_ item: TodoItem) -> some View {
        TaskRow(item: item)
            .listRowInsets(rowInsets)
            .swipeActions(edge: .leading) {
                Button {
                    reschedulingItem = item
                } label: {
                    Label("Move", systemImage: "calendar")
                }
                .tint(scope.color)
            }
    }

    private func addRow(for day: Date) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundStyle(scope.color)
            TextField("Add a task", text: draftBinding(for: day))
                .focused($focusedAddDay, equals: day)
                .submitLabel(.return)
                .onSubmit { commitDraft(for: day) }
            Spacer(minLength: 0)
        }
        .listRowInsets(rowInsets)
        .contentShape(Rectangle())
        .onTapGesture { focusedAddDay = day }
    }

    private func dayHeader(_ day: Date) -> some View {
        let isToday = Calendar.current.isDateInToday(day)
        let text = isToday ? "Today" : Self.dayHeaderFormatter.string(from: day)
        return sectionHeader(text, highlighted: isToday)
    }

    private func sectionHeader(_ text: String, highlighted: Bool) -> some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(highlighted ? AnyShapeStyle(scope.color) : AnyShapeStyle(.secondary))
            .textCase(nil)
    }

    // MARK: - Data

    private func openItems(on day: Date) -> [TodoItem] {
        let calendar = Calendar.current
        return allItems.filter {
            $0.completedAt == nil && calendar.isDate($0.day, inSameDayAs: day)
        }
    }

    private func completedItems(on day: Date) -> [TodoItem] {
        let calendar = Calendar.current
        return allItems.filter {
            $0.completedAt != nil && calendar.isDate($0.day, inSameDayAs: day)
        }
    }

    private func draftBinding(for day: Date) -> Binding<String> {
        Binding(
            get: { drafts[day] ?? "" },
            set: { drafts[day] = $0 }
        )
    }

    private func commitDraft(for day: Date) {
        let text = (drafts[day] ?? "").trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else {
            focusedAddDay = nil
            return
        }
        let nextOrder = (openItems(on: day).map(\.sortOrder).max() ?? -1) + 1
        withAnimation {
            modelContext.insert(TodoItem(title: text, day: day, sortOrder: nextOrder))
        }
        drafts[day] = ""
        // Re-assert focus after submit resigns it — Return adds and keeps going.
        DispatchQueue.main.async { focusedAddDay = day }
    }

    private func moveItems(on day: Date, from source: IndexSet, to destination: Int) {
        var items = openItems(on: day)
        items.move(fromOffsets: source, toOffset: destination)
        for (index, item) in items.enumerated() {
            item.sortOrder = index
        }
    }

    private func deleteItems(_ items: [TodoItem], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(items[index])
        }
    }
}
