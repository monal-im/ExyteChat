import Foundation

extension String {
    func sanitizedFilename() -> String {
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*%?\"<>|")
            .union(.newlines)
            .union(.illegalCharacters)
            .union(.controlCharacters)
        var sanitized = self.components(separatedBy: invalidCharacters).joined(separator: "_")

        if sanitized.isEmpty || sanitized == "." || sanitized == ".." {
            return "file"
        }

        if sanitized.unicodeScalars.count >= 255 {
            sanitized = String(sanitized.prefix(63))
        }

        return sanitized
    }
}
