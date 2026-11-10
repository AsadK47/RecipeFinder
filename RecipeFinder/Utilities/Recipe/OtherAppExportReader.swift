import Compression
import Foundation

/// Why an export file couldn't be read; shown to the user as-is.
enum OtherAppExportError: LocalizedError, Equatable {
    case unsupportedFile
    case damaged

    var errorDescription: String? {
        switch self {
        case .unsupportedFile: "This isn't a Paprika, Mela or CSV export."
        case .damaged: "This export looks damaged. Try exporting it again."
        }
    }
}

/// Reads another app's export file into recipes: Paprika (`.paprikarecipes` zip of gzipped JSON, or one
/// `.paprikarecipe`), Mela (`.melarecipes` zip of JSON, or one `.melarecipe`) and CSV.
enum OtherAppExportReader {
    enum Format: String, Equatable, Sendable {
        case paprika = "Paprika", mela = "Mela", csv = "CSV"
    }

    struct Contents: Equatable, Sendable {
        let format: Format
        var recipes: [OtherAppRecipe]
        /// Entries in the export that weren't readable recipes — reported, never silently dropped.
        var unreadable: Int
    }

    static func format(forFileName name: String) -> Format? {
        switch (name as NSString).pathExtension.lowercased() {
        case "paprikarecipes", "paprikarecipe": .paprika
        case "melarecipes", "melarecipe": .mela
        case "csv": .csv
        default: nil
        }
    }

    static func read(_ data: Data, fileName: String) throws -> Contents {
        guard let format = format(forFileName: fileName) else { throw OtherAppExportError.unsupportedFile }
        let isBundle = (fileName as NSString).pathExtension.lowercased().hasSuffix("s")
        switch format {
        case .csv:
            guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
                throw OtherAppExportError.damaged
            }
            return Contents(format: .csv, recipes: CSVRecipeParser.parse(csv: text), unreadable: 0)
        case .paprika:
            let files = isBundle ? try ZipArchive.entries(in: data).map(\.data) : [data]
            return collect(files, format: .paprika) { file in
                (try? Gzip.decompress(file)).flatMap(PaprikaRecipeParser.parse(json:))
            }
        case .mela:
            let files = isBundle ? try ZipArchive.entries(in: data).map(\.data) : [data]
            return collect(files, format: .mela, parse: MelaRecipeParser.parse(json:))
        }
    }

    private static func collect(_ files: [Data], format: Format, parse: (Data) -> OtherAppRecipe?) -> Contents {
        var contents = Contents(format: format, recipes: [], unreadable: 0)
        for file in files {
            if let recipe = parse(file) {
                contents.recipes.append(recipe)
            } else {
                contents.unreadable += 1
            }
        }
        return contents
    }
}

/// Minimal ZIP reader (stored and deflate entries, via the central directory) — enough for app exports, so no
/// third-party archive dependency.
enum ZipArchive {
    struct Entry: Equatable {
        let name: String
        let data: Data
    }

    static func entries(in data: Data) throws -> [Entry] {
        let bytes = [UInt8](data)
        guard let end = endOfCentralDirectory(in: bytes) else { throw OtherAppExportError.damaged }
        let count = Int(try bytes.uint16(at: end + 10))
        var offset = Int(try bytes.uint32(at: end + 16))
        var entries: [Entry] = []
        for _ in 0..<count {
            guard try bytes.uint32(at: offset) == 0x0201_4b50 else { throw OtherAppExportError.damaged }
            let method = try bytes.uint16(at: offset + 10)
            let compressedSize = Int(try bytes.uint32(at: offset + 20))
            let size = Int(try bytes.uint32(at: offset + 24))
            let nameLength = Int(try bytes.uint16(at: offset + 28))
            let extraLength = Int(try bytes.uint16(at: offset + 30))
            let commentLength = Int(try bytes.uint16(at: offset + 32))
            let localOffset = Int(try bytes.uint32(at: offset + 42))
            let name = String(decoding: try bytes.slice(offset + 46, nameLength), as: UTF8.self)
            offset += 46 + nameLength + extraLength + commentLength

            // Folders and macOS resource forks aren't recipes.
            guard !name.hasSuffix("/"), !name.hasPrefix("__MACOSX/") else { continue }
            guard try bytes.uint32(at: localOffset) == 0x0403_4b50 else { throw OtherAppExportError.damaged }
            let start = localOffset + 30 + Int(try bytes.uint16(at: localOffset + 26))
                + Int(try bytes.uint16(at: localOffset + 28))
            let stored = Data(try bytes.slice(start, compressedSize))
            switch method {
            case 0: entries.append(Entry(name: name, data: stored))
            case 8: entries.append(Entry(name: name, data: try Inflate.raw(stored, size: size)))
            default: throw OtherAppExportError.damaged
            }
        }
        return entries
    }

    private static func endOfCentralDirectory(in bytes: [UInt8]) -> Int? {
        guard bytes.count >= 22 else { return nil }
        // The record is the last 22 bytes plus an optional comment of up to 64 KB.
        let lowest = max(0, bytes.count - 22 - 65_535)
        return stride(from: bytes.count - 22, through: lowest, by: -1).first { index in
            (try? bytes.uint32(at: index)) == 0x0605_4b50
        }
    }
}

/// gzip (RFC 1952) — Paprika gzips each recipe's JSON.
enum Gzip {
    static func decompress(_ data: Data) throws -> Data {
        let bytes = [UInt8](data)
        guard bytes.count >= 18, bytes[0] == 0x1f, bytes[1] == 0x8b, bytes[2] == 8 else {
            throw OtherAppExportError.damaged
        }
        let flags = bytes[3]
        var offset = 10
        if flags & 0x04 != 0 { offset += 2 + Int(try bytes.uint16(at: offset)) }   // extra field
        if flags & 0x08 != 0 { offset = try bytes.afterZeroTerminator(from: offset) } // file name
        if flags & 0x10 != 0 { offset = try bytes.afterZeroTerminator(from: offset) } // comment
        if flags & 0x02 != 0 { offset += 2 }                                         // header CRC
        let size = Int(try bytes.uint32(at: bytes.count - 4))
        let body = Data(try bytes.slice(offset, bytes.count - 8 - offset))
        return try Inflate.raw(body, size: size)
    }
}

/// Raw DEFLATE via Apple's Compression framework (`COMPRESSION_ZLIB` is headerless DEFLATE).
enum Inflate {
    /// Exports are recipes, not media libraries: refuse to allocate more than this for one entry.
    static let maxSize = 50_000_000

    static func raw(_ data: Data, size: Int) throws -> Data {
        guard size > 0 else { return Data() }
        guard size <= maxSize, !data.isEmpty else { throw OtherAppExportError.damaged }
        var output = [UInt8](repeating: 0, count: size)
        let written = data.withUnsafeBytes { source -> Int in
            guard let base = source.bindMemory(to: UInt8.self).baseAddress else { return 0 }
            return compression_decode_buffer(&output, size, base, data.count, nil, COMPRESSION_ZLIB)
        }
        guard written == size else { throw OtherAppExportError.damaged }
        return Data(output)
    }
}

private extension [UInt8] {
    func slice(_ start: Int, _ length: Int) throws -> ArraySlice<UInt8> {
        guard start >= 0, length >= 0, start + length <= count else { throw OtherAppExportError.damaged }
        return self[start..<start + length]
    }

    func uint16(at index: Int) throws -> UInt16 {
        let b = try slice(index, 2)
        return UInt16(b[b.startIndex]) | UInt16(b[b.startIndex + 1]) << 8
    }

    func uint32(at index: Int) throws -> UInt32 {
        let b = try slice(index, 4)
        return (0..<4).reduce(0) { $0 | UInt32(b[b.startIndex + $1]) << (8 * $1) }
    }

    func afterZeroTerminator(from index: Int) throws -> Int {
        guard index < count, let zero = self[index...].firstIndex(of: 0) else { throw OtherAppExportError.damaged }
        return zero + 1
    }
}
