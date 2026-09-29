import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/playback/audio_capability_probe.dart';
import 'package:moonfin/playback/audio_capability_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('moonfin/macos_audio');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.macOS);
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('macOS exposes the probe', () {
    expect(AudioCapabilityProbe.isSupported, isTrue);
  });

  test('a bluetooth route differs from the optimistic fallback only in the route',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'audioCapabilities');
      return <String, Object>{
        'activeRouteType': 'bluetooth',
        'maxPcmChannels': 8,
        'routeSupportsHdAudio': false,
        'canDecodeAc3': true,
        'canDecodeEac3': true,
        'canDecodeDts': true,
        'canDecodeDtsHd': true,
        'canDecodeTrueHd': true,
        'canDecodeFlac': true,
        'canPassthroughAc3': false,
        'canPassthroughEac3': false,
        'canPassthroughDts': false,
        'canPassthroughDtsHd': false,
        'canPassthroughTrueHd': false,
      };
    });

    final probed = await AudioCapabilityProbe.query();
    const fallback = AudioCapabilityProfile.optimistic();

    expect(probed, isNotNull);
    expect(probed!.activeRouteType, AudioRouteType.bluetooth);
    expect(probed.maxPcmChannels, fallback.maxPcmChannels);
    expect(probed.canDecodeEac3, fallback.canDecodeEac3);
    expect(probed.canDecodeTrueHd, fallback.canDecodeTrueHd);
    expect(probed.canPassthroughEac3, fallback.canPassthroughEac3);
    expect(probed.routeSupportsHdAudio, fallback.routeSupportsHdAudio);
    expect(probed.isDowngradeFrom(fallback), isFalse);
  });

  test('a probe failure leaves the fallback in place', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'unavailable');
    });
    expect(await AudioCapabilityProbe.query(), isNull);
  });
}
