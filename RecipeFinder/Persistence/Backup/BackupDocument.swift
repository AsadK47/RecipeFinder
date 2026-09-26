import SwiftUI
import UniformTypeIdentifiers

/// `FileDocument` wrapper letting `fileExporter`/`fileImporter` move `BackupCodec` bytes as a `.recipefinderbackup` file.
struct BackupDocument: FileDocument {
    /// Content type from `BackupCodec.fileExtension`, falling back to JSON if the custom extension can't resolve.
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
