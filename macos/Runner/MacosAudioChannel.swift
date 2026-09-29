import CoreAudio
import FlutterMacOS
import Foundation

/// Pure mapping half, so the transport table is testable without CoreAudio,
/// a window or a Flutter engine.
enum MacosAudioRoute {
    /// macOS reports a transport, not a speaker. Anything unrecognised is
    /// `other`, which the Dart side treats as "say nothing".
    static func routeName(forTransportType transport: UInt32) -> String {
        switch transport {
        case kAudioDeviceTransportTypeBluetooth, kAudioDeviceTransportTypeBluetoothLE:
            return "bluetooth"
        case kAudioDeviceTransportTypeBuiltIn:
            return "speaker"
        case kAudioDeviceTransportTypeHDMI, kAudioDeviceTransportTypeDisplayPort:
            return "hdmi"
        case kAudioDeviceTransportTypeUSB, kAudioDeviceTransportTypeFireWire,
             kAudioDeviceTransportTypeThunderbolt, kAudioDeviceTransportTypePCI:
            return "headphones"
        default:
            return "other"
        }
    }

    /// `AudioCapabilityProfile.optimistic()` with only the route filled in.
    /// macOS had no probe before, so any other difference changes behaviour for
    /// every Mac user. `maxPcmChannels` must stay 8: a value <= 2 flips
    /// `forceStereo` in the device-profile builder.
    static func capabilities(routeName: String) -> [String: Any] {
        return [
            "activeRouteType": routeName,
            "maxPcmChannels": 8,
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
    }

    /// Transport of the default output device, or `other` when CoreAudio has
    /// no device or refuses the query.
    static func currentRouteName() -> String {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID) == noErr,
            deviceID != kAudioObjectUnknown
        else { return "other" }

        var transport = UInt32(0)
        var transportSize = UInt32(MemoryLayout<UInt32>.size)
        var transportAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        guard AudioObjectGetPropertyData(
            deviceID, &transportAddress, 0, nil, &transportSize, &transport) == noErr
        else { return "other" }

        return routeName(forTransportType: transport)
    }
}

/// Method channel `moonfin/macos_audio` (method `audioCapabilities`) +
/// event channel `moonfin/macos_audio_events` (pushes on default-device change).
/// Mirrors `tvos/Runner/AppleTvAudioChannel.swift`.
final class MacosAudioChannel: NSObject, FlutterStreamHandler {
    private let methodChannel: FlutterMethodChannel
    private let eventChannel: FlutterEventChannel
    private var eventSink: FlutterEventSink?
    private var listener: AudioObjectPropertyListenerBlock?

    private var defaultDeviceAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain)

    init(messenger: FlutterBinaryMessenger) {
        methodChannel = FlutterMethodChannel(
            name: "moonfin/macos_audio", binaryMessenger: messenger)
        eventChannel = FlutterEventChannel(
            name: "moonfin/macos_audio_events", binaryMessenger: messenger)
        super.init()
        methodChannel.setMethodCallHandler { call, result in
            guard call.method == "audioCapabilities" else {
                result(FlutterMethodNotImplemented)
                return
            }
            result(MacosAudioRoute.capabilities(routeName: MacosAudioRoute.currentRouteName()))
        }
        eventChannel.setStreamHandler(self)
    }

    func onListen(
        withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        eventSink = events
        guard listener == nil else { return nil }
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            guard let sink = self?.eventSink else { return }
            sink(MacosAudioRoute.capabilities(routeName: MacosAudioRoute.currentRouteName()))
        }
        let status = AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject), &defaultDeviceAddress, DispatchQueue.main, block)
        if status == noErr { listener = block }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        if let block = listener {
            AudioObjectRemovePropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject), &defaultDeviceAddress, DispatchQueue.main, block)
            listener = nil
        }
        eventSink = nil
        return nil
    }
}
