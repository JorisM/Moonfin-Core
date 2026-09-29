import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';
import 'package:moonfin/playback/audio_capability_probe.dart';
import 'package:moonfin/playback/audio_capability_profile.dart';
import 'package:moonfin/preference/user_preferences.dart';
import 'package:moonfin/util/platform_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('moonfin/macos_audio');
  const events = MethodChannel('moonfin/macos_audio_events');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  // The same file MacosAudioRouteTests.swift loads, so neither side can drift
  // from the other or from optimistic() unnoticed.
  final fixture = jsonDecode(
    File('test_fixtures/macos_audio_capabilities.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  Map<String, Object?> nativeMap(String route) => <String, Object?>{
    'activeRouteType': route,
    ...fixture,
  };

  Future<void> emit(Map<String, Object?> payload) {
    return messenger.handlePlatformMessage(
      events.name,
      const StandardMethodCodec().encodeSuccessEnvelope(payload),
      (_) {},
    );
  }

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    PlatformDetection.setAudioCapabilities(null);
    AudioCapabilityProbe.resetForTesting();
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    PlatformDetection.setAudioCapabilities(null);
    AudioCapabilityProbe.resetForTesting();
    debugDefaultTargetPlatformOverride = null;
  });

  test('macOS exposes the probe', () {
    expect(AudioCapabilityProbe.isSupported, isTrue);
  });

  test('every fixture value equals the optimistic() value', () {
    final optimistic = const AudioCapabilityProfile.optimistic().toMap();
    for (final entry in fixture.entries) {
      expect(optimistic[entry.key], entry.value, reason: entry.key);
    }
  });

  for (final route in ['bluetooth', 'speaker', 'headphones', 'hdmi']) {
    test(
      'a $route route differs from the optimistic fallback only in the route',
      () async {
        messenger.setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'audioCapabilities');
          return nativeMap(route);
        });

        final probed = await AudioCapabilityProbe.query();
        const fallback = AudioCapabilityProfile.optimistic();

        expect(probed, isNotNull);
        expect(probed!.activeRouteType.name, route);
        // toMap() covers every field, so a field added later is compared too.
        final expected = fallback.toMap()..['activeRouteType'] = route;
        expect(probed.toMap(), expected);
        expect(probed.isDowngradeFrom(fallback), isFalse);
      },
    );
  }

  test('a probe failure leaves the fallback in place', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'unavailable');
    });
    expect(await AudioCapabilityProbe.query(), isNull);
  });

  test(
    'passthrough codecs resolve the same with and without the probe',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = PreferenceStore();
      await store.init();
      final prefs = UserPreferences(store);

      final without = prefs.resolvedPassthroughCodecs();

      messenger.setMockMethodCallHandler(channel, (call) async {
        return nativeMap('bluetooth');
      });
      AudioCapabilityProbe.apply(await AudioCapabilityProbe.query());
      expect(PlatformDetection.hasAudioCapabilities, isTrue);

      expect(prefs.resolvedPassthroughCodecs(), without);
    },
  );

  group('route events', () {
    test('a pushed route change reaches the snapshot', () async {
      AudioCapabilityProbe.apply(
        AudioCapabilityProfile.fromMap(nativeMap('bluetooth')),
      );
      AudioCapabilityProbe.listenForRouteChanges();

      await emit(nativeMap('speaker'));

      expect(
        PlatformDetection.audioCapabilitiesSnapshot['activeRouteType'],
        'speaker',
      );
    });

    test('hdmi to bluetooth lands without the downgrade delay', () async {
      AudioCapabilityProbe.apply(
        AudioCapabilityProfile.fromMap(nativeMap('hdmi')),
      );
      AudioCapabilityProbe.listenForRouteChanges();

      await emit(nativeMap('bluetooth'));

      expect(
        PlatformDetection.audioCapabilitiesSnapshot['activeRouteType'],
        'bluetooth',
      );
    });
  });
}
