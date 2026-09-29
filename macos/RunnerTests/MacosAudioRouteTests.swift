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
        XCTAssertEqual(MacosAudioRoute.routeName(forTransportType: kAudioDeviceTransportTypeFireWire), "headphones")
        XCTAssertEqual(MacosAudioRoute.routeName(forTransportType: kAudioDeviceTransportTypeThunderbolt), "headphones")
        XCTAssertEqual(MacosAudioRoute.routeName(forTransportType: kAudioDeviceTransportTypePCI), "headphones")
    }

    func testUnknownTransportFallsThroughToOther() {
        XCTAssertEqual(MacosAudioRoute.routeName(forTransportType: kAudioDeviceTransportTypeUnknown), "other")
        XCTAssertEqual(MacosAudioRoute.routeName(forTransportType: 0x6d656f77), "other")
    }

    func testCapabilityMapMatchesOptimisticFallbackExceptRoute() {
        let map = MacosAudioRoute.capabilities(routeName: "bluetooth")
        let expectedBools: [String: Bool] = [
            "routeSupportsHdAudio": false,
            "canDecodeAc3": true,
            "canDecodeEac3": true,
            "canDecodeDts": true,
            "canDecodeDtsHd": true,
            "canDecodeTrueHd": true,
            "canDecodeFlac": true,
            "canPassthroughAc3": false,
            "canPassthroughEac3": false,
            "canPassthroughDts": false,
            "canPassthroughDtsHd": false,
            "canPassthroughTrueHd": false,
        ]
        XCTAssertEqual(map.count, 14)
        XCTAssertEqual(map["activeRouteType"] as? String, "bluetooth")
        XCTAssertEqual(map["maxPcmChannels"] as? Int, 8)
        for (key, expected) in expectedBools {
            XCTAssertEqual(map[key] as? Bool, expected, key)
        }
    }
}
