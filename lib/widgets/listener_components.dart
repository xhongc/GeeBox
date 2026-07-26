import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../models/album.dart';
import '../models/artist.dart';
import '../models/song.dart';

class ListenerColors {
  static const foreground = Color(0xFF111827);
  static const muted = Color(0xFF94A3B8);
  static const softText = Color(0xFF64748B);
  static const card = Color(0xCCFFFFFF);
  static const dock = Color(0xD6FFFFFF);
}

class ListenerGradients {
  static const shell = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF7F6F3),
      Color(0xFFEEF3FF),
      Color(0xFFF7F7F7),
    ],
    stops: [0, 0.46, 1],
  );

  static const darkPlayer = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xF5121212),
      Color(0xEB2A2A2A),
    ],
  );
}

class ListenerShadows {
  static final soft = [
    BoxShadow(
      color: const Color(0xFF94A3B8).withValues(alpha: 0.12),
      blurRadius: 26,
      offset: const Offset(0, 12),
    ),
  ];

  static final elevated = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.18),
      blurRadius: 32,
      offset: const Offset(0, 16),
    ),
  ];
}

class ListenerPageBackground extends StatelessWidget {
  final Widget child;
  final bool dramatic;

  const ListenerPageBackground({
    super.key,
    required this.child,
    this.dramatic = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: ListenerGradients.shell),
      child: Stack(
        children: [
          Positioned(
            top: dramatic ? -120 : -112,
            right: dramatic ? -96 : -80,
            child: _ListenerBlurredGlow(
              color:
                  dramatic ? const Color(0x3B111827) : const Color(0x2E3B82F6),
              size: dramatic ? 250 : 224,
              radius: dramatic ? 72 : 48,
              blur: dramatic ? 34 : 24,
            ),
          ),
          Positioned(
            left: dramatic ? -92 : -80,
            bottom: dramatic ? 120 : 80,
            child: _ListenerBlurredGlow(
              color:
                  dramatic ? const Color(0x3AE11D48) : const Color(0x24F472B6),
              size: dramatic ? 230 : 208,
              radius: 999,
              blur: dramatic ? 42 : 24,
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _ListenerBlurredGlow extends StatelessWidget {
  final Color color;
  final double size;
  final double radius;
  final double blur;

  const _ListenerBlurredGlow({
    required this.color,
    required this.size,
    required this.radius,
    required this.blur,
  });

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class ListenerCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPress;

  const ListenerCircleButton({
    super.key,
    required this.icon,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return FTappable(
      onPress: onPress,
      builder: (context, states, child) {
        return AnimatedScale(
          scale: states.contains(FTappableVariant.pressed) ? 0.96 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF94A3B8).withValues(alpha: 0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(icon, color: ListenerColors.foreground, size: 20),
          ),
        );
      },
    );
  }
}

class ListenerCoverArt extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;
  final double borderRadius;

  const ListenerCoverArt({
    super.key,
    this.imageUrl,
    this.fallbackIcon = FLucideIcons.music,
    this.borderRadius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final imageProvider =
        imageUrl == null || imageUrl!.isEmpty ? null : NetworkImage(imageUrl!);

    Widget fallback() => DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE2E8F0), Color(0xFFF8FAFC)],
            ),
          ),
          child: Center(
            child: Icon(fallbackIcon, color: ListenerColors.muted),
          ),
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: imageProvider == null
          ? fallback()
          : Image(
              key: ValueKey(imageUrl),
              image: imageProvider,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallback(),
            ),
    );
  }
}

class ListenerPlayingArtCard extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;
  final double borderRadius;

  const ListenerPlayingArtCard({
    super.key,
    required this.imageUrl,
    this.fallbackIcon = FLucideIcons.music,
    this.borderRadius = 30,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.72),
            Colors.white.withValues(alpha: 0.36),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.18),
            blurRadius: 70,
            offset: const Offset(0, 28),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: ListenerCoverArt(
          imageUrl: imageUrl,
          fallbackIcon: fallbackIcon,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

class ListenerCoverBackdrop extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;

  const ListenerCoverBackdrop({
    super.key,
    required this.imageUrl,
    this.fallbackIcon = FLucideIcons.music,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -82,
          left: -56,
          right: -56,
          height: 340,
          child: Opacity(
            opacity: 0.18,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 44, sigmaY: 44),
              child: Transform.scale(
                scale: 1.08,
                child: ListenerCoverArt(
                  imageUrl: imageUrl,
                  fallbackIcon: fallbackIcon,
                  borderRadius: 0,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: -96,
          left: 0,
          right: 0,
          height: 260,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 0.72,
                  colors: [
                    Colors.white.withValues(alpha: 0.88),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ListenerSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ListenerSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ListenerColors.foreground,
              fontSize: 27,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (actionLabel != null)
            FButton(
              variant: FButtonVariant.ghost,
              size: FButtonSizeVariant.sm,
              onPress: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  color: ListenerColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ListenerAlbumCard extends StatelessWidget {
  final Album album;
  final String? imageUrl;
  final VoidCallback onPress;

  const ListenerAlbumCard({
    super.key,
    required this.album,
    required this.onPress,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return FTappable(
      onPress: onPress,
      builder: (context, states, child) {
        return AnimatedScale(
          scale: states.contains(FTappableVariant.pressed) ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(boxShadow: ListenerShadows.soft),
                  child: ListenerCoverArt(
                    imageUrl: imageUrl,
                    fallbackIcon: FLucideIcons.disc3,
                    borderRadius: 19,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                album.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ListenerColors.foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                album.artist ?? '未知艺术家',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ListenerColors.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ListenerArtistCard extends StatelessWidget {
  final Artist artist;
  final String? imageUrl;
  final VoidCallback onPress;

  const ListenerArtistCard({
    super.key,
    required this.artist,
    required this.onPress,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return FTappable(
      onPress: onPress,
      builder: (context, states, child) {
        return AnimatedScale(
          scale: states.contains(FTappableVariant.pressed) ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 15, 12, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  const Color(0xFFBFDBFE).withValues(alpha: 0.32),
                  Colors.white.withValues(alpha: 0.78),
                ],
              ),
              boxShadow: ListenerShadows.soft,
            ),
            child: Column(
              children: [
                SizedBox.square(
                  dimension: 72,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: ListenerShadows.soft,
                    ),
                    child: ClipOval(
                      child: ListenerCoverArt(
                        imageUrl: imageUrl,
                        fallbackIcon: FLucideIcons.userRound,
                        borderRadius: 999,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  artist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ListenerColors.foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ListenerGenreCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final VoidCallback? onPress;

  const ListenerGenreCard({
    super.key,
    required this.name,
    required this.subtitle,
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return FTappable(
      onPress: onPress,
      builder: (context, states, child) {
        return AnimatedScale(
          scale: states.contains(FTappableVariant.pressed) ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            constraints: const BoxConstraints(minHeight: 74),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.74),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF94A3B8).withValues(alpha: 0.10),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ListenerColors.foreground,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ListenerColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ListenerTrackRow extends StatelessWidget {
  final Song song;
  final String? imageUrl;
  final VoidCallback onPress;
  final VoidCallback? onFavorite;
  final VoidCallback? onMore;

  const ListenerTrackRow({
    super.key,
    required this.song,
    required this.onPress,
    this.imageUrl,
    this.onFavorite,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return FTappable(
      onPress: onPress,
      builder: (context, states, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
          decoration: BoxDecoration(
            color: states.contains(FTappableVariant.pressed)
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF94A3B8).withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 53,
                child: ListenerCoverArt(
                  imageUrl: imageUrl,
                  fallbackIcon: FLucideIcons.music,
                  borderRadius: 16,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ListenerColors.foreground,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      song.artist ?? song.album ?? '未知艺术家',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ListenerColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: onMore == null ? 46 : 86,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatSongDuration(song.duration),
                      style: const TextStyle(
                        color: ListenerColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FButton.icon(
                          variant: FButtonVariant.ghost,
                          size: FButtonSizeVariant.sm,
                          onPress: onFavorite,
                          child: const Icon(
                            FLucideIcons.heart,
                            color: Color(0xFFCBD5E1),
                            size: 19,
                          ),
                        ),
                        if (onMore != null) ...[
                          const SizedBox(width: 2),
                          FButton.icon(
                            variant: FButtonVariant.ghost,
                            size: FButtonSizeVariant.sm,
                            onPress: onMore,
                            child: const Icon(
                              FLucideIcons.ellipsis,
                              color: ListenerColors.muted,
                              size: 19,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String formatSongDuration(int? seconds) {
  if (seconds == null || seconds < 0) return '--:--';
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
}
