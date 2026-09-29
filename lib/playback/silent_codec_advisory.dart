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

/// Decides whether to offer the user a server-side transcode because the
/// current backend, output route and codec are known to play as silence.
class SilentCodecAdvisory {
  const SilentCodecAdvisory._();

  /// True only when the local output is what plays the audio, the server is
  /// sending the codec untouched, the user has not opted out of local decode
  /// or dismissed this combination, and [KnownDefects] lists it as silent.
  static bool shouldOffer(SilentCodecAdvisoryInputs inputs) {
    if (inputs.isRemotePlayback ||
        inputs.isExternalPlayer ||
        inputs.isOfflinePlayback) {
      return false;
    }
    if (!inputs.isDirectPlayingAudio) return false;
    if (!inputs.localDecodeEnabledForCodec) return false;
    if (inputs.alreadyDismissed) return false;
    return KnownDefects.rendersSilently(
      backend: inputs.backend,
      route: inputs.route,
      codec: inputs.codec,
    );
  }

  /// Storage key for a dismissal. The enum names are a persisted format:
  /// renaming an enum value invalidates every stored dismissal.
  static String dismissalKey({
    required PlaybackBackendKind backend,
    required AudioRouteType route,
    required String codec,
  }) => '${backend.name}:${route.name}:${codec.trim().toLowerCase()}';
}
