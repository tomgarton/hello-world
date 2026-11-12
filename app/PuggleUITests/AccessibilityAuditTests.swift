import XCTest

/// Apple's accessibility audit on the main screens: contrast, text cut off at
/// large sizes, buttons without a spoken name, and touch targets that are too small.
/// Runs against the sample family, so every screen has something on it.
final class AccessibilityAuditTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = true
        app = await XCUIApplication()
        await MainActor.run {
            app.launchArguments += ["-uitest", "1"]
            app.launch()
        }
    }

    /// Everything except checks that report on the system's own controls
    /// (the tab bar and navigation buttons), which we don't draw.
    @MainActor
    private func audit(_ screen: String, file: StaticString = #filePath, line: UInt = #line) throws {
        try app.performAccessibilityAudit(for: [.contrast, .dynamicType, .elementDetection, .hitRegion, .sufficientElementDescription, .textClipped, .trait]) { issue in
            let element = issue.element
            let what = element.map { "\($0.elementType.rawValue) '\($0.label)' '\($0.identifier)'" } ?? "?"
            print("AUDIT [\(screen)] \(issue.auditType): \(issue.compactDescription) — \(what)")
            // Report every issue, then fail the test so it is seen.
            return false
        }
    }

    @MainActor
    func testToday() throws {
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 10))
        try audit("Today")
    }

    @MainActor
    func testHistory() throws {
        app.tabBars.buttons["History"].tap()
        try audit("History")
    }

    @MainActor
    func testInsights() throws {
        app.tabBars.buttons["Insights"].tap()
        try audit("Insights")
    }

    @MainActor
    func testFamily() throws {
        app.tabBars.buttons["Family"].tap()
        try audit("Family")
    }
}
