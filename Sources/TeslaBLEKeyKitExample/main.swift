import Foundation
import TeslaBLEKeyKit

print("=== TeslaBLEKeyKit Example ===\n")

// MARK: - Key Generation

print("1. Key Generation")
let privateKey = TeslaPrivateKey.generate()
print("   Private key (raw): \(privateKey.rawRepresentation.count) bytes")
print("   Public key (x963): \(privateKey.publicKey.count) bytes")
print("   Public key hex:    \(privateKey.publicKey.prefix(8).hexString())...\n")

// MARK: - Key Serialization

print("2. Key Serialization")
let pem = privateKey.pemRepresentation
print("   PEM format: \(pem.prefix(27))...")
let der = privateKey.derRepresentation
print("   DER format: \(der.count) bytes\n")

// MARK: - Key Restoration

print("3. Key Round-Trip")
do {
    let restored = try TeslaPrivateKey(rawRepresentation: privateKey.rawRepresentation)
    print("   Restored key matches: \(restored.publicKey == privateKey.publicKey)\n")
} catch {
    print("   Error: \(error)\n")
}

// MARK: - Vehicle Local Name

print("4. Vehicle BLE Discovery Name")
do {
    let vin = "5YJ3E1EA0LF000000"
    let localName = try vehicleLocalName(forVIN: vin)
    print("   VIN: \(vin)")
    print("   BLE local name: \(localName)\n")
} catch {
    print("   Error: \(error)\n")
}

// MARK: - AES-GCM Encryption

print("5. AES-GCM Encryption")
do {
    let alice = TeslaPrivateKey.generate()
    let bob = TeslaPrivateKey.generate()
    let sessionKey = try alice.sharedAESKey(with: bob.publicKey)
    print("   Session key: \(sessionKey.hexString())")

    let gcm = try VariableNonceAESGCM(key: sessionKey)
    let message = Data("unlock_doors".utf8)
    let sealed = try gcm.seal(plaintext: message, nonceMode: .teslaBLE4Byte)
    print("   Plaintext:   \(String(data: message, encoding: .utf8)!)")
    print("   Ciphertext:  \(sealed.ciphertext.hexString())")
    print("   Nonce:       \(sealed.nonce.hexString())")
    print("   Tag:         \(sealed.tag.hexString())")

    let decrypted = try gcm.open(sealed)
    print("   Decrypted:   \(String(data: decrypted, encoding: .utf8)!)")
    print("   Match:       \(decrypted == message)\n")
} catch {
    print("   Error: \(error)\n")
}

// MARK: - BLE Framing

print("6. BLE Message Framing")
do {
    let payload = Data("VCSEC command".utf8)
    let framed = try BLEFramer.encode(payload)
    print("   Payload:     \(payload.count) bytes")
    print("   Framed:      \(framed.count) bytes (2-byte length prefix)")

    var framer = BLEFramer()
    let decoded = try framer.receive(framed)
    print("   Decoded:     \(decoded.count) message(s)")
    print("   Match:       \(decoded.first == payload)\n")
} catch {
    print("   Error: \(error)\n")
}

// MARK: - Configuration

print("7. Vehicle Configuration Presets")
let standard = TeslaVehicleConfiguration.standard
print("   Standard: nonce=\(standard.nonceMode.length)B, timeout=\(Int(standard.commandTimeout))s")
let ble4 = TeslaVehicleConfiguration.fourByteNonceBLE
print("   BLE 4-byte: nonce=\(ble4.nonceMode.length)B, timeout=\(Int(ble4.commandTimeout))s\n")

print("=== Done ===")
