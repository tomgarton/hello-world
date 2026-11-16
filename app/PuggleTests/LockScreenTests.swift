import XCTest
@testable import Puggle

/// The family card on the Lock Screen, and the links that open a log sheet from a widget (16 November 2026).
@MainActor
final class LockScreenTests: XCTestCase {
    private func card(_ id: String, _ mode: String, minutesAgo: Double) -> LiveTimers.Wanted {
        let at = Date.now.addingTimeInterval(-minutesAgo * 60)
        var state = TimerAttributes.ContentState(mode: mode)
        if mode == "glance" { state.fedSince = at } else { state.since = at }
        return .init(attributes: .init(childID: id, childName: id.capitalized, colourIndex: 0), state: state)
    }

    func testOneChildIsOneCardWithNobodyElse() throws {
        let all = LiveTimers.family([card("ollie", "glance", minutesAgo: 90)])
        let only = try XCTUnwrap(all[TimerAttributes.familyID])
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(only.state.leadID, "ollie")
        XCTAssertEqual(only.state.others ?? [], [])
        XCTAssertNil(only.state.more)
    }

    func testAFeedThenASleepThenWhoeverWasFedLongestAgo() throws {
        let all = LiveTimers.family([
            card("kit", "glance", minutesAgo: 30),
            card("bea", "sleep", minutesAgo: 70),
            card("ollie", "glance", minutesAgo: 120),
        ])
        let state = try XCTUnwrap(all[TimerAttributes.familyID]).state
        XCTAssertEqual(state.leadID, "bea")
        XCTAssertEqual(state.others?.map(\.id), ["ollie", "kit"])

        let feeding = try XCTUnwrap(LiveTimers.family([card("bea", "sleep", minutesAgo: 70), card("ollie", "feed", minutesAgo: 5)])[TimerAttributes.familyID]).state
        XCTAssertEqual(feeding.leadID, "ollie")
    }

    func testTheRestAreCountedWhenThereIsNoRoom() throws {
        let four = ["a", "b", "c", "d"].enumerated().map { card($0.element, "glance", minutesAgo: Double(100 - $0.offset)) }
        let state = try XCTUnwrap(LiveTimers.family(four)[TimerAttributes.familyID]).state
        XCTAssertEqual(state.others?.count, 2)
        XCTAssertEqual(state.more, 1)

        // Under a feed with its buttons there is room for one more row.
        let underFeed = [card("a", "feed", minutesAgo: 5), card("b", "glance", minutesAgo: 60), card("c", "glance", minutesAgo: 30)]
        let fed = try XCTUnwrap(LiveTimers.family(underFeed)[TimerAttributes.familyID]).state
        XCTAssertEqual(fed.others?.map(\.id), ["b"])
        XCTAssertEqual(fed.more, 1)
    }

    func testTheButtonsAreForTheFirstChild() {
        let attributes = TimerAttributes(childID: TimerAttributes.familyID, childName: "Family", colourIndex: nil)
        var state = TimerAttributes.ContentState(mode: "sleep")
        state.leadID = "bea"
        state.leadName = "Bea"
        state.leadColour = 2
        XCTAssertEqual(attributes.lead(state).childID, "bea")
        XCTAssertEqual(attributes.lead(state).colourIndex, 2)
        // A card made before the family card is its own child's.
        let old = TimerAttributes(childID: "ollie", childName: "Ollie", colourIndex: 0)
        XCTAssertEqual(old.lead(.init(mode: "glance")).childID, "ollie")
    }

    func testAnOldCardStillReads() throws {
        // What a card saved before the family fields looks like.
        let json = #"{"mode":"glance","label":"","fedSince":700000000}"#
        let state = try JSONDecoder().decode(TimerAttributes.ContentState.self, from: Data(json.utf8))
        XCTAssertNil(state.others)
        XCTAssertNil(state.leadID)
    }

    func testLinksGoThereAndBack() throws {
        let url = PuggleLink.log("nappy", child: "1234-ABCD")
        XCTAssertEqual(url.absoluteString, "puggle://log/nappy?child=1234-ABCD")
        let back = try XCTUnwrap(PuggleLink.parse(url))
        XCTAssertEqual(back.fact, "nappy")
        XCTAssertEqual(back.child, "1234-ABCD")
        XCTAssertNil(PuggleLink.parse(URL(string: "puggle://log/sing?child=1")!))
        XCTAssertNil(PuggleLink.parse(URL(string: "puggle://log/fed")!))
        XCTAssertNil(PuggleLink.parse(URL(string: "https://example.com/log/fed?child=1")!))
    }
}
