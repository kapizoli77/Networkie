// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(name: "Networkie",
                      platforms: [.iOS(.v11)],
                      products: [.library(name: "Networkie",
                                          targets: ["Networkie"])],
                      targets: [.target(name: "Networkie",
                                        path: "Source")],
                      swiftLanguageVersions: [.v5])
