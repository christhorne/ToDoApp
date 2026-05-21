import SwiftUI
import CloudKit

/// Scaffold wrapper around `UICloudSharingController`. Presents the system
/// share-invite UI; actual sharing only works once CloudKit is configured
/// and `AppConfig.useCloudKit` is `true`. See README for setup.
struct ShareSheetView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UICloudSharingController

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let placeholder = CKRecord(recordType: "ToDoAppShare")
        let share = CKShare(rootRecord: placeholder)
        share[CKShare.SystemFieldKey.title] = "ToDoApp" as CKRecordValue
        let controller = UICloudSharingController(share: share, container: CKContainer.default())
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) { }
}
