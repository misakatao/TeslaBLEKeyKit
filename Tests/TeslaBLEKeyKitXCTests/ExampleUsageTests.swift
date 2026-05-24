import XCTest
@testable import TeslaBLEKeyKit

/// Example tests demonstrating typical usage patterns of TeslaBLEKeyKit.
/// These serve as both integration tests and living documentation.
final class ExampleUsageTests: XCTestCase {

    // MARK: - Key Generation & Persistence

    func testKeyGenerationAndPersistence() throws {
        let key = TeslaPrivateKey.generate()

        let raw = key.rawRepresentation
        let restored = try TeslaPrivateKey(rawRepresentation: raw)
        XCTAssertEqual(restored.publicKey, key.publicKey)

        let pem = key.pemRepresentation
        let fromPEM = try TeslaPrivateKey(pemRepresentation: pem)
        XCTAssertEqual(fromPEM.publicKey, key.publicKey)

        let der = key.derRepresentation
        let fromDER = try TeslaPrivateKey(derRepresentation: der)
        XCTAssertEqual(fromDER.publicKey, key.publicKey)
    }

    func testKeyPairForVehiclePairing() throws {
        let ownerKey = TeslaPrivateKey.generate()
        let phoneKey = TeslaPrivateKey.generate()

        XCTAssertEqual(ownerKey.publicKey.count, 65)
        XCTAssertEqual(phoneKey.publicKey.count, 65)
        XCTAssertNotEqual(ownerKey.publicKey, phoneKey.publicKey)

        let sharedFromOwner = try ownerKey.sharedAESKey(with: phoneKey.publicKey)
        XCTAssertEqual(sharedFromOwner.count, 16)
    }

    // MARK: - BLE Frame Encoding/Decoding

    func testBLEMessageFramingRoundTrip() throws {
        let originalPayload = Data("VCSEC command payload".utf8)

        let framed = try BLEFramer.encode(originalPayload)
        XCTAssertEqual(framed.count, originalPayload.count + 2)

        var framer = BLEFramer()
        let messages = try framer.receive(framed)
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0], originalPayload)
    }

    func testBLEChunkedTransmission() throws {
        let payload = try ByteUtilities.randomData(count: 200)
        let framed = try BLEFramer.encode(payload)

        var framer = BLEFramer()
        let chunkSize = 20
        var offset = 0
        var decoded: [Data] = []

        while offset < framed.count {
            let end = min(offset + chunkSize, framed.count)
            let chunk = framed[framed.index(framed.startIndex, offsetBy: offset)..<framed.index(framed.startIndex, offsetBy: end)]
            let messages = try framer.receive(Data(chunk))
            decoded.append(contentsOf: messages)
            offset = end
        }

        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded[0], payload)
    }

    // MARK: - Encryption for Vehicle Communication

    func testEncryptedCommunicationSimulation() throws {
        let vehicleKey = TeslaPrivateKey.generate()
        let phoneKey = TeslaPrivateKey.generate()

        let sessionKey = try phoneKey.sharedAESKey(with: vehicleKey.publicKey)
        XCTAssertEqual(sessionKey.count, 16)

        let gcm = try VariableNonceAESGCM(key: sessionKey)
        let command = Data("unlock_doors".utf8)
        let metadata = Data("domain:vcsec".utf8)

        let sealed = try gcm.seal(
            plaintext: command,
            authenticatedData: metadata,
            nonceMode: .teslaBLE4Byte
        )

        XCTAssertEqual(sealed.nonce.count, 4)
        XCTAssertEqual(sealed.tag.count, 16)
        XCTAssertNotEqual(sealed.ciphertext, command)

        let decrypted = try gcm.open(sealed, authenticatedData: metadata)
        XCTAssertEqual(decrypted, command)
    }

    func testMultipleCommandsWithDifferentNonces() throws {
        let key = try ByteUtilities.randomData(count: 16)
        let gcm = try VariableNonceAESGCM(key: key)

        let commands = ["lock", "unlock", "trunk_open", "frunk_open"]
        var sealedBoxes: [AESGCMSealedBox] = []

        for command in commands {
            let sealed = try gcm.seal(plaintext: Data(command.utf8), nonceMode: .standard12Byte)
            sealedBoxes.append(sealed)
        }

        let nonces = Set(sealedBoxes.map { $0.nonce })
        XCTAssertEqual(nonces.count, commands.count)

        for (index, sealed) in sealedBoxes.enumerated() {
            let decrypted = try gcm.open(sealed)
            XCTAssertEqual(String(data: decrypted, encoding: .utf8), commands[index])
        }
    }

    // MARK: - Anti-Replay Protection

    func testAntiReplayProtection() {
        var window = SlidingWindow(size: 32)

        XCTAssertTrue(window.update(1))
        XCTAssertTrue(window.update(2))
        XCTAssertTrue(window.update(3))

        XCTAssertFalse(window.update(2))
        XCTAssertFalse(window.update(1))

        XCTAssertTrue(window.update(5))
        XCTAssertTrue(window.update(4))

        XCTAssertTrue(window.update(100))
        XCTAssertFalse(window.update(3))
    }

    // MARK: - Vehicle Local Name Discovery

    func testVehicleDiscoveryByVIN() throws {
        let vin = "5YJ3E1EA0LF000000"
        let localName = try vehicleLocalName(forVIN: vin)

        XCTAssertTrue(localName.hasPrefix("S"))
        XCTAssertTrue(localName.hasSuffix("C"))

        let sameVIN = try vehicleLocalName(forVIN: vin)
        XCTAssertEqual(localName, sameVIN)
    }

    // MARK: - Configuration

    func testVehicleConfigurationDefaults() {
        let standard = TeslaVehicleConfiguration.standard
        XCTAssertEqual(standard.nonceMode, .standard12Byte)
        XCTAssertEqual(standard.commandTimeout, 10)
        XCTAssertEqual(standard.sessionTimeout, 15)

        let ble4 = TeslaVehicleConfiguration.fourByteNonceBLE
        XCTAssertEqual(ble4.nonceMode, .teslaBLE4Byte)
    }

    func testCustomConfiguration() {
        let config = TeslaVehicleConfiguration(
            nonceMode: .custom(8),
            commandTimeout: 30,
            sessionTimeout: 60
        )
        XCTAssertEqual(config.nonceMode.length, 8)
        XCTAssertEqual(config.commandTimeout, 30)
        XCTAssertEqual(config.sessionTimeout, 60)
    }

    // MARK: - Error Handling Patterns

    func testErrorRetryDecision() {
        let retryableErrors: [TeslaError] = [
            .vehicleBusy,
            .scanTimedOut,
            .protocolFault(1),
            .protocolFault(2),
        ]
        for error in retryableErrors {
            XCTAssertTrue(shouldRetry(error), "\(error) should be retryable")
        }

        let nonRetryableErrors: [TeslaError] = [
            .timeout,
            .keyNotPaired,
            .invalidVIN,
            .notConnected,
            .crypto("bad key"),
        ]
        for error in nonRetryableErrors {
            XCTAssertFalse(shouldRetry(error), "\(error) should not be retryable")
        }
    }
}
