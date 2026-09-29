import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/playback/audio_capability_profile.dart';
import 'package:moonfin/playback/known_defects.dart';

void main() {
  test('EAC3 on a bluetooth route under Aether is a known defect', () {
    expect(
      KnownDefects.rendersSilently(
        backend: PlaybackBackendKind.aether,
        route: AudioRouteType.bluetooth,
        codec: 'eac3',
      ),
      isTrue,
    );
  });

  test('the same codec and route under mpv is not', () {
    // mpv-based clients play the file on the same Mac and the same AirPods.
    expect(
      KnownDefects.rendersSilently(
        backend: PlaybackBackendKind.mediaKit,
        route: AudioRouteType.bluetooth,
        codec: 'eac3',
      ),
      isFalse,
    );
  });

  test('another codec on the same route is not', () {
    expect(
      KnownDefects.rendersSilently(
        backend: PlaybackBackendKind.aether,
        route: AudioRouteType.bluetooth,
        codec: 'aac',
      ),
      isFalse,
    );
  });

  test('the same codec on a wired route is not', () {
    expect(
      KnownDefects.rendersSilently(
        backend: PlaybackBackendKind.aether,
        route: AudioRouteType.headphones,
        codec: 'eac3',
      ),
      isFalse,
    );
  });

  test('the same codec on an HDMI route is not', () {
    expect(
      KnownDefects.rendersSilently(
        backend: PlaybackBackendKind.aether,
        route: AudioRouteType.hdmi,
        codec: 'eac3',
      ),
      isFalse,
    );
  });

  test('an unresolved route never matches', () {
    expect(
      KnownDefects.rendersSilently(
        backend: PlaybackBackendKind.aether,
        route: AudioRouteType.other,
        codec: 'eac3',
      ),
      isFalse,
    );
  });

  test('codec matching ignores case', () {
    expect(
      KnownDefects.rendersSilently(
        backend: PlaybackBackendKind.aether,
        route: AudioRouteType.bluetooth,
        codec: 'EAC3',
      ),
      isTrue,
    );
  });

  test('codec matching trims leading and trailing spaces', () {
    expect(
      KnownDefects.rendersSilently(
        backend: PlaybackBackendKind.aether,
        route: AudioRouteType.bluetooth,
        codec: '  eac3 ',
      ),
      isTrue,
    );
  });

  test('codec matching trims spaces and newlines', () {
    expect(
      KnownDefects.rendersSilently(
        backend: PlaybackBackendKind.aether,
        route: AudioRouteType.bluetooth,
        codec: ' EAC3\n',
      ),
      isTrue,
    );
  });
}
