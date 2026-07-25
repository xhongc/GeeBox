import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class ChansonScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget> suffixes;
  final VoidCallback? onBack;
  final bool childPad;

  const ChansonScaffold({
    super.key,
    required this.title,
    required this.child,
    this.suffixes = const [],
    this.onBack,
    this.childPad = false,
  });

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      childPad: childPad,
      header: FHeader.nested(
        prefixes: [
          if (onBack != null) FHeaderAction.back(onPress: onBack),
        ],
        title: Text(title),
        suffixes: suffixes,
      ),
      child: child,
    );
  }
}

class ChansonSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const ChansonSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Text(
            title,
            style: theme.typography.body.xs.copyWith(
              color: theme.colors.mutedForeground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        FCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ],
    );
  }
}

class ChansonTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? details;
  final VoidCallback? onPress;

  const ChansonTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.details,
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return FTile(
      prefix: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      details: details,
      suffix: onPress == null ? null : const Icon(FLucideIcons.chevronRight),
      onPress: onPress,
    );
  }
}

class ChansonAlert extends StatelessWidget {
  final String title;
  final String message;
  final FAlertVariant variant;

  const ChansonAlert({
    super.key,
    required this.title,
    required this.message,
    this.variant = FAlertVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    return FAlert(
      variant: variant,
      title: Text(title),
      subtitle: Text(message),
    );
  }
}

class ChansonEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const ChansonEmptyState({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: theme.colors.mutedForeground),
          const SizedBox(height: 14),
          Text(
            message,
            style: theme.typography.body.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class ChansonCoverArt extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;
  final double borderRadius;

  const ChansonCoverArt({
    super.key,
    this.imageUrl,
    this.fallbackIcon = FLucideIcons.music,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    Widget fallback() => ColoredBox(
          color: theme.colors.muted,
          child: Center(
            child: Icon(
              fallbackIcon,
              color: theme.colors.mutedForeground,
            ),
          ),
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: imageUrl == null
          ? fallback()
          : Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallback(),
            ),
    );
  }
}

class ChansonGridCard extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;
  final String title;
  final String subtitle;
  final VoidCallback onPress;

  const ChansonGridCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onPress,
    this.imageUrl,
    this.fallbackIcon = FLucideIcons.disc3,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return FTappable(
      onPress: onPress,
      builder: (context, variants, child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: ChansonCoverArt(
                imageUrl: imageUrl,
                fallbackIcon: fallbackIcon,
                borderRadius: 8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.typography.body.sm.copyWith(
              color: theme.colors.foreground,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.typography.body.xs.copyWith(
              color: theme.colors.mutedForeground,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class ChansonSongTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? coverUrl;
  final String? duration;
  final VoidCallback onPress;
  final VoidCallback? onMore;
  final bool selected;

  const ChansonSongTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onPress,
    this.coverUrl,
    this.duration,
    this.onMore,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return FTile(
      selected: selected,
      prefix: SizedBox.square(
        dimension: 46,
        child: ChansonCoverArt(imageUrl: coverUrl),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      details: duration == null ? null : Text(duration!),
      suffix: onMore == null
          ? null
          : FButton.icon(
              variant: FButtonVariant.ghost,
              size: FButtonSizeVariant.sm,
              onPress: onMore,
              child: const Icon(FLucideIcons.ellipsisVertical),
            ),
      onPress: onPress,
    );
  }
}
