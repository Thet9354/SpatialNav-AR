//
//  AccessibilityAuditTests.swift
//  SpatialNavUITests
//
//  Xcode's built-in accessibility audit (element descriptions, hit regions,
//  contrast, Dynamic Type) against the two screens reachable in the simulator:
//  onboarding and the main screen (which shows the unsupported-device state
//  where there is no AR hardware).
//

import XCTest

final class AccessibilityAuditTests: XCTestCase {

    @MainActor
    func testOnboardingAndMainScreenPassAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launchArguments += ["--uitest-reset"]
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Welcome to SpatialNav"].waitForExistence(timeout: 10),
            "Onboarding should appear on a fresh install"
        )
        try performLoggedAudit(on: app)

        let firstMode = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Sound and Vibration'")
        ).firstMatch
        XCTAssertTrue(firstMode.waitForExistence(timeout: 5))
        firstMode.tap()

        XCTAssertTrue(
            app.staticTexts["Device Not Supported"].waitForExistence(timeout: 10),
            "Simulator has no AR support, so the main screen shows the unsupported state"
        )
        try performLoggedAudit(on: app)
    }

    /// Prints every audit issue to the console so a failure names the exact
    /// element and problem instead of just "audit failed".
    @MainActor
    private func performLoggedAudit(on app: XCUIApplication) throws {
        try app.performAccessibilityAudit { issue in
            print("ACCESSIBILITY AUDIT ISSUE: \(issue.auditType) — \(issue.compactDescription) — element: \(issue.element.map(String.init(describing:)) ?? "unknown")")
            return false // never ignore; fail the test
        }
    }
}
