import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../exceptions/subsonic_exceptions.dart';
import 'forui_components.dart';

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
              color: context.theme.colors.destructive,
            ),
            const SizedBox(height: 16),
            ChansonAlert(
              title: title,
              message: customMessage ?? message,
              variant: FAlertVariant.destructive,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FButton(
                onPress: onRetry,
                prefix: const Icon(FLucideIcons.refreshCw),
                child: const Text('重试'),
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
        FLucideIcons.wifiOff,
        '网络错误',
        error.toString(),
      );
    } else if (error is AuthenticationException) {
      return (
        FLucideIcons.lock,
        '认证失败',
        '用户名或密码错误，请重新登录',
      );
    } else if (error is NotConfiguredException) {
      return (
        FLucideIcons.settings,
        '未配置服务器',
        '请先配置服务器连接信息',
      );
    } else if (error is ServerException) {
      final serverError = error as ServerException;
      return (
        FLucideIcons.serverCrash,
        '服务器错误',
        '错误代码: ${serverError.statusCode}\n${serverError.message}',
      );
    } else if (error is ParseException) {
      return (
        FLucideIcons.triangleAlert,
        '数据解析失败',
        error.toString(),
      );
    }

    return (
      FLucideIcons.circleAlert,
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
