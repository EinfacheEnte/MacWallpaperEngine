// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WallpaperEngineMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "WallpaperEngineMac", targets: ["WallpaperEngineMac"])
    ],
    targets: [
        .executableTarget(
            name: "WallpaperEngineMac",
            path: "Sources",
            exclude: ["WallpaperEngineSaver"]
        )
    ]
)
