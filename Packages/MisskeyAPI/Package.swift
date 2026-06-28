// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "MisskeyAPI",
  platforms: [.iOS("26.0")],
  products: [
    .library(
      name: "MisskeyAPI",
      targets: ["MisskeyAPI"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/ishkawa/APIKit.git", from: "5.4.0")
  ],
  targets: [
    .target(
      name: "MisskeyAPI",
      dependencies: [
        .product(name: "APIKit", package: "APIKit")
      ]
    )
  ],
  swiftLanguageModes: [.v6]
)
