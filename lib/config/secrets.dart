/// API keys. Empty by default — supply your own via
/// `flutter run --dart-define-from-file=dart_defines.local.json`
/// (copy dart_defines.example.json). Every service reads
/// String.fromEnvironment('X', defaultValue: Secrets.x).
///
/// Free keys: YouVersion Platform (https://developers.youversion.com)
/// and Gloo AI Studio (https://studio.ai.gloo.com).
abstract class Secrets {
  static const youVersionKey = '';
  static const glooClientId = '';
  static const glooClientSecret = '';
  static const agoraAppId = '';
  static const foldrApiKey = '';
}
