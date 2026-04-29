# Installation

## Requirements

| Platform | Minimum version |
|---|---|
| iOS | 16.0 |
| macOS | 13.0 |
| tvOS | 16.0 |
| watchOS | 9.0 |
| Swift | 5.9+ |

## Swift Package Manager

### In `Package.swift`

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        .package(url: "https://github.com/cyrilleguipie/arc.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "MyApp",
            dependencies: ["Arc"]
        )
    ]
)
```

### In Xcode

1. Open your project in Xcode
2. **File → Add Package Dependencies...**
3. Enter `https://github.com/cyrilleguipie/arc` in the search field
4. Select **Up to Next Major Version** starting from `1.0.0`
5. Click **Add Package**

## Import

```swift
import Arc
```

That's it. All types — `Either`, `Option`, `Validated`, `NonEmptyArray`, `Effect` — are available immediately.
