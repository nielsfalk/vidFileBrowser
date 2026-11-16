import Foundation

/// Reads Finder tags from the extended attribute where Finder stores them.
///
/// `URLResourceValues.tagNames` strips the color suffix on newer macOS versions,
/// so the raw `com.apple.metadata:_kMDItemUserTags` attribute is the source of
/// truth. It holds a binary plist with entries such as `"Red\n6"`.
enum FinderTags {
    static let attributeName = "com.apple.metadata:_kMDItemUserTags"

    static func tags(for url: URL) -> [FileTag]? {
        guard let data = readAttribute(named: attributeName, at: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let rawValues = plist as? [String]
        else {
            return nil
        }
        return rawValues.map(FileTag.init(rawValue:))
    }

    private static func readAttribute(named name: String, at url: URL) -> Data? {
        let path = url.path
        let length = getxattr(path, name, nil, 0, 0, 0)
        guard length > 0 else { return nil }

        var data = Data(count: length)
        let result = data.withUnsafeMutableBytes { buffer in
            getxattr(path, name, buffer.baseAddress, length, 0, 0)
        }
        guard result == length else { return nil }
        return data
    }
}
