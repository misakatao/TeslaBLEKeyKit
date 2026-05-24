# TeslaBLEKeyKit

A pure Swift library for communicating with Tesla vehicles over BLE (Bluetooth Low Energy). It implements the local BLE command protocol including universal-message session authentication and VCSEC commands — no Tesla Fleet API or network access required.

## Features

- BLE scanning, connection, and message framing via CoreBluetooth
- VCSEC protocol: lock, unlock, trunk/frunk control, remote drive, and more
- Session authentication with P256 key agreement (AES-GCM / HMAC-SHA256)
- Key management: generate key pairs and add keys to vehicle whitelist
- Async/await API with structured concurrency
- Supports iOS 16+ and macOS 13+

## Requirements

- Swift 5.9+
- iOS 16.0+ / macOS 13.0+
- Bluetooth LE capable hardware

## Installation

### Swift Package Manager

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/misakatao/TeslaBLEKeyKit.git", from: "0.1.0"),
]
```

Then add `"TeslaBLEKeyKit"` to your target's dependencies.

### CocoaPods

Add to your `Podfile`:

```ruby
pod 'TeslaBLEKeyKit', '~> 0.1.0'
```

Then run `pod install`.

## Quick Start

```swift
import TeslaBLEKeyKit

// 1. Generate or load a private key
let privateKey = TeslaPrivateKey.generate()

// 2. Create a BLE connection
let connection = try BLEConnection(vin: "5YJ3E1EA0LF000000")
try await connection.connect()

// 3. Create a vehicle instance
let vehicle = try TeslaVehicle(connector: connection, privateKey: privateKey)
try await vehicle.connect()

// 4. Start a VCSEC session
try await vehicle.startVCSECSession()

// 5. Send commands
try await vehicle.wakeVehicle()
try await vehicle.unlock()
try await vehicle.lock()
try await vehicle.openTrunk()
```

### Adding a Key to the Vehicle

```swift
let newKey = TeslaPrivateKey.generate()
try await vehicle.addKeyToWhitelist(
    publicKey: newKey.publicKey,
    role: .driver,
    formFactor: .iosDevice
)
```

## Available Commands

| Command | Method |
|---------|--------|
| Wake | `wakeVehicle()` |
| Unlock | `unlock()` |
| Lock | `lock()` |
| Open/Close Trunk | `openTrunk()` / `closeTrunk()` |
| Open Frunk | `openFrunk()` |
| Open/Close/Stop Tonneau | `openTonneau()` / `closeTonneau()` / `stopTonneau()` |
| Remote Drive | `remoteDrive()` |
| Auto Secure | `autoSecureVehicle()` |
| Vehicle Status | `vehicleStatus()` |
| Add Key | `addKeyToWhitelist(publicKey:role:formFactor:)` |

## Configuration

```swift
let config = TeslaVehicleConfiguration(
    nonceMode: .teslaBLE4Byte,  // or .standard12Byte
    commandTimeout: 10,
    sessionTimeout: 15
)
let vehicle = try TeslaVehicle(
    connector: connection,
    privateKey: privateKey,
    configuration: config
)
```

## License

MIT License. See [LICENSE](LICENSE) for details.
