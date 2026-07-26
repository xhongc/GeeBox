import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../providers/subsonic_provider.dart';
import '../widgets/forui_components.dart';
import '../widgets/listener_components.dart';

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
    return FScaffold(
      childPad: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: ListenerGradients.shell),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _ConfigHero(),
                const SizedBox(height: 26),
                _ConfigFormCard(
                  serverUrlController: _serverUrlController,
                  usernameController: _usernameController,
                  passwordController: _passwordController,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _ConfigError(message: _errorMessage!),
                ],
                const SizedBox(height: 22),
                FButton(
                  onPress: _isLoading ? null : _testConnection,
                  prefix: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: FCircularProgress(),
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
        ),
      ),
    );
  }
}

class _ConfigHero extends StatelessWidget {
  const _ConfigHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Server',
          style: TextStyle(
            color: ListenerColors.muted,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '服务器配置',
          style: TextStyle(
            color: ListenerColors.foreground,
            fontSize: 34,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                const Color(0xFFBFDBFE).withValues(alpha: 0.38),
                Colors.white.withValues(alpha: 0.86),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: ListenerShadows.soft,
          ),
          child: const Row(
            children: [
              SizedBox.square(
                dimension: 58,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: ListenerColors.foreground,
                    borderRadius: BorderRadius.all(Radius.circular(21)),
                  ),
                  child: Icon(
                    FLucideIcons.serverCog,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '配置 Subsonic 服务器',
                      style: TextStyle(
                        color: ListenerColors.foreground,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '请输入服务器地址、用户名和密码，连接成功后会进入 Listener 音乐界面。',
                      style: TextStyle(
                        color: ListenerColors.softText,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfigFormCard extends StatelessWidget {
  final TextEditingController serverUrlController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;

  const _ConfigFormCard({
    required this.serverUrlController,
    required this.usernameController,
    required this.passwordController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(26),
        boxShadow: ListenerShadows.soft,
      ),
      child: Column(
        children: [
          FTextField(
            control: FTextFieldControl.managed(controller: serverUrlController),
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
            control: FTextFieldControl.managed(controller: usernameController),
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
            control: FTextFieldControl.managed(controller: passwordController),
            label: const Text('密码'),
          ),
        ],
      ),
    );
  }
}

class _ConfigError extends StatelessWidget {
  final String message;

  const _ConfigError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            FLucideIcons.triangleAlert,
            color: Color(0xFFDC2626),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
