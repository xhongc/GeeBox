import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sleep_timer_service.dart';

/// 睡眠定时器服务 Provider
final sleepTimerServiceProvider = Provider<SleepTimerService>((ref) {
  return SleepTimerService();
});

/// 定时器状态 Provider（用于触发 UI 更新）
final sleepTimerStateProvider = StateProvider<int>((ref) => 0);
