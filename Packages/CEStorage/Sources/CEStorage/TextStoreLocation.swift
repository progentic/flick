import Foundation

public enum TextStoreLocation {
    public static let groupIdentifier = "group.com.progentic.flick"

    public static func applicationURL() throws -> URL {
        guard let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier)
        else { throw TextStoreError.groupContainerUnavailable }
        let directory = group.appending(path: "Library/Application Support/Flick", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: "TextV1.store")
    }
}
