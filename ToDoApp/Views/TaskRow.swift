import SwiftUI
import SwiftData

struct TaskRow: View {
    @Bindable var item: TodoItem
    @Binding var activeActionItem: TodoItem?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @State private var expanded = false
    @State private var showingTimePicker = false
    @State private var timeDraft: Date = .now
    @State private var showingMapSheet = false
    @State private var showingListSheet = false
    @State private var mapLabelDraft = ""
    @State private var mapAddressDraft = ""
    @State private var listItemsDraft: [ChecklistItem] = []

    // Long-press action bar sub-dialogs
    @State private var showingRepeatDialog = false
    @State private var showingAssignDialog = false
    @State private var showingAttachDialog = false

    private var showingActions: Bool {
        activeActionItem === item
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        f.dateTimeStyle = .numeric
        return f
    }()

    private static let timeFormatStyle = Date.FormatStyle.dateTime.hour().minute()

    var body: some View {
        rowContent
            .contentShape(Rectangle())
            .highPriorityGesture(longPressToReveal)
            .popover(
                isPresented: Binding(
                    get: { activeActionItem === item },
                    set: { isPresented in
                        if !isPresented, activeActionItem === item {
                            activeActionItem = nil
                        }
                    }
                ),
                attachmentAnchor: .point(UnitPoint(x: 0.85, y: 1)),
                arrowEdge: .top
            ) {
                actionBar
                    .presentationCompactAdaptation(.popover)
            }
        .sheet(isPresented: $showingTimePicker) {
            timePickerSheet
        }
        .sheet(isPresented: $showingMapSheet) {
            mapSheet
        }
        .sheet(isPresented: $showingListSheet) {
            listSheet
        }
        .confirmationDialog("Repeat", isPresented: $showingRepeatDialog, titleVisibility: .visible) {
            Button("Daily") { setRecurrence(kind: .daily, intervalDays: 1) }
            Button("Weekly") { setRecurrence(kind: .weekly, intervalDays: 7) }
            Button("Every 3 days") { setRecurrence(kind: .everyN, intervalDays: 3) }
            if item.recurrenceRuleId != nil {
                Button("Don't repeat", role: .destructive) { clearRecurrence() }
            }
        }
        .confirmationDialog("Assign", isPresented: $showingAssignDialog, titleVisibility: .visible) {
            ForEach(Assignee.all) { assignee in
                Button("Assign to \(assignee.displayName)") { item.assigneeId = assignee.id }
            }
            if item.assigneeId != nil {
                Button("Unassign", role: .destructive) { item.assigneeId = nil }
            }
        }
        .confirmationDialog("Attach", isPresented: $showingAttachDialog, titleVisibility: .visible) {
            if hasMap {
                Button("Edit map…") { openMapSheet() }
                Button("Remove map", role: .destructive) { item.attachment = nil }
            } else if hasList {
                Button("Edit list…") { openListSheet() }
                Button("Remove list", role: .destructive) { item.attachment = nil }
            } else {
                Button("Attach map…") { openMapSheet() }
                Button("Attach list…") { openListSheet() }
            }
        }
    }

    // MARK: - Row content

    private var rowContent: some View {
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

                if item.recurrenceRuleId != nil {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Repeats")
                }

                VStack(alignment: .leading, spacing: 1) {
                    titleView
                    if let completedAt = item.completedAt {
                        Text("Done \(Self.relativeFormatter.localizedString(for: completedAt, relativeTo: .now))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)

                assigneeChip

                attachmentBadge
            }

            if case .list(let items) = item.attachment, expanded {
                checklist(items: items)
            }
        }
    }

    // MARK: - Long-press action bar

    private var longPressToReveal: some Gesture {
        LongPressGesture(minimumDuration: 0.35).onEnded { _ in
            guard !showingActions else { return }
            UISelectionFeedbackGenerator().selectionChanged()
            activeActionItem = item
        }
    }

    private func dismissActions(then: (() -> Void)? = nil) {
        if activeActionItem === item {
            activeActionItem = nil
        }
        if let then {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.24, execute: then)
        }
    }

    private var actionBar: some View {
        VStack(alignment: .leading, spacing: 0) {
            actionButton(title: "Time", systemImage: "clock", tint: .orange) {
                dismissActions {
                    timeDraft = item.time ?? defaultTimeDraft()
                    showingTimePicker = true
                }
            }
            divider
            actionButton(title: "Repeat", systemImage: "arrow.triangle.2.circlepath", tint: .blue) {
                dismissActions { showingRepeatDialog = true }
            }
            divider
            actionButton(title: "Assign", systemImage: "person.crop.circle", tint: .purple) {
                dismissActions { showingAssignDialog = true }
            }
            divider
            actionButton(title: "Attach", systemImage: "paperclip", tint: .green) {
                dismissActions { showingAttachDialog = true }
            }
        }
        .frame(width: 140, alignment: .leading)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.06))
            .frame(height: 0.5)
            .padding(.leading, 52)
    }

    private func actionButton(
        title: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 24, height: 24)
                Text(title)
                    .font(.callout)
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var hasMap: Bool {
        if case .map = item.attachment { return true }
        return false
    }

    private var hasList: Bool {
        if case .list = item.attachment { return true }
        return false
    }

    @ViewBuilder
    private var assigneeChip: some View {
        if let assignee = Assignee.find(id: item.assigneeId) {
            Text(assignee.initial)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(assignee.color, in: Circle())
                .accessibilityLabel("Assigned to \(assignee.displayName)")
        }
        // Unassigned: nothing on the row. Assign via long-press menu only.
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
                withAnimation(.smooth(duration: 0.28)) { expanded.toggle() }
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

    // MARK: - Title rendering

    @ViewBuilder
    private var titleView: some View {
        if item.isComplete {
            timedTitle(strikethrough: true)
                .foregroundStyle(.secondary)
        } else if item.time != nil {
            HStack(spacing: 6) {
                Text(item.time!, format: Self.timeFormatStyle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("·")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Task", text: $item.title)
                    .onSubmit(handleTitleSubmit)
            }
        } else {
            TextField("Task", text: $item.title)
                .onSubmit(handleTitleSubmit)
        }
    }

    @ViewBuilder
    private func timedTitle(strikethrough: Bool) -> some View {
        if let time = item.time {
            HStack(spacing: 6) {
                Text(time, format: Self.timeFormatStyle)
                    .font(.caption.weight(.semibold))
                    .strikethrough(strikethrough)
                Text("·")
                    .font(.caption)
                    .strikethrough(strikethrough)
                Text(item.title)
                    .strikethrough(strikethrough)
            }
        } else {
            Text(item.title)
                .strikethrough(strikethrough)
        }
    }

    // MARK: - Time picker sheet

    private var timePickerSheet: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Time",
                    selection: $timeDraft,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()
                Spacer()
            }
            .navigationTitle("Set Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingTimePicker = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        item.time = timeDraft
                        showingTimePicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func defaultTimeDraft() -> Date {
        let calendar = Calendar.current
        let now = Date.now
        let minute = calendar.component(.minute, from: now)
        let bumpedMinute = ((minute / 15) + 1) * 15
        return calendar.date(
            bySettingHour: calendar.component(.hour, from: now),
            minute: bumpedMinute % 60,
            second: 0,
            of: bumpedMinute >= 60 ? now.addingTimeInterval(3600) : now
        ) ?? now
    }

    // MARK: - Inline checklist

    private func checklist(items: [ChecklistItem]) -> some View {
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
        .transition(.opacity)
    }

    // MARK: - Actions

    private func toggleComplete() {
        withAnimation {
            if !item.isComplete {
                if let ruleId = item.recurrenceRuleId,
                   let rule = fetchRule(id: ruleId) {
                    let nextDay = rule.nextDate(after: item.day)
                    let next = TodoItem(
                        title: item.title,
                        day: nextDay,
                        sortOrder: item.sortOrder,
                        assigneeId: item.assigneeId,
                        time: item.time,
                        recurrenceRuleId: item.recurrenceRuleId,
                        recurrenceParentId: item.recurrenceParentId
                    )
                    modelContext.insert(next)
                }
            }
            item.completedAt = item.isComplete ? nil : .now
        }
    }

    private func handleTitleSubmit() {
        if item.title.trimmingCharacters(in: .whitespaces).isEmpty {
            modelContext.delete(item)
        }
    }

    private func setRecurrence(kind: RecurrenceKind, intervalDays: Int) {
        let rule: RecurrenceRule
        if let existingId = item.recurrenceRuleId, let existing = fetchRule(id: existingId) {
            existing.kindRaw = kind.rawValue
            existing.intervalDays = intervalDays
            rule = existing
        } else {
            let newRule = RecurrenceRule(kind: kind, intervalDays: intervalDays)
            modelContext.insert(newRule)
            rule = newRule
        }
        item.recurrenceRuleId = rule.id
        if item.recurrenceParentId == nil {
            item.recurrenceParentId = UUID()
        }
    }

    private func clearRecurrence() {
        item.recurrenceRuleId = nil
        item.recurrenceParentId = nil
    }

    private func fetchRule(id: UUID) -> RecurrenceRule? {
        let descriptor = FetchDescriptor<RecurrenceRule>(predicate: #Predicate { $0.id == id })
        return try? modelContext.fetch(descriptor).first
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

    // MARK: - Attachment sheets

    private var mapSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Label (e.g. Arthur's School)", text: $mapLabelDraft)
                    TextField("Address", text: $mapAddressDraft, axis: .vertical)
                        .lineLimit(2...4)
                } footer: {
                    Text("Tapping the pin on this task will open the address in Apple Maps.")
                }
            }
            .navigationTitle(hasMap ? "Edit Map" : "Attach Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingMapSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { saveMap() }
                        .disabled(mapAddressDraft.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var listSheet: some View {
        NavigationStack {
            List {
                Section {
                    ForEach($listItemsDraft) { $entry in
                        HStack(spacing: 10) {
                            TextField("Item", text: $entry.text)
                            Button {
                                listItemsDraft.removeAll { $0.id == entry.id }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Remove item")
                        }
                    }
                    Button {
                        listItemsDraft.append(ChecklistItem(text: ""))
                    } label: {
                        Label("Add item", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle(hasList ? "Edit Checklist" : "Attach Checklist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingListSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { saveList() }
                        .disabled(listItemsDraft.allSatisfy {
                            $0.text.trimmingCharacters(in: .whitespaces).isEmpty
                        })
                }
            }
        }
    }

    private func openMapSheet() {
        if case .map(let label, let address) = item.attachment {
            mapLabelDraft = label
            mapAddressDraft = address
        } else {
            mapLabelDraft = ""
            mapAddressDraft = ""
        }
        showingMapSheet = true
    }

    private func openListSheet() {
        if case .list(let items) = item.attachment {
            listItemsDraft = items
        } else {
            listItemsDraft = [ChecklistItem(text: "")]
        }
        showingListSheet = true
    }

    private func saveMap() {
        let address = mapAddressDraft.trimmingCharacters(in: .whitespaces)
        let label = mapLabelDraft.trimmingCharacters(in: .whitespaces)
        item.attachment = .map(label: label.isEmpty ? "Location" : label, address: address)
        showingMapSheet = false
    }

    private func saveList() {
        let filtered: [ChecklistItem] = listItemsDraft.compactMap { entry in
            let trimmed = entry.text.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return nil }
            return ChecklistItem(id: entry.id, text: trimmed, done: entry.done)
        }
        item.attachment = filtered.isEmpty ? nil : .list(items: filtered)
        showingListSheet = false
    }
}
