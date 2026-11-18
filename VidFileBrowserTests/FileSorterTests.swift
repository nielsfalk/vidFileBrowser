import XCTest
@testable import VidFileBrowser

final class FileSorterTests: XCTestCase {
    func testFoldersComeFirst() {
        let items = [
            item("b.txt"),
            item("Folder", isDirectory: true),
            item("a.mov")
        ]

        let sorted = FileSorter.sorted(items, by: .name, ascending: true)

        XCTAssertEqual(sorted.map(\.name), ["Folder", "a.mov", "b.txt"])
    }

    func testNameSortUsesNaturalOrder() {
        let items = [item("file10"), item("file2"), item("file1")]

        let sorted = FileSorter.sorted(items, by: .name, ascending: true)

        XCTAssertEqual(sorted.map(\.name), ["file1", "file2", "file10"])
    }

    func testNameSortDescending() {
        let items = [item("a"), item("c"), item("b")]

        let sorted = FileSorter.sorted(items, by: .name, ascending: false)

        XCTAssertEqual(sorted.map(\.name), ["c", "b", "a"])
    }

    func testDateSortDescendingPutsNewestFirst() {
        let old = Date(timeIntervalSince1970: 100)
        let new = Date(timeIntervalSince1970: 200)
        let items = [item("old", date: old), item("new", date: new), item("none", date: nil)]

        let sorted = FileSorter.sorted(items, by: .date, ascending: false)

        XCTAssertEqual(sorted.map(\.name), ["new", "old", "none"])
    }

    func testSizeSort() {
        let items = [item("big", size: 500), item("small", size: 5), item("folder", isDirectory: true)]

        let sorted = FileSorter.sorted(items, by: .size, ascending: true)

        XCTAssertEqual(sorted.map(\.name), ["folder", "small", "big"])
    }

    func testTagSort() {
        let items = [item("none", tagColor: 0), item("red", tagColor: 6), item("gray", tagColor: 1)]

        let sorted = FileSorter.sorted(items, by: .tag, ascending: true)

        XCTAssertEqual(sorted.map(\.name), ["none", "gray", "red"])
    }

    func testEqualValuesFallBackToName() {
        let date = Date(timeIntervalSince1970: 1)
        let items = [item("b", date: date), item("a", date: date)]

        let sorted = FileSorter.sorted(items, by: .date, ascending: false)

        XCTAssertEqual(sorted.map(\.name), ["a", "b"])
    }

    private func item(
        _ name: String,
        isDirectory: Bool = false,
        date: Date? = nil,
        size: Int64? = nil,
        tagColor: Int = 0
    ) -> FileItem {
        let tags = tagColor == 0 ? [] : [FileTag(name: "Tag", color: TagColor(rawValue: tagColor))]
        return FileItem(
            url: URL(fileURLWithPath: "/tmp/\(name)"),
            name: name,
            isDirectory: isDirectory,
            size: size,
            modificationDate: date,
            tags: tags,
            kind: isDirectory ? .other : .video
        )
    }
}
