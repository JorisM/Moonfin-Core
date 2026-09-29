import XCTest
import CoreAudio
@testable import Moonfin

final class MacosAudioRouteTests: XCTestCase {
    func testBluetoothTransportsMapToBluetooth() {
        XCTAssertEqual(MacosAudioRoute.routeName(forTransportType: kAudioDeviceTransportTypeBluetooth), "bluetooth")
        XCTAssertEqual(MacosAudioRoute.routeName(forTransportType: kAudioDeviceTransportTypeBluetoothLE), "bluetooth")
    }

    func testBuiltInMapsToSpeaker() {
        XCTAssertEqual(MacosAudioRoute.routeName(forTransportType: kAudioDeviceTransportTypeBuiltIn), "speaker")
    }

    func testHdmiAndDisplayPortMapToHdmi() {
        XCTAssertEqual(MacosAudioRoute.routeName(forTransportType: kAudioDeviceTransportTypeHDMI), "hdmi")
        XCTAssertEqual(MacosAudioRoute.routeName(forTransportType: kAudioDeviceTransportTypeDisplayPort), "hdmi")
    }

    func testWiredTransportsMapToHeadphones() {
        XCTAssertEqual(MacosAudioRoute.routeName(forTransportType: kAudioDeviceTransportTypeUSB), "headphones")
    }

    func testUnknownTransportFallsThroughToOther() {
        XCTAssertEqual(MacosAudioRoute.routeName(forTransportType: kAudioDeviceTransportTypeUnknown), "other")
        XCTAssertEqual(MacosAudioRoute.routeName(forTransportType: 0x6d656f77), "other")
    }

    func testCapabilityMapMatchesOptimisticFallbackExceptRoute() {
        let map = MacosAudioRoute.capabilities(routeName: "bluetooth")
        XCTAssertEqual(map["activeRouteType"] as? String, "bluetooth")
        XCTAssertEqual(map["maxPcmChannels"] as? Int, 8)
        XCTAssertEqual(map["canDecodeEac3"] as? Bool, true)
        XCTAssertEqual(map["canPassthroughEac3"] as? Bool, false)
        XCTAssertEqual(map["routeSupportsHdAudio"] as? Bool, false)
    }
}
