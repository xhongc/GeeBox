import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'artists_screen.dart';

class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('浏览音乐'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCategoryCard(
            context,
            icon: Icons.album,
            title: '专辑',
            subtitle: '浏览所有专辑',
            onTap: () {
              // TODO: 导航到专辑列表
            },
          ),
          const SizedBox(height: 12),
          _buildCategoryCard(
            context,
            icon: Icons.person,
            title: '艺术家',
            subtitle: '浏览所有艺术家',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ArtistsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildCategoryCard(
            context,
            icon: Icons.playlist_play,
            title: '播放列表',
            subtitle: '查看您的播放列表',
            onTap: () {
              // TODO: 导航到播放列表
            },
          ),
          const SizedBox(height: 12),
          _buildCategoryCard(
            context,
            icon: Icons.favorite,
            title: '收藏',
            subtitle: '您收藏的音乐',
            onTap: () {
              // TODO: 导航到收藏列表
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
