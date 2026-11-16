import XCTest
@testable import VidFileBrowser

final class MPVLibraryTests: XCTestCase {
    func testMissingLibraryDoesNotLoad() {
        XCTAssertNil(MPVLibrary(path: "/nonexistent/directory/libmpv.dylib"))
    }

    func testLocateReturnsLibraryOnlyWhenInstalled() {
        let missing = Dependencies(libmpvPath: nil, ffmpegPath: "/usr/bin/true")
        XCTAssertNil(MPVLibrary.locate(dependencies: missing))
    }

    @MainActor
    func testFactoryFallsBackWithoutLibmpv() {
        let missing = Dependencies(libmpvPath: nil, ffmpegPath: nil)

        let player = PlayerFactory.make(dependencies: missing)

        XCTAssertTrue(player is UnavailablePlayer)
    }
}
