import Foundation

enum SharedAppGroup {
    static let identifier = "group.com.chris.ToDoApp"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    static var storeURL: URL? {
        containerURL?.appending(path: "ToDoApp.sqlite")
    }
}
