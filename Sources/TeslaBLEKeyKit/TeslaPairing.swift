import Foundation
import SwiftProtobuf
import TeslaBLEKeyKitCore
import TeslaBLEKeyKitCrypto

public final class TeslaPairing {
    private let connector: VehicleConnector

    public init(connector: VehicleConnector) {
        self.connector = connector
    }

    public func requestPairing(
        publicKey: Data,
        role: Keys_Role = .driver,
        formFactor: VCSEC_KeyFormFactor = .iosDevice
    ) async throws {
        var permission = VCSEC_PermissionChange()
        permission.key.publicKeyRaw = publicKey
        permission.keyRole = role

        var operation = VCSEC_WhitelistOperation()
        operation.addKeyToWhitelistAndAddPermissions = permission
        operation.metadataForKey.keyFormFactor = formFactor

        var payload = VCSEC_UnsignedMessage()
        payload.whitelistOperation = operation

        let bytes = try payload.serializedData()
        _ = try await sendUnauthenticated(payload: bytes) { response in
            if case .commandStatus(let status)? = response.subMessage,
               case .whitelistOperationStatus(let whitelist)? = status.subMessage {
                let code = whitelist.whitelistOperationInformation.rawValue
                return (true, code == 0 ? nil : TeslaError.whitelistError(code))
            }
            if response.hasCommandStatus {
                return (false, nil)
            }
            return (true, nil)
        }
    }

    public func vehicleStatus() async throws -> VCSEC_VehicleStatus {
        var request = VCSEC_InformationRequest()
        request.informationRequestType = .getStatus

        var payload = VCSEC_UnsignedMessage()
        payload.informationRequest = request

        let bytes = try payload.serializedData()
        let response = try await sendUnauthenticated(payload: bytes) { _ in (true, nil) }
        guard case .vehicleStatus(let status)? = response.subMessage else {
            throw TeslaError.malformedResponse("VCSEC status response missing vehicleStatus")
        }
        return status
    }

    private func sendUnauthenticated(
        payload: Data,
        done: @escaping (VCSEC_FromVCSECMessage) -> (Bool, Error?)
    ) async throws -> VCSEC_FromVCSECMessage {
        var message = UniversalMessage_RoutableMessage()
        message.toDestination.domain = .vehicleSecurity
        message.protobufMessageAsBytes = payload

        let encoded = try message.serializedData()
        try await connector.send(encoded)

        return try await withTimeout(seconds: 10) {
            for await bytes in self.connector.receiveMessages() {
                guard let routable = try? UniversalMessage_RoutableMessage(serializedBytes: bytes),
                      case .protobufMessageAsBytes(let responsePayload)? = routable.payload else {
                    continue
                }
                let response = try VCSEC_FromVCSECMessage(serializedBytes: responsePayload)
                if case .nominalError(let nominal)? = response.subMessage {
                    throw TeslaError.vcsecError(String(describing: nominal.genericError))
                }
                let result = done(response)
                if result.0 {
                    if let error = result.1 { throw error }
                    return response
                }
            }
            throw TeslaError.notConnected
        }
    }
}
