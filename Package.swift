// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "DefencePensionCalculator",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [.library(name: "PensionCore", targets: ["PensionCore"])],
    targets: [
        .target(name: "PensionCore", path: "DefencePensionCalculator",
                exclude: ["DefencePensionCalculatorApp.swift", "Presentation", "Tests", "Assets.xcassets", "Utilities/PensionPDFExporter.swift"],
                sources: ["Domain", "Data/Repositories", "Utilities/DateUtilities.swift", "Utilities/CurrencyFormatter.swift"],
                resources: [.process("Data/Resources")]),
        .testTarget(name: "PensionCoreTests", dependencies: ["PensionCore"], path: "DefencePensionCalculator/Tests")
    ]
)
