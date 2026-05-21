import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingShareSheet = false
    @State private var showingCloudKitAlert = false
    @State private var showingClearConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        if AppConfig.useCloudKit {
                            showingShareSheet = true
                        } else {
                            showingCloudKitAlert = true
                        }
                    } label: {
                        Label("Share this list", systemImage: "square.and.arrow.up")
                    }
                } header: {
                    Text("Sharing")
                } footer: {
                    if !AppConfig.useCloudKit {
                        Text("Syncing your lists across devices isn't available yet.")
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                }

                Section {
                    Button(role: .destructive) {
                        showingClearConfirmation = true
                    } label: {
                        Label("Clear All Tasks", systemImage: "trash")
                    }
                } footer: {
                    Text("Permanently deletes every task. This can't be undone.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheetView()
                    .ignoresSafeArea()
            }
            .alert("Sharing isn't available yet", isPresented: $showingCloudKitAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Syncing your lists across devices will be available in a future update.")
            }
            .confirmationDialog(
                "Delete all tasks?",
                isPresented: $showingClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All Tasks", role: .destructive) {
                    clearAllData()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently removes every task and can't be undone.")
            }
        }
        .tint(.blue)
    }

    private func clearAllData() {
        try? modelContext.delete(model: TodoItem.self)
        try? modelContext.save()
    }
}

#Preview {
    SettingsView()
}
