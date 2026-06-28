// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "MFMRenderer",
  platforms: [.iOS("26.0")],
  products: [
    .library(
      name: "MFMRenderer",
      targets: ["MFMRenderer"]
    )
  ],
  dependencies: [
    .package(
      url: "https://github.com/SDWebImage/SDWebImage.git",
      from: "5.21.7"
    ),
    .package(path: "../MFMParser"),
  ],
  targets: [
    .target(
      name: "MFMRenderer",
      dependencies: [
        .product(name: "SDWebImage", package: "SDWebImage"),
        .product(name: "MFMParser", package: "MFMParser"),
      ],
      swiftSettings: [.defaultIsolation(MainActor.self)]
    )
  ],
  swiftLanguageModes: [.v6]
)
