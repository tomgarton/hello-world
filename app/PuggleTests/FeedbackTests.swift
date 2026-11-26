import XCTest
@testable import Puggle

final class FeedbackTests: XCTestCase {
    func testNotesAreCopiedOutWithTheirDateAndBuild() {
        let at = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let notes = [FeedbackNote(text: "The bubbles are cut off.", at: at, build: "0.1.0 (9)"),
                     FeedbackNote(text: "Second note.", at: at, build: "0.1.0 (8)")]
        let text = FeedbackNotes.text(notes)
        XCTAssertTrue(text.contains("Build 0.1.0 (9)\nThe bubbles are cut off."))
        XCTAssertTrue(text.contains("\n\n"))
        XCTAssertTrue(text.hasSuffix("Second note."))
    }

    func testTheBuildComesFromTheApp() {
        XCTAssertTrue(FeedbackNote.currentBuild.contains("("))
    }
}
