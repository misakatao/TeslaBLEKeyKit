@_exported import TeslaBLEKeyKitCore
@_exported import TeslaBLEKeyKitCrypto
@_exported import TeslaBLEKeyKitBLE

import Foundation

public enum TeslaBLEKeyKit {
    public static let vehicleCommandSource = "teslamotors/vehicle-command"
}

public typealias TeslaVCSECStatus = VCSEC_VehicleStatus
public typealias TeslaVCSECResponse = VCSEC_FromVCSECMessage
