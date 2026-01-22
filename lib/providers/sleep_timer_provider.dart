import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sleep_timer_service.dart';

class SleepTimerState {
  final bool isRunning;
  final DateTime? endTime;

  const SleepTimerState({
    required this.isRunning,
    required this.endTime,
  });

  const SleepTimerState.idle() : this(isRunning: false, endTime: null);

  SleepTimerState copyWith({
    bool? isRunning,
    DateTime? endTime,
  }) {
    return SleepTimerState(
      isRunning: isRunning ?? this.isRunning,
      endTime: endTime ?? this.endTime,
    );
  }

  Duration? get remaining {
    if (endTime == null) return null;
    final remaining = endTime!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

class SleepTimerController extends StateNotifier<SleepTimerState> {
  SleepTimerController(this._service) : super(const SleepTimerState.idle());

  final SleepTimerService _service;

  void setTimer(Duration duration, void Function() onTimerEnd) {
    _service.setTimer(duration, () {
      onTimerEnd();
      state = const SleepTimerState.idle();
    });
    state = state.copyWith(
      isRunning: true,
      endTime: DateTime.now().add(duration),
    );
  }

  void cancel() {
    _service.cancel();
    state = const SleepTimerState.idle();
  }
}

/// 睡眠定时器服务 Provider
final sleepTimerServiceProvider = Provider<SleepTimerService>((ref) {
  return SleepTimerService();
});

/// 睡眠定时器状态 Provider
final sleepTimerControllerProvider =
    StateNotifierProvider<SleepTimerController, SleepTimerState>((ref) {
  final service = ref.watch(sleepTimerServiceProvider);
  return SleepTimerController(service);
});
