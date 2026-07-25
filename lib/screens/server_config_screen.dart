import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../providers/subsonic_provider.dart';
import '../widgets/forui_components.dart';

class ServerConfigScreen extends ConsumerStatefulWidget {
  const ServerConfigScreen({super.key});

  @override
  ConsumerState<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends ConsumerState<ServerConfigScreen> {
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  void _loadSavedConfig() {
    final settingsBox = Hive.box('settings');
    _serverUrlController.text = settingsBox.get('serverUrl', defaultValue: '');
    _usernameController.text = settingsBox.get('username', defaultValue: '');
    _passwordController.text = settingsBox.get('password', defaultValue: '');
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final validationError = _validateConfig();
    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final subsonicService = ref.read(subsonicServiceProvider);
      final serverUrl = _serverUrlController.text.trim();
      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      subsonicService.configure(
        serverUrl: serverUrl,
        username: username,
        password: password,
      );

      final success = await subsonicService.ping();

      if (mounted) {
        if (success) {
          // 保存配置
          final settingsBox = Hive.box('settings');
          await settingsBox.put('serverUrl', serverUrl);
          await settingsBox.put('username', username);
          await settingsBox.put('password', password);
          await settingsBox.put('skip_config', false);

          // 更新 Provider
          ref.read(serverConfigProvider.notifier).state = ServerConfig(
            serverUrl: serverUrl,
            username: username,
            password: password,
          );

          if (mounted) {
            showChansonToast(context, '连接成功！');
            context.go('/');
          }
        } else {
          setState(() {
            _errorMessage = '连接失败，请检查服务器地址和凭据';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = '连接错误: $e';

        // 检测是否是 Web 平台的 CORS 错误
        if (e.toString().contains('XMLHttpRequest') ||
            e.toString().contains('CORS') ||
            e.toString().contains('network layer')) {
          errorMsg = 'Web 平台 CORS 限制\n\n'
              '建议使用桌面应用运行：\n'
              'flutter run -d macos\n\n'
              '或配置服务器支持 CORS';
        }

        setState(() {
          _errorMessage = errorMsg;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateConfig() {
    final serverUrl = _serverUrlController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (serverUrl.isEmpty) {
      return '请输入服务器地址';
    }
    if (!serverUrl.startsWith('http://') && !serverUrl.startsWith('https://')) {
      return '服务器地址必须以 http:// 或 https:// 开头';
    }
    if (username.isEmpty) {
      return '请输入用户名';
    }
    if (password.isEmpty) {
      return '请输入密码';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return ChansonScaffold(
      title: '服务器配置',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              FLucideIcons.serverCog,
              size: 64,
              color: theme.colors.primary,
            ),
            const SizedBox(height: 24),
            Text(
              '配置 Subsonic 服务器',
              style: theme.typography.body.xl2.copyWith(
                color: theme.colors.foreground,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '请输入您的 Subsonic 服务器信息',
              style: theme.typography.body.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    FTextField(
                      control: FTextFieldControl.managed(
                          controller: _serverUrlController),
                      label: const Text('服务器地址'),
                      hint: 'https://demo.subsonic.org',
                      keyboardType: TextInputType.url,
                      prefixBuilder: (context, style, variants) =>
                          FTextField.prefixIconBuilder(
                        context,
                        style,
                        variants,
                        const Icon(FLucideIcons.link),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FTextField(
                      control: FTextFieldControl.managed(
                          controller: _usernameController),
                      label: const Text('用户名'),
                      prefixBuilder: (context, style, variants) =>
                          FTextField.prefixIconBuilder(
                        context,
                        style,
                        variants,
                        const Icon(FLucideIcons.userRound),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FTextField.password(
                      control: FTextFieldControl.managed(
                          controller: _passwordController),
                      label: const Text('密码'),
                    ),
                  ],
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              ChansonAlert(
                title: '连接失败',
                message: _errorMessage!,
                variant: FAlertVariant.destructive,
              ),
            ],
            const SizedBox(height: 24),
            FButton(
              onPress: _isLoading ? null : _testConnection,
              prefix: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(FLucideIcons.plugZap),
              child: const Text('测试连接'),
            ),
            const SizedBox(height: 12),
            FButton(
              variant: FButtonVariant.ghost,
              onPress: () async {
                final settingsBox = Hive.box('settings');
                await settingsBox.put('skip_config', true);
                if (!context.mounted) return;
                context.go('/');
              },
              child: const Text('跳过'),
            ),
          ],
        ),
      ),
    );
  }
}
