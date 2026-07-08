import AppKit

struct PasteboardWriter {
    private let write: (String) -> Bool

    init(pasteboard: NSPasteboard = .general) {
        write = { string in
            pasteboard.clearContents()
            return pasteboard.setString(string, forType: .string)
        }
    }

    init(writeString: @escaping (String) -> Bool) {
        write = writeString
    }

    @discardableResult
    func writeString(_ string: String) -> Bool {
        write(string)
    }
}
