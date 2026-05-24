import Testing
import Foundation
@testable import TeslaBLEKeyKit

// MARK: - TeslaPrivateKey Tests

@Suite("TeslaPrivateKey")
struct TeslaPrivateKeyTests {
    @Test("Generate produces valid key")
    func generate() {
        let key = TeslaPrivateKey.generate()
        #expect(key.rawRepresentation.count == 32)
        #expect(!key.publicKey.isEmpty)
    }

    @Test("Public key is 65 bytes (uncompressed P-256)")
    func publicKeyLength() {
        let key = TeslaPrivateKey.generate()
        #expect(key.publicKey.count == 65)
    }

    @Test("Round-trip via raw representation")
    func rawRoundTrip() throws {
        let original = TeslaPrivateKey.generate()
        let restored = try TeslaPrivateKey(rawRepresentation: original.rawRepresentation)
        #expect(restored.publicKey == original.publicKey)
    }

    @Test("Round-trip via DER representation")
    func derRoundTrip() throws {
        let original = TeslaPrivateKey.generate()
        let restored = try TeslaPrivateKey(derRepresentation: original.derRepresentation)
        #expect(restored.publicKey == original.publicKey)
    }

    @Test("Round-trip via PEM representation")
    func pemRoundTrip() throws {
        let original = TeslaPrivateKey.generate()
        let restored = try TeslaPrivateKey(pemRepresentation: original.pemRepresentation)
        #expect(restored.publicKey == original.publicKey)
    }

    @Test("Two generated keys are different")
    func uniqueKeys() {
        let key1 = TeslaPrivateKey.generate()
        let key2 = TeslaPrivateKey.generate()
        #expect(key1.publicKey != key2.publicKey)
    }

    @Test("Shared AES key is deterministic for same key pair")
    func sharedKeyDeterministic() throws {
        let alice = TeslaPrivateKey.generate()
        let bob = TeslaPrivateKey.generate()
        let shared1 = try alice.sharedAESKey(with: bob.publicKey)
        let shared2 = try alice.sharedAESKey(with: bob.publicKey)
        #expect(shared1 == shared2)
    }

    @Test("Shared AES key is 16 bytes")
    func sharedKeyLength() throws {
        let alice = TeslaPrivateKey.generate()
        let bob = TeslaPrivateKey.generate()
        let shared = try alice.sharedAESKey(with: bob.publicKey)
        #expect(shared.count == 16)
    }

    @Test("Invalid raw representation throws")
    func invalidRaw() {
        #expect(throws: Error.self) {
            _ = try TeslaPrivateKey(rawRepresentation: Data([0x01, 0x02, 0x03]))
        }
    }
}

// MARK: - VehicleAdvertisement Tests

@Suite("VehicleAdvertisement")
struct VehicleAdvertisementTests {
    @Test("Vehicle local name from VIN")
    func localNameFromVIN() throws {
        let name = try vehicleLocalName(forVIN: "5YJ3E1EA0LF000000")
        #expect(name.hasPrefix("S"))
        #expect(name.hasSuffix("C"))
        #expect(name.count == 18)
    }

    @Test("Same VIN produces same local name")
    func localNameDeterministic() throws {
        let name1 = try vehicleLocalName(forVIN: "5YJ3E1EA0LF000000")
        let name2 = try vehicleLocalName(forVIN: "5YJ3E1EA0LF000000")
        #expect(name1 == name2)
    }

    @Test("Different VINs produce different local names")
    func localNameUnique() throws {
        let name1 = try vehicleLocalName(forVIN: "5YJ3E1EA0LF000001")
        let name2 = try vehicleLocalName(forVIN: "5YJ3E1EA0LF000002")
        #expect(name1 != name2)
    }

    @Test("Empty VIN throws invalidVIN")
    func emptyVIN() {
        #expect(throws: TeslaError.self) {
            _ = try vehicleLocalName(forVIN: "")
        }
    }
}

// MARK: - TeslaError Tests

@Suite("TeslaError")
struct TeslaErrorTests {
    @Test("Timeout may have succeeded")
    func timeoutMayHaveSucceeded() {
        #expect(TeslaError.timeout.mayHaveSucceeded == true)
    }

    @Test("Not connected has not succeeded")
    func notConnectedNotSucceeded() {
        #expect(TeslaError.notConnected.mayHaveSucceeded == false)
    }

    @Test("Vehicle busy is temporary")
    func vehicleBusyIsTemporary() {
        #expect(TeslaError.vehicleBusy.isTemporary == true)
    }

    @Test("Invalid VIN is not temporary")
    func invalidVINNotTemporary() {
        #expect(TeslaError.invalidVIN.isTemporary == false)
    }

    @Test("shouldRetry returns true for temporary non-succeeded errors")
    func shouldRetryTemporary() {
        #expect(shouldRetry(TeslaError.vehicleBusy) == true)
    }

    @Test("shouldRetry returns false for timeout")
    func shouldRetryTimeout() {
        #expect(shouldRetry(TeslaError.timeout) == false)
    }

    @Test("shouldRetry returns false for nil")
    func shouldRetryNil() {
        #expect(shouldRetry(nil) == false)
    }

    @Test("Error descriptions are not empty")
    func errorDescriptions() {
        let errors: [TeslaError] = [
            .bluetoothUnavailable, .notConnected, .invalidVIN,
            .timeout, .messageTooLarge(100), .crypto("test"),
        ]
        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
}

// MARK: - MetadataBuilder Tests

@Suite("MetadataBuilder")
struct MetadataBuilderTests {
    @Test("Checksum produces 32 bytes for SHA256 context")
    func checksumLength() {
        let meta = MetadataBuilder(context: .sha256)
        let checksum = meta.checksum()
        #expect(checksum.count == 32)
    }

    @Test("Checksum with message differs from without")
    func checksumWithMessage() throws {
        var meta = MetadataBuilder(context: .sha256)
        try meta.add(.signatureType, value: Data([0x01]))
        let without = meta.checksum()
        let with = meta.checksum(message: Data("payload".utf8))
        #expect(without != with)
    }

    @Test("HMAC context produces 32 bytes")
    func hmacContext() {
        let meta = MetadataBuilder(context: .hmacSHA256(key: Data("key".utf8)))
        let checksum = meta.checksum()
        #expect(checksum.count == 32)
    }

    @Test("Tags must be in ascending order")
    func tagOrder() throws {
        var meta = MetadataBuilder()
        try meta.add(.domain, value: Data([0x02]))
        #expect(throws: TeslaError.self) {
            try meta.add(.signatureType, value: Data([0x01]))
        }
    }
}

// MARK: - AESGCMNonceMode Tests

@Suite("AESGCMNonceMode")
struct AESGCMNonceModeTests {
    @Test("Standard 12 byte length")
    func standard12() {
        #expect(AESGCMNonceMode.standard12Byte.length == 12)
    }

    @Test("Tesla BLE 4 byte length")
    func teslaBLE4() {
        #expect(AESGCMNonceMode.teslaBLE4Byte.length == 4)
    }

    @Test("Custom length")
    func custom() {
        #expect(AESGCMNonceMode.custom(7).length == 7)
    }
}
