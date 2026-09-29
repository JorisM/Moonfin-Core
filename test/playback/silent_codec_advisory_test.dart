import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/playback/audio_capability_profile.dart';
import 'package:moonfin/playback/known_defects.dart';
import 'package:moonfin/playback/silent_codec_advisory.dart';

SilentCodecAdvisoryInputs inputs({
  PlaybackBackendKind backend = PlaybackBackendKind.aether,
  bool isDirectPlaying = true,
  bool localDecodeEnabled = true,
  bool dismissed = false,
  bool isRemotePlayback = false,
  bool isExternalPlayer = false,
  bool isOffline = false,
  AudioRouteType route = AudioRouteType.bluetooth,
  String codec = 'eac3',
}) => SilentCodecAdvisoryInputs(
  backend: backend,
  route: route,
  codec: codec,
  isDirectPlayingAudio: isDirectPlaying,
  localDecodeEnabledForCodec: localDecodeEnabled,
  alreadyDismissed: dismissed,
  isRemotePlayback: isRemotePlayback,
  isExternalPlayer: isExternalPlayer,
  isOfflinePlayback: isOffline,
);

void main() {
  test('offers on a known-bad combination during direct play', () {
    expect(SilentCodecAdvisory.shouldOffer(inputs()), isTrue);
  });

  test('stays silent when the server already transcodes the audio', () {
    expect(
      SilentCodecAdvisory.shouldOffer(inputs(isDirectPlaying: false)),
      isFalse,
    );
  });

  test('stays silent when the user already turned local decoding off', () {
    expect(
      SilentCodecAdvisory.shouldOffer(inputs(localDecodeEnabled: false)),
      isFalse,
    );
  });

  test('stays silent once dismissed for this combination', () {
    expect(SilentCodecAdvisory.shouldOffer(inputs(dismissed: true)), isFalse);
  });

  test('stays silent while casting', () {
    expect(
      SilentCodecAdvisory.shouldOffer(inputs(isRemotePlayback: true)),
      isFalse,
    );
  });

  test('stays silent on an external player', () {
    expect(
      SilentCodecAdvisory.shouldOffer(inputs(isExternalPlayer: true)),
      isFalse,
    );
  });

  test('stays silent offline', () {
    expect(SilentCodecAdvisory.shouldOffer(inputs(isOffline: true)), isFalse);
  });

  test('stays silent on a route that never resolved', () {
    expect(
      SilentCodecAdvisory.shouldOffer(inputs(route: AudioRouteType.other)),
      isFalse,
    );
  });

  test('stays silent for a codec with no recorded defect', () {
    expect(SilentCodecAdvisory.shouldOffer(inputs(codec: 'aac')), isFalse);
  });

  test('backend variation changes advisory decision', () {
    // mediaKit plays eac3 on bluetooth fine, unlike aether
    expect(
      SilentCodecAdvisory.shouldOffer(
        inputs(backend: PlaybackBackendKind.mediaKit),
      ),
      isFalse,
    );
  });

  test('dismissal keys normalise codec and distinguish backend, route', () {
    expect(
      SilentCodecAdvisory.dismissalKey(
        backend: PlaybackBackendKind.aether,
        route: AudioRouteType.bluetooth,
        codec: 'eac3',
      ),
      'aether:bluetooth:eac3',
    );

    // Codec normalisation: spaces and case
    expect(
      SilentCodecAdvisory.dismissalKey(
        backend: PlaybackBackendKind.aether,
        route: AudioRouteType.bluetooth,
        codec: ' EAC3 ',
      ),
      'aether:bluetooth:eac3',
    );

    // Different backend produces different key
    expect(
      SilentCodecAdvisory.dismissalKey(
        backend: PlaybackBackendKind.mediaKit,
        route: AudioRouteType.bluetooth,
        codec: 'eac3',
      ),
      'mediaKit:bluetooth:eac3',
    );

    // Different route produces different key
    expect(
      SilentCodecAdvisory.dismissalKey(
        backend: PlaybackBackendKind.aether,
        route: AudioRouteType.speaker,
        codec: 'eac3',
      ),
      'aether:speaker:eac3',
    );
  });
}
