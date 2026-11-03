import XCTest
final class ProNavigationUITests: XCTestCase {
    private var app: XCUIApplication!
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }
    private func launchDashboard(extra: [String] = []) {
        app.launchArguments = ["-showWelcomeOnLaunch", "NO"] + extra
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["screen.home"].waitForExistence(timeout: 10))
    }
    private func reveal(_ element: XCUIElement) {
        for _ in 0..<12 { if element.isHittable { return }; app.swipeUp() }
    }
    func testWelcomeAttributionAndContinue() {
        app.launchArguments = ["-showWelcomeOnLaunch", "YES"]
        app.launch()
        XCTAssertTrue(app.buttons["welcome.continue"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["welcome.developer"].exists || app.otherElements["welcome.developer"].exists)
        reveal(app.buttons["welcome.continue"])
        app.buttons["welcome.continue"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["screen.home"].waitForExistence(timeout: 5))
    }
    func testDashboardRoutesIncludeEveryCalculator() {
        launchDashboard()
        app.tabBars.buttons["Calculators"].tap()
        for id in ["pension", "orop", "commutation", "gratuity", "disability", "family", "arrears", "leaveEncashment", "sevaNidhi", "npsUPS"] {
            let row = app.descendants(matching: .any)["directory.\(id)"]
            reveal(row)
            XCTAssertTrue(row.exists, "Missing calculator route \(id)")
        }
    }
    func testImplementedRoutesNavigateToExistingScreens() {
        for (id, title) in [("pension", "Pension Calculator"), ("orop", "OROP Comparison"),
                            ("commutation", "Commutation"), ("disability", "Disability & War Injury"),
                            ("family", "Family Pension"), ("arrears", "Pension Arrears")] {
            launchDashboard(); app.tabBars.buttons["Calculators"].tap()
            let row = app.descendants(matching: .any)["directory.\(id)"]; reveal(row); row.tap()
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 5))
        }
    }
    func testUnavailableRoutesNavigateToExplicitExplanation() {
        for id in ["gratuity", "leaveEncashment", "sevaNidhi", "npsUPS"] {
            launchDashboard()
            app.tabBars.buttons["Calculators"].tap()
            XCTAssertTrue(app.descendants(matching: .any)["screen.calculators"].waitForExistence(timeout: 10), "Calculators tab did not open")
            let row = app.descendants(matching: .any)["directory.\(id)"]
            XCTAssertTrue(row.waitForExistence(timeout: 10), "Missing calculator route \(id)")
            reveal(row)
            XCTAssertTrue(row.isHittable, "Calculator route \(id) is not hittable")
            row.tap()
            XCTAssertTrue(app.staticTexts["Calculation unavailable"].waitForExistence(timeout: 5))
        }
    }
    func testAboutDeveloperAttributionAndDisclaimer() {
        launchDashboard(); app.tabBars.buttons["Settings"].tap()
        app.descendants(matching: .any)["settings.aboutDeveloper"].tap()
        XCTAssertTrue(app.staticTexts["about.name"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["about.name"].label, "Jaspal Singh")
        let disclaimer = app.descendants(matching: .any)["about.disclaimer"]
        reveal(disclaimer)
        XCTAssertTrue(disclaimer.exists)
        XCTAssertTrue(disclaimer.label.contains("Independent application"))
        XCTAssertTrue(app.descendants(matching: .any)["about.version"].exists)
    }
    func testReportsWithoutCalculationDoNotShowFakePension() {
        launchDashboard(); app.tabBars.buttons["Reports"].tap()
        XCTAssertTrue(app.staticTexts["Your pension report"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["report.generatePDF"].exists)
    }
    func testDashboardInDarkMode() {
        launchDashboard(extra: ["-AppleInterfaceStyle", "Dark"])
        XCTAssertTrue(app.buttons["calculator.pension"].exists)
        XCTAssertTrue(app.tabBars.buttons["References"].exists)
        app.tabBars.buttons["References"].tap()
        XCTAssertTrue(app.staticTexts["Official tables unavailable"].waitForExistence(timeout: 5))
    }
    func testDashboardAtAccessibilityTextSize() {
        launchDashboard(extra: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        let calculator = app.buttons["calculator.pension"]; reveal(calculator)
        XCTAssertTrue(calculator.isHittable)
    }
}
