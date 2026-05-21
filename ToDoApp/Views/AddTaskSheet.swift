import SwiftUI
import SwiftData

struct AddTaskSheet: View {
    let defaultScope: TaskScope

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var notes = ""
    @State private var scope: TaskScope
    @FocusState private var titleFocused: Bool

    init(defaultScope: TaskScope) {
        self.defaultScope = defaultScope
        _scope = State(initialValue: defaultScope)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What needs doing?", text: $title)
                        .focused($titleFocused)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                }
                Section("List") {
                    Picker("Scope", selection: $scope) {
                        ForEach(TaskScope.allCases) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: add)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { titleFocused = true }
        }
    }

    private func add() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let item = TodoItem(
            title: trimmed,
            notes: notes.isEmpty ? nil : notes,
            scope: scope
        )
        modelContext.insert(item)
        dismiss()
    }
}
