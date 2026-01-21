import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '欢迎使用 Chanson',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('您的 Subsonic 音乐客户端'),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => context.go('/browse'),
              icon: const Icon(Icons.library_music),
              label: const Text('浏览音乐'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.go('/player'),
              icon: const Icon(Icons.play_circle),
              label: const Text('播放器'),
            ),
          ],
        ),
      ),
    );
  }
}
