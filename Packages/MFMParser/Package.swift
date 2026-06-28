// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "MFMParser",
  platforms: [.iOS("26.0")],
  products: [
    .library(
      name: "MFMParser",
      targets: ["MFMParser"]
    )
  ],
  targets: [
    .target(
      name: "MFMParser"
    ),
    .testTarget(
      name: "MFMParserTests",
      dependencies: ["MFMParser"]
    ),
  ],
  swiftLanguageModes: [.v6]
)
