import 'package:flutter/material.dart';
import '../exceptions/subsonic_exceptions.dart';

/// 通用错误展示 Widget
class ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final String? customMessage;

  const ErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, title, message) = _getErrorInfo();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              customMessage ?? message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (IconData, String, String) _getErrorInfo() {
    if (error is NetworkException) {
      return (
        Icons.wifi_off,
        '网络错误',
        error.toString(),
      );
    } else if (error is AuthenticationException) {
      return (
        Icons.lock_outline,
        '认证失败',
        '用户名或密码错误，请重新登录',
      );
    } else if (error is NotConfiguredException) {
      return (
        Icons.settings_outlined,
        '未配置服务器',
        '请先配置服务器连接信息',
      );
    } else if (error is ServerException) {
      final serverError = error as ServerException;
      return (
        Icons.error_outline,
        '服务器错误',
        '错误代码: ${serverError.statusCode}\n${serverError.message}',
      );
    } else if (error is ParseException) {
      return (
        Icons.warning_outlined,
        '数据解析失败',
        error.toString(),
      );
    }

    return (
      Icons.error_outline,
      '未知错误',
      error.toString(),
    );
  }
}

/// AsyncValue 错误处理扩展
extension AsyncValueErrorHandling on Object {
  Widget toErrorWidget({VoidCallback? onRetry, String? customMessage}) {
    return ErrorView(
      error: this,
      onRetry: onRetry,
      customMessage: customMessage,
    );
  }
}
