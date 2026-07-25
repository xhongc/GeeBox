import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../widgets/forui_components.dart';

class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChansonScaffold(
      title: '浏览音乐',
      onBack: () => context.go('/'),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ChansonSection(
            title: '资料库',
            children: [
              ChansonTile(
                icon: FLucideIcons.disc3,
                title: '专辑',
                subtitle: '浏览所有专辑',
                onPress: () {},
              ),
              ChansonTile(
                icon: FLucideIcons.userRound,
                title: '艺术家',
                subtitle: '浏览所有艺术家',
                onPress: () => context.push('/artists'),
              ),
              ChansonTile(
                icon: FLucideIcons.listMusic,
                title: '播放列表',
                subtitle: '查看您的播放列表',
                onPress: () {},
              ),
              ChansonTile(
                icon: FLucideIcons.heart,
                title: '收藏',
                subtitle: '您收藏的音乐',
                onPress: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
