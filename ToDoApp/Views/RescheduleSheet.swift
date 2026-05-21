import SwiftUI

struct RescheduleSheet: View {
    @Bindable var item: TodoItem
    @Environment(\.dismiss) private var dismiss
    @State private var picked: Date = .now

    var body: some View {
        NavigationStack {
            DatePicker(
                "Day",
                selection: $picked,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .padding(.horizontal)
            .navigationTitle("Move task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Move") {
                        item.day = Calendar.current.startOfDay(for: picked)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear { picked = item.day }
    }
}
