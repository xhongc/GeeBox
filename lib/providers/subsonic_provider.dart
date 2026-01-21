import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/subsonic_service.dart';

// Subsonic 服务单例 Provider
final subsonicServiceProvider = Provider<SubsonicService>((ref) {
  return SubsonicService();
});

// 服务器配置状态 Provider
final serverConfigProvider = StateProvider<ServerConfig?>((ref) => null);

class ServerConfig {
  final String serverUrl;
  final String username;
  final String password;

  ServerConfig({
    required this.serverUrl,
    required this.username,
    required this.password,
  });
}
