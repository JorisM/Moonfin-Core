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
    }

    func testInternalPciMapsToSpeaker() {
        XCTAssertEqual(MacosAudioRoute.routeName(forTransportType: kAudioDeviceTransportTypePCI), "speaker")
    }

    func testUnknownTransportFallsThroughToOther() {
        XCTAssertEqual(MacosAudioRoute.routeName(forTransportType: kAudioDeviceTransportTypeUnknown), "other")
        XCTAssertEqual(MacosAudioRoute.routeName(forTransportType: 0x6d656f77), "other")
    }

    /// Shared with test/playback/audio_capability_probe_macos_test.dart, so the
    /// Swift map and the Dart-side `optimistic()` comparison cannot drift apart.
    func testCapabilityMapMatchesSharedFixtureExceptRoute() throws {
        let fixtureURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("test_fixtures/macos_audio_capabilities.json")
        let data = try Data(contentsOf: fixtureURL)
        let fixture = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: data) as? [String: Any])

        for route in ["bluetooth", "speaker", "headphones", "hdmi", "other"] {
            var map = MacosAudioRoute.capabilities(routeName: route)
            XCTAssertEqual(map.removeValue(forKey: "activeRouteType") as? String, route)
            XCTAssertEqual(NSDictionary(dictionary: map), NSDictionary(dictionary: fixture), route)
        }
    }
}
