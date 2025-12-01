// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

var swiftSettings: [SwiftSetting] = [
    .define("GRDBCUSTOMSQLITE"),
    .define("SQLITE_ENABLE_FTS5"),
]

var cSettings: [CSetting] = [
    // ⭐ FIXED — SQLCipher required flags:
    .define("SQLITE_HAS_CODEC", to: "1"),
    .define("SQLITE_TEMP_STORE", to: "2"),           // MUST be 2 or 3; SQLCipher enforces 2
    .define("SQLITE_THREADSAFE", to: "1"),
    .define("SQLITE_CORE", to: "1"),

    // ⭐ SQLCipher initialization hooks:
    .define("SQLITE_EXTRA_INIT", to: "sqlcipher_extra_init"),
    .define("SQLITE_EXTRA_SHUTDOWN", to: "sqlcipher_extra_shutdown"),

    // ⭐ Use Apple’s CommonCrypto backend instead of OpenSSL:
    .define("SQLCIPHER_CRYPTO_CC"),

    // Helps avoid warnings during build:
    .unsafeFlags(["-Wno-shorten-64-to-32", "-Wno-unused-function"])
]

var dependencies: [PackageDescription.Package.Dependency] = []

if ProcessInfo.processInfo.environment["SQLITE_ENABLE_PREUPDATE_HOOK"] == "1" {
    swiftSettings.append(.define("SQLITE_ENABLE_PREUPDATE_HOOK"))
    cSettings.append(.define("GRDB_SQLITE_ENABLE_PREUPDATE_HOOK"))
}

if ProcessInfo.processInfo.environment["SPI_BUILDER"] == "1" {
    dependencies.append(.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"))
}

let package = Package(
    name: "GRDB",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v7),
    ],
    products: [
        .library(name: "GRDB", targets: ["GRDB"]),
        .library(name: "GRDB-dynamic", type: .dynamic, targets: ["GRDB"]),
    ],
    dependencies: dependencies,
    targets: [

        // ⭐ C SQLCipher Target
        .target(
            name: "SQLCipher",
            path: "Sources/SQLCipher",
            publicHeadersPath: ".",
            cSettings: cSettings + [
                .define("GRDBCUSTOMSQLITE")
            ]
        ),

        // ⭐ GRDB Swift target — imports the above custom C SQLCipher build
        .target(
            name: "GRDB",
            dependencies: ["SQLCipher"],
            path: "GRDB",
            resources: [.copy("PrivacyInfo.xcprivacy")],
            cSettings: cSettings + [
                .define("GRDBCUSTOMSQLITE")
            ],
            swiftSettings: swiftSettings + [
                .define("GRDBCUSTOMSQLITE")
            ]
        ),

        .testTarget(
            name: "GRDBTests",
            dependencies: ["GRDB"],
            path: "Tests",
            exclude: [
                "CocoaPods", "Crash", "CustomSQLite",
                "GRDBManualInstall", "GRDBTests/getThreadsCount.c",
                "Info.plist", "Performance", "SPM", "Swift6Migration",
                "generatePerformanceReport.rb", "parsePerformanceTests.rb",
            ],
            resources: [
                .copy("GRDBTests/Betty.jpeg"),
                .copy("GRDBTests/InflectionsTests.json"),
                .copy("GRDBTests/Issue1383.sqlite"),
            ],
            cSettings: cSettings,
            swiftSettings: swiftSettings + [
                .swiftLanguageMode(.v5),
                .enableUpcomingFeature("InferSendableFromCaptures"),
                .enableUpcomingFeature("GlobalActorIsolatedTypesUsability"),
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)

