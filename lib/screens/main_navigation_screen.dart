import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../providers/navigation_provider.dart';
import 'home_screen.dart';
import 'albums_screen.dart';
import 'favorites_screen.dart';
import 'play_queue_screen.dart';
import 'player_screen.dart';
import '../widgets/mini_player.dart';
import '../widgets/listener_components.dart';

/// 主导航页面 - 底部导航栏
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  final List<Widget> _screens = const [
    HomeScreen(),
    AlbumsScreen(embedded: true),
    PlayQueueScreen(),
    FavoritesScreen(),
  ];

  void _openPlayer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PlayerScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(mainNavigationIndexProvider);

    return FScaffold(
      childPad: false,
      child: ListenerPageBackground(
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 184),
                child: IndexedStack(
                  index: currentIndex,
                  children: _screens,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ListenerDock(
                index: currentIndex,
                onChange: (index) {
                  ref.read(mainNavigationIndexProvider.notifier).state = index;
                },
                onPlayerTap: _openPlayer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListenerDock extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChange;
  final VoidCallback onPlayerTap;

  const _ListenerDock({
    required this.index,
    required this.onChange,
    required this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0x00F7F6F3),
            const Color(0xF5F7F6F3).withValues(alpha: 0.96),
            const Color(0xFFF7F6F3),
          ],
          stops: const [0, 0.28, 1],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, bottom + 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MiniPlayer(onTap: onPlayerTap),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: ListenerColors.dock,
                borderRadius: BorderRadius.circular(23),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                    blurRadius: 36,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _ListenerDockItem(
                    active: index == 0,
                    icon: FLucideIcons.compass,
                    label: '首页',
                    onPress: () => onChange(0),
                  ),
                  _ListenerDockItem(
                    active: index == 1,
                    icon: FLucideIcons.disc3,
                    label: '专辑',
                    onPress: () => onChange(1),
                  ),
                  _ListenerDockItem(
                    active: index == 2,
                    icon: FLucideIcons.play,
                    label: '播放',
                    onPress: () => onChange(2),
                  ),
                  _ListenerDockItem(
                    active: index == 3,
                    icon: FLucideIcons.heart,
                    label: '喜爱',
                    onPress: () => onChange(3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListenerDockItem extends StatelessWidget {
  final bool active;
  final IconData icon;
  final String label;
  final VoidCallback onPress;

  const _ListenerDockItem({
    required this.active,
    required this.icon,
    required this.label,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FTappable(
        onPress: onPress,
        builder: (context, states, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: active ? ListenerColors.foreground : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color:
                            ListenerColors.foreground.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: active ? Colors.white : ListenerColors.softText,
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? Colors.white : ListenerColors.softText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
