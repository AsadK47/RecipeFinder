import SwiftUI
import UniformTypeIdentifiers

/// Thin `FileDocument` wrapper so SwiftUI's `fileExporter` can write, and
/// `fileImporter` can read, a backup as a single `.recipefinderbackup` file.
/// The bytes are produced/consumed by `BackupCodec`; this type only moves them
/// in and out of the document browser.
struct BackupDocument: FileDocument {
    /// The backup's content type, derived from `BackupCodec.fileExtension`. Falls
    /// back to JSON if the system can't resolve the custom extension.
    static let backupType = UTType(filenameExtension: BackupCodec.fileExtension) ?? .json

    static var readableContentTypes: [UTType] { [backupType, .json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let contents = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        data = contents
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
