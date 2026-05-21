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
    @State private var showCompleted = false
    @State private var dayExpansion: [Date: Bool] = [:]

    private let rowInsets = EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)
    private let dayHeaderInsets = EdgeInsets(top: 16, leading: 16, bottom: 6, trailing: 16)

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

    /// Days the week/weekend view actually renders. The Weekend tab always
    /// shows both Saturday and Sunday. The Week tab shows today and future
    /// always, and past days only when they still hold open (leftover) tasks.
    private var visibleDays: [Date] {
        if scope == .weekend {
            return dayGroups
        }
        let today = CalendarHelper.today
        return dayGroups.filter { day in
            if day < today {
                return !openItems(on: day).isEmpty
            }
            return true
        }
    }

    private var overdueItems: [TodoItem] {
        let today = CalendarHelper.today
        return allItems.filter { $0.completedAt == nil && $0.day < today }
    }

    private var completedItems: [TodoItem] {
        allItems
            .filter { item in
                guard let completedAt = item.completedAt else { return false }
                return scope.includesCompletion(at: completedAt)
            }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    private var navigationTitleText: String {
        switch scope {
        case .daily: CalendarHelper.longDateWithOrdinal(CalendarHelper.today)
        case .weekly: "This Week"
        case .weekend: "This Weekend"
        }
    }

    /// True when some visible day holds enough open tasks to reorder.
    private var canReorder: Bool {
        let days = scope == .daily ? [CalendarHelper.today] : visibleDays
        return days.contains { openItems(on: $0).count >= 2 }
    }

    var body: some View {
        NavigationStack {
            List {
                if scope == .daily {
                    todayContent
                } else {
                    weekContent
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
                    if canReorder || isEditing {
                        EditButton()
                    }
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

    // MARK: - Today

    @ViewBuilder
    private var todayContent: some View {
        if !overdueItems.isEmpty {
            Section {
                ForEach(overdueItems) { item in
                    taskRow(item)
                }
                .onDelete { deleteItems(overdueItems, at: $0) }
            } header: {
                plainHeader("Earlier")
            }
        }

        Section {
            dayRows(CalendarHelper.today)
        }

        if !completedItems.isEmpty {
            completedSection
        }
    }

    // MARK: - Week / Weekend

    @ViewBuilder
    private var weekContent: some View {
        ForEach(Array(visibleDays.enumerated()), id: \.element) { index, day in
            dayHeaderRow(day)
                .listRowInsets(dayHeaderInsets)
                .listRowSeparator(index == 0 ? .hidden : .automatic, edges: .top)
            if isDayExpanded(day) {
                dayRows(day)
            }
        }

        if !completedItems.isEmpty {
            completedSection
        }
    }

    @ViewBuilder
    private func dayRows(_ day: Date) -> some View {
        let open = openItems(on: day)
        ForEach(Array(open.enumerated()), id: \.element.id) { index, item in
            taskRow(item)
                .listRowSeparator(scope == .daily && index == 0 ? .hidden : .automatic, edges: .top)
        }
        .onDelete { deleteItems(open, at: $0) }
        .onMove { moveItems(on: day, from: $0, to: $1) }

        if !isEditing {
            addRow(for: day)
                .listRowSeparator(scope == .daily && open.isEmpty ? .hidden : .automatic, edges: .top)
        }
    }

    private var completedSection: some View {
        Section {
            Button {
                withAnimation { showCompleted.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.square.fill")
                        .foregroundStyle(scope.color)
                    Text(scope.completedSectionLabel)
                        .fontWeight(.medium)
                    Spacer()
                    countBadge(completedItems.count)
                    chevron(expanded: showCompleted)
                }
                .font(.subheadline)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .listRowInsets(rowInsets)

            if showCompleted {
                ForEach(completedItems) { item in
                    taskRow(item)
                }
                .onDelete { deleteItems(completedItems, at: $0) }
            }
        }
    }

    // MARK: - Rows

    private func dayHeaderRow(_ day: Date) -> some View {
        let isToday = Calendar.current.isDateInToday(day)
        let openCount = openItems(on: day).count
        return Button {
            withAnimation { toggleDay(day) }
        } label: {
            HStack(spacing: 8) {
                if isToday {
                    Text(CalendarHelper.longDateWithOrdinal(day))
                        .fontWeight(.semibold)
                        .foregroundStyle(scope.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(scope.color.opacity(0.15), in: Capsule())
                } else {
                    Text(Self.dayHeaderFormatter.string(from: day))
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                Spacer()
                if openCount > 0 {
                    countBadge(openCount)
                }
                chevron(expanded: isDayExpanded(day))
            }
            .font(.subheadline)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func chevron(expanded: Bool) -> some View {
        Image(systemName: "chevron.right")
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.tertiary)
            .rotationEffect(.degrees(expanded ? 90 : 0))
    }

    private func countBadge(_ count: Int) -> some View {
        Text("\(count)")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(.quaternary, in: Capsule())
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

    private func plainHeader(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(nil)
    }

    // MARK: - Expansion

    private func isDayExpanded(_ day: Date) -> Bool {
        dayExpansion[day] ?? defaultExpanded(day)
    }

    /// Today expands; past days stay collapsed (leftovers — expand to handle);
    /// future days expand only if they hold tasks, except the focused Weekend
    /// tab which keeps its two days open for planning.
    private func defaultExpanded(_ day: Date) -> Bool {
        if Calendar.current.isDateInToday(day) { return true }
        if day < CalendarHelper.today { return false }
        if scope == .weekend { return true }
        return !openItems(on: day).isEmpty
    }

    private func toggleDay(_ day: Date) {
        dayExpansion[day] = !isDayExpanded(day)
    }

    // MARK: - Data

    private func openItems(on day: Date) -> [TodoItem] {
        let calendar = Calendar.current
        return allItems.filter {
            $0.completedAt == nil && calendar.isDate($0.day, inSameDayAs: day)
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
