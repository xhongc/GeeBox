import 'dart:async';

/// 睡眠定时器服务
class SleepTimerService {
  static final SleepTimerService _instance = SleepTimerService._internal();
  factory SleepTimerService() => _instance;
  SleepTimerService._internal();

  Timer? _timer;
  DateTime? _endTime;
  Function()? _onTimerEnd;

  /// 获取剩余时间
  Duration? get remainingTime {
    if (_endTime == null) return null;
    final remaining = _endTime!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// 是否正在运行
  bool get isRunning => _timer != null && _timer!.isActive;

  /// 设置定时器
  void setTimer(Duration duration, Function() onTimerEnd) {
    // 取消现有定时器
    cancel();

    _endTime = DateTime.now().add(duration);
    _onTimerEnd = onTimerEnd;

    _timer = Timer(duration, () {
      _onTimerEnd?.call();
      _endTime = null;
      _onTimerEnd = null;
    });
  }

  /// 取消定时器
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _endTime = null;
    _onTimerEnd = null;
  }

  /// 释放资源
  void dispose() {
    cancel();
  }
}
