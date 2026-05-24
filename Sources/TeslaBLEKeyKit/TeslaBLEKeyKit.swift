import Foundation

/// Utilities for talking to Tesla vehicles over the local BLE command protocol.
///
/// This package is intentionally local-only: it wraps the BLE transport,
/// universal-message session authentication, and VCSEC commands without using
/// Tesla Fleet API HTTP endpoints.
public enum TeslaBLEKeyKit {
    public static let vehicleCommandSource = "teslamotors/vehicle-command"
}

public typealias TeslaDomain = UniversalMessage_Domain
public typealias TeslaVCSECStatus = VCSEC_VehicleStatus
public typealias TeslaVCSECResponse = VCSEC_FromVCSECMessage
