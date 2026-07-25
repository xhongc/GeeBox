import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'home_screen.dart';
import 'discover_screen.dart';
import 'library_screen.dart';
import 'player_screen.dart';
import '../widgets/mini_player.dart';

/// 主导航页面 - 底部导航栏
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    DiscoverScreen(),
    LibraryScreen(),
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
    return FScaffold(
      childPad: false,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniPlayer(onTap: _openPlayer),
          FBottomNavigationBar(
            index: _currentIndex,
            safeAreaBottom: true,
            onChange: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: const [
              FBottomNavigationBarItem(
                icon: Icon(FLucideIcons.house),
                label: Text('首页'),
              ),
              FBottomNavigationBarItem(
                icon: Icon(FLucideIcons.compass),
                label: Text('发现'),
              ),
              FBottomNavigationBarItem(
                icon: Icon(FLucideIcons.library),
                label: Text('我的音乐'),
              ),
            ],
          ),
        ],
      ),
      child: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
    );
  }
}
