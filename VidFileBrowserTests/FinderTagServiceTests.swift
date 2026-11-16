import XCTest
@testable import VidFileBrowser

final class FinderTagServiceTests: XCTestCase {
    private var directory: URL!
    private var file: URL!
    private let service = FinderTagService()

    override func setUpWithError() throws {
        try super.setUpWithError()
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FinderTagServiceTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        file = directory.appendingPathComponent("clip.mov")
        try Data().write(to: file)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        super.tearDown()
    }

    func testToggleAddsAndRemovesAColor() throws {
        try service.toggle(color: .red, on: file)
        XCTAssertEqual(service.tags(of: file), [FileTag(name: "Red", color: .red)])

        try service.toggle(color: .red, on: file)
        XCTAssertEqual(service.tags(of: file), [])
    }

    func testToggleKeepsOtherTags() throws {
        try service.setTags([FileTag(name: "Todo")], on: file)

        try service.toggle(color: .blue, on: file)

        let tags = service.tags(of: file)
        XCTAssertEqual(tags.count, 2)
        XCTAssertTrue(tags.contains(FileTag(name: "Todo")))
        XCTAssertTrue(tags.contains(FileTag(name: "Blue", color: .blue)))
    }

    func testRemoveAll() throws {
        try service.toggle(color: .green, on: file)
        try service.toggle(color: .yellow, on: file)

        try service.removeAll(from: file)

        XCTAssertEqual(service.tags(of: file), [])
    }

    func testDefaultNames() {
        XCTAssertEqual(FinderTagService.defaultName(for: .gray), "Gray")
        XCTAssertEqual(FinderTagService.defaultName(for: .orange), "Orange")
    }
}
