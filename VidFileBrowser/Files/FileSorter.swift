import Foundation

enum FileSorter {
    static func sorted(_ items: [FileItem], by property: SortProperty, ascending: Bool) -> [FileItem] {
        let folders = items
            .filter(\.isDirectory)
            .sorted { isOrdered($0, $1, by: property, ascending: ascending) }
        let files = items
            .filter { !$0.isDirectory }
            .sorted { isOrdered($0, $1, by: property, ascending: ascending) }
        return folders + files
    }

    private static func isOrdered(_ lhs: FileItem, _ rhs: FileItem, by property: SortProperty, ascending: Bool) -> Bool {
        switch compare(lhs, rhs, by: property) {
        case .orderedSame:
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        case .orderedAscending:
            return ascending
        case .orderedDescending:
            return !ascending
        }
    }

    private static func compare(_ lhs: FileItem, _ rhs: FileItem, by property: SortProperty) -> ComparisonResult {
        switch property {
        case .name:
            return lhs.name.localizedStandardCompare(rhs.name)
        case .date:
            return compareValues(lhs.modificationDate ?? .distantPast, rhs.modificationDate ?? .distantPast)
        case .tag:
            return compareTagCombinations(lhs, rhs)
        case .size:
            return compareValues(lhs.size ?? 0, rhs.size ?? 0)
        }
    }

    /// Compares the complete set of tag names, so files with several tags are
    /// ordered by the combination and not only by their first tag.
    private static func compareTagCombinations(_ lhs: FileItem, _ rhs: FileItem) -> ComparisonResult {
        let left = lhs.sortedTagNames
        let right = rhs.sortedTagNames

        for (leftName, rightName) in zip(left, right) {
            let result = leftName.localizedStandardCompare(rightName)
            if result != .orderedSame {
                return result
            }
        }
        return compareValues(left.count, right.count)
    }

    private static func compareValues<T: Comparable>(_ lhs: T, _ rhs: T) -> ComparisonResult {
        if lhs == rhs {
            return .orderedSame
        }
        return lhs < rhs ? .orderedAscending : .orderedDescending
    }
}
