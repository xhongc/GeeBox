/// Subsonic API 异常基类
sealed class SubsonicException implements Exception {
  final String message;

  SubsonicException(this.message);

  @override
  String toString() => message;
}

/// 网络异常（连接超时、网络不可用等）
class NetworkException extends SubsonicException {
  NetworkException(super.message);
}

/// 认证异常（用户名密码错误、token 过期等）
class AuthenticationException extends SubsonicException {
  AuthenticationException(super.message);
}

/// 服务器异常（服务器返回错误状态）
class ServerException extends SubsonicException {
  final int statusCode;

  ServerException(this.statusCode, super.message);

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// 未配置异常（服务器未配置）
class NotConfiguredException extends SubsonicException {
  NotConfiguredException() : super('服务器未配置，请先配置服务器连接信息');
}

/// 数据解析异常
class ParseException extends SubsonicException {
  ParseException(super.message);
}
