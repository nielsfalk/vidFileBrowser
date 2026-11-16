import AppKit
import XCTest
@testable import VidFileBrowser

final class BrowserShortcutTests: XCTestCase {
    func testPlaybackAndFullScreenKeys() {
        XCTAssertEqual(shortcut(character: "f", keyCode: 3), .toggleFullScreen)
        XCTAssertEqual(shortcut(character: " ", keyCode: 49), .playPause)
        XCTAssertEqual(shortcut(character: "n", keyCode: 45), .trimLeft)
        XCTAssertEqual(shortcut(character: "m", keyCode: 46), .trimRight)
        XCTAssertEqual(shortcut(character: ",", keyCode: 43), .skipBackward30)
        XCTAssertEqual(shortcut(character: ".", keyCode: 47), .skipForward30)
    }

    func testArrowKeys() {
        XCTAssertEqual(shortcut(character: String(UnicodeScalar(NSLeftArrowFunctionKey)!), keyCode: 123), .skipBackward10)
        XCTAssertEqual(shortcut(character: String(UnicodeScalar(NSRightArrowFunctionKey)!), keyCode: 124), .skipForward10)
        XCTAssertEqual(shortcut(character: String(UnicodeScalar(27)!), keyCode: 53), .exitFullScreen)
    }

    func testUnhandledKeys() {
        XCTAssertNil(shortcut(character: "a", keyCode: 0))
        XCTAssertNil(shortcut(character: "y", keyCode: 16))
    }

    func testModifierKeysAreNotShortcuts() {
        XCTAssertNil(event(character: "f", keyCode: 3, modifiers: .command).flatMap(BrowserShortcut.init(event:)))
    }

    private func shortcut(character: String, keyCode: UInt16) -> BrowserShortcut? {
        event(character: character, keyCode: keyCode).flatMap(BrowserShortcut.init(event:))
    }

    private func event(character: String, keyCode: UInt16, modifiers: NSEvent.ModifierFlags = []) -> NSEvent? {
        NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: modifiers,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: character,
            charactersIgnoringModifiers: character,
            isARepeat: false,
            keyCode: keyCode
        )
    }
}
