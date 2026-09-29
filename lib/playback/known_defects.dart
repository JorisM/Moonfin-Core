import '../preference/preference_constants.dart';
import '../util/platform_detection.dart';
import 'audio_capability_profile.dart';

/// Which player is decoding. Not the same thing as the platform: the defect
/// below is AetherEngine's, and mpv plays the same file on the same route.
/// Deliberately distinct from `PlaybackEnginePreference`, which is Android's
/// user-facing engine choice.
enum PlaybackBackendKind { aether, mediaKit, media3, html }

class KnownDefects {
  const KnownDefects._();

  static const Set<String> modelsWithDoViHdr10PlusBug = <String>{
    'AFTKA', // Amazon Fire TV 4K Max (1st Gen)
    'AFTKM', // Amazon Fire TV 4K (2nd Gen)
    'AFTKRT', // Amazon Fire TV 4K Max (2nd Gen)
    'AFTMM', // Amazon Fire TV 4K (1st Gen)
    'BRAVIA 4K VH22',
  };

  static const Set<String> modelsWithDolbyVisionProfile7ElDirectPlayDefault =
      <String>{
        'AFTKRT',
      };

  static bool get hevcDoviHdr10PlusBug =>
      PlatformDetection.knownHevcDoviHdr10PlusBug ||
      modelHasHevcDoviHdr10PlusBug(PlatformDetection.deviceModel);

  static bool modelHasHevcDoviHdr10PlusBug(String? model) {
    if (model == null) {
      return false;
    }
    return modelsWithDoViHdr10PlusBug.contains(model.trim().toUpperCase());
  }

  static bool modelHasDolbyVisionProfile7ElDirectPlayDefault(String? model) {
    if (model == null) {
      return false;
    }
    return modelsWithDolbyVisionProfile7ElDirectPlayDefault.contains(
      model.trim().toUpperCase(),
    );
  }

  static bool shouldAllowDolbyVisionProfile7ElDirectPlay({
    required DolbyVisionProfile7DirectPlayBehavior behavior,
    String? model,
    bool hasHardwareDolbyVisionDecoder = false,
    bool hasDoviCompat = false,
  }) {
    switch (behavior) {
      case DolbyVisionProfile7DirectPlayBehavior.enabled:
        return true;
      case DolbyVisionProfile7DirectPlayBehavior.disabled:
        return false;
      case DolbyVisionProfile7DirectPlayBehavior.auto:
        // A device with a hardware Dolby Vision decoder can render the P7 base
        // layer, so allow it there even when the EL-specific probe is
        // inconclusive. A player with the DoVi compat chain rewrites or strips
        // the P7 metadata itself, so it always renders the base layer too.
        // Everything else stays gated (P7 transcodes).
        return PlatformDetection.isDesktop ||
            hasDoviCompat ||
            hasHardwareDolbyVisionDecoder ||
            modelHasDolbyVisionProfile7ElDirectPlayDefault(
              model ?? PlatformDetection.deviceModel,
            );
    }
  }

  /// Combinations observed to play as silence while the player reports normal
  /// playback. One row per observation, never per suspicion.
  ///
  /// AetherEngine renders EAC3 as silence on a Bluetooth route while the same
  /// track plays through wired output, and mpv plays it on the same route.
  /// Observed 2026-09-29: MacBook Pro M4 Pro + MacBook Air M4, macOS 26,
  /// AirPods Pro, Moonfin 2.6.0, EAC3 5.1 JOC.
  static const Map<PlaybackBackendKind, Map<AudioRouteType, Set<String>>>
  _silentDirectPlayCodecs = <PlaybackBackendKind, Map<AudioRouteType, Set<String>>>{
    PlaybackBackendKind.aether: <AudioRouteType, Set<String>>{
      AudioRouteType.bluetooth: <String>{'eac3'},
    },
  };

  /// Whether this player is known to render [codec] as silence on [route].
  /// `AudioRouteType.other` means the route was never resolved, which is a
  /// "say nothing" answer rather than a match.
  static bool rendersSilently({
    required PlaybackBackendKind backend,
    required AudioRouteType route,
    required String codec,
  }) {
    if (route == AudioRouteType.other) return false;
    final routes = _silentDirectPlayCodecs[backend];
    if (routes == null) return false;
    return routes[route]?.contains(codec.trim().toLowerCase()) ?? false;
  }
}
