import 'audio_capability_profile.dart';
import 'known_defects.dart';

/// Everything the advisory decision reads, gathered by the caller so the
/// decision itself stays pure and testable without a player.
class SilentCodecAdvisoryInputs {
  const SilentCodecAdvisoryInputs({
    required this.backend,
    required this.route,
    required this.codec,
    required this.isDirectPlayingAudio,
    required this.localDecodeEnabledForCodec,
    required this.alreadyDismissed,
    required this.isRemotePlayback,
    required this.isExternalPlayer,
    required this.isOfflinePlayback,
  });

  final PlaybackBackendKind backend;
  final AudioRouteType route;
  final String codec;

  /// The server is sending this codec untouched. When it already transcodes,
  /// there is nothing to offer.
  final bool isDirectPlayingAudio;
  final bool localDecodeEnabledForCodec;
  final bool alreadyDismissed;

  /// The local output route describes this machine, which says nothing about
  /// a Cast receiver or an external player, and an offline file has no server
  /// to ask for a transcode.
  final bool isRemotePlayback;
  final bool isExternalPlayer;
  final bool isOfflinePlayback;
}

class SilentCodecAdvisory {
  const SilentCodecAdvisory._();

  static bool shouldOffer(SilentCodecAdvisoryInputs i) {
    if (i.isRemotePlayback || i.isExternalPlayer || i.isOfflinePlayback) {
      return false;
    }
    if (!i.isDirectPlayingAudio) return false;
    if (!i.localDecodeEnabledForCodec) return false;
    if (i.alreadyDismissed) return false;
    return KnownDefects.rendersSilently(
      backend: i.backend,
      route: i.route,
      codec: i.codec,
    );
  }

  static String dismissalKey({
    required PlaybackBackendKind backend,
    required AudioRouteType route,
    required String codec,
  }) => '${backend.name}:${route.name}:${codec.trim().toLowerCase()}';
}
