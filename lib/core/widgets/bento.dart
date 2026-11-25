import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants.dart';

/// Connectzy "Bento" design kit — charcoal + brand teal.
/// To change the app's main colour, change the accent values below.
class Bento {
  Bento._();

  // Brand accent (teal)
  static const Color accent = Color(0xFF0D9488);
  static const Color accentLight = Color(0xFF2DD4BF);
  static const Color accentDeep = Color(0xFF0F766E);
  static const Color accentSoft = Color(0xFFCCFBF1);

  /// Warnings / on-hold / star ratings only — not a brand colour.
  static const Color warning = Color(0xFFF59E0B);

  // Charcoal
  static const Color ink = Color(0xFF111318);
  static const Color ink2 = Color(0xFF1C1F26);

  // Status
  static const Color green = Color(0xFF10B981);
  static const Color red = Color(0xFFEF4444);
  static const Color blue = Color(0xFF3B82F6);
  static const Color violet = Color(0xFF8B5CF6);

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), accentDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient inkGradient = LinearGradient(
    colors: [Color(0xFF242833), ink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const double radius = 24;
  static const double radiusSm = 16;
  static const double gap = 12;

  static Color surface(bool dark) => dark ? const Color(0xFF181B22) : Colors.white;
  static Color surfaceAlt(bool dark) => dark ? const Color(0xFF22262F) : const Color(0xFFF6F5F2);
  static Color border(bool dark) => dark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFECEAE6);
  static Color text(bool dark) => dark ? Colors.white : ink;
  static Color muted(bool dark) => dark ? const Color(0xFF9AA1AD) : const Color(0xFF6B7280);
  static Color accentText(bool dark) => dark ? accentLight : accentDeep;

  static List<BoxShadow> shadow(bool dark) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.35 : 0.05),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];
}

/// Adds a gentle press-down scale + haptic tick to any tile.
class BentoPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const BentoPressable({super.key, required this.child, this.onTap});

  @override
  State<BentoPressable> createState() => _BentoPressableState();
}

class _BentoPressableState extends State<BentoPressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// The basic bento tile.
class BentoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final double? height;
  final double radius;
  final bool showBorder;
  final DecorationImage? image;

  const BentoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.gradient,
    this.onTap,
    this.height,
    this.radius = Bento.radius,
    this.showBorder = true,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final card = Container(
      height: height,
      width: double.infinity,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? Bento.surface(dark)) : null,
        gradient: gradient,
        image: image,
        borderRadius: BorderRadius.circular(radius),
        border: showBorder && gradient == null && image == null
            ? Border.all(color: Bento.border(dark))
            : null,
        boxShadow: Bento.shadow(dark),
      ),
      child: child,
    );
    return BentoPressable(onTap: onTap, child: card);
  }
}

class BentoSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const BentoSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: Bento.text(dark),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 12.5, color: Bento.muted(dark)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            BentoPressable(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Bento.surfaceAlt(dark),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Bento.text(dark),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: Bento.text(dark)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Rounded-square icon holder.
class BentoIconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? background;
  final double size;

  const BentoIconBubble({
    super.key,
    required this.icon,
    required this.color,
    this.background,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Small status / label pill.
class BentoPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color? background;
  final IconData? icon;

  const BentoPill({
    super.key,
    required this.label,
    required this.color,
    this.background,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.2),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded progress bar with a teal gradient fill.
class BentoProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final Gradient? gradient;
  final Color? trackColor;

  const BentoProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.gradient,
    this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, c) => Container(
        height: height,
        width: c.maxWidth,
        decoration: BoxDecoration(
          color: trackColor ?? Bento.surfaceAlt(dark),
          borderRadius: BorderRadius.circular(height),
        ),
        alignment: Alignment.centerLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          width: c.maxWidth * v,
          decoration: BoxDecoration(
            gradient: gradient ?? Bento.accentGradient,
            borderRadius: BorderRadius.circular(height),
          ),
        ),
      ),
    );
  }
}

/// Circular progress ring with a percentage (or custom child) in the middle.
class BentoProgressRing extends StatelessWidget {
  final double value;
  final Color color;
  final double size;
  final double stroke;
  final Widget? child;

  const BentoProgressRing({
    super.key,
    required this.value,
    this.color = Bento.accent,
    this.size = 58,
    this.stroke = 6,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(value: 1, strokeWidth: stroke, color: Bento.surfaceAlt(dark)),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: v),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, val, _) => CircularProgressIndicator(
              value: val,
              strokeWidth: stroke,
              strokeCap: StrokeCap.round,
              color: color,
            ),
          ),
          Center(
            child: child ??
                Text(
                  '${(v * 100).round()}%',
                  style: TextStyle(fontSize: size * 0.24, fontWeight: FontWeight.w900, color: Bento.text(dark), letterSpacing: -0.5),
                ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal pill tabs with counts (works with a [TabController]).
class BentoPillTabs extends StatelessWidget {
  final TabController controller;
  final List<String> labels;
  final List<int>? counts;
  final List<IconData>? icons;

  const BentoPillTabs({super.key, required this.controller, required this.labels, this.counts, this.icons});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: labels.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final selected = controller.index == i;
            final count = counts != null && i < counts!.length ? counts![i] : null;
            return BentoPressable(
              onTap: () => controller.animateTo(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: selected ? (dark ? Colors.white : Bento.ink) : Bento.surface(dark),
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(color: selected ? Colors.transparent : Bento.border(dark)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icons != null) ...[
                      Icon(icons![i], size: 15, color: selected ? (dark ? Bento.ink : Colors.white) : Bento.muted(dark)),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: selected ? (dark ? Bento.ink : Colors.white) : Bento.text(dark),
                      ),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: selected ? Bento.accent : Bento.surfaceAlt(dark),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: selected ? Colors.white : Bento.muted(dark),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Rounded search field.
class BentoSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const BentoSearchField({super.key, required this.hint, required this.onChanged, this.controller});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Bento.surface(dark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Bento.border(dark)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: Bento.text(dark), fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Bento.muted(dark), fontSize: 13.5, fontWeight: FontWeight.w500),
          prefixIcon: Icon(Icons.search_rounded, color: Bento.muted(dark), size: 20),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

/// Friendly empty state card.
class BentoEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const BentoEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return BentoCard(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      child: Column(
        children: [
          BentoIconBubble(icon: icon, color: Bento.accent, size: 60),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Bento.text(dark), letterSpacing: -0.3),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Bento.muted(dark), height: 1.4),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            BentoButton(label: actionLabel!, onTap: onAction!, compact: true),
          ],
        ],
      ),
    );
  }
}

/// Pill-style segmented control.
class BentoSegmented extends StatelessWidget {
  final List<String> labels;
  final List<IconData>? icons;
  final int index;
  final ValueChanged<int> onChanged;

  const BentoSegmented({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.icons,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Bento.surfaceAlt(dark),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == index;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? (dark ? Bento.ink2 : Colors.white) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: selected
                      ? [BoxShadow(color: Colors.black.withValues(alpha: dark ? 0.3 : 0.06), blurRadius: 10, offset: const Offset(0, 3))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icons != null) ...[
                      Icon(icons![i], size: 15, color: selected ? Bento.accentText(dark) : Bento.muted(dark)),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: selected ? Bento.text(dark) : Bento.muted(dark),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Metric tile: icon, big number, label.
class BentoStatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String? caption;

  const BentoStatTile({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return BentoCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BentoIconBubble(icon: icon, color: color, size: 34),
              const Spacer(),
              if (onTap != null) Icon(Icons.north_east_rounded, size: 16, color: Bento.muted(dark)),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 28,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                color: Bento.text(dark),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Bento.text(dark)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (caption != null)
            Text(
              caption!,
              style: TextStyle(fontSize: 11, color: Bento.muted(dark)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

/// Circular avatar from a URL, base64 data or initials.
class BentoAvatar extends StatelessWidget {
  final String name;
  final String? image;
  final double size;
  final bool ring;

  const BentoAvatar({super.key, required this.name, this.image, this.size = 46, this.ring = true});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';
    Widget fallback() => Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(gradient: Bento.accentGradient, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: TextStyle(color: Colors.white, fontSize: size * 0.42, fontWeight: FontWeight.w900),
          ),
        );

    Widget content = fallback();
    final src = image?.trim() ?? '';
    if (src.startsWith('http://') || src.startsWith('https://')) {
      content = ClipOval(
        child: Image.network(src, width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true, errorBuilder: (_, _, _) => fallback()),
      );
    } else if (src.isNotEmpty) {
      final bytes = Base64ImageCache.decode(src);
      if (bytes.isNotEmpty) {
        content = ClipOval(
          child: Image.memory(bytes, width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true, errorBuilder: (_, _, _) => fallback()),
        );
      }
    }

    if (!ring) return content;
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(gradient: Bento.accentGradient, shape: BoxShape.circle),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          shape: BoxShape.circle,
        ),
        child: content,
      ),
    );
  }
}

/// Round icon button with optional numeric badge (notifications).
class BentoBadgeButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final VoidCallback onTap;

  const BentoBadgeButton({super.key, required this.icon, required this.onTap, this.count = 0});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return BentoPressable(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Bento.surface(dark),
              shape: BoxShape.circle,
              border: Border.all(color: Bento.border(dark)),
              boxShadow: Bento.shadow(dark),
            ),
            child: Icon(icon, color: Bento.text(dark), size: 22),
          ),
          if (count > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  gradient: Bento.accentGradient,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Bento.surface(dark), width: 2),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Primary teal call-to-action button.
class BentoButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool dark;
  final bool compact;

  /// Fill the available width (label centred).
  final bool expand;

  /// [dark] = charcoal button (for use on teal surfaces).
  const BentoButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.arrow_forward_rounded,
    this.dark = false,
    this.compact = false,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    return BentoPressable(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 18, vertical: compact ? 9 : 12),
        decoration: BoxDecoration(
          gradient: dark ? null : Bento.accentGradient,
          color: dark ? Bento.ink : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: (dark ? Colors.black : Bento.accentDeep).withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(color: Colors.white, fontSize: compact ? 12.5 : 14, fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 6),
              Icon(icon, color: Colors.white, size: compact ? 15 : 17),
            ],
          ],
        ),
      ),
    );
  }
}

/// Round icon button used in bento headers (back / actions).
class BentoCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;

  const BentoCircleButton({super.key, required this.icon, this.onPressed, this.tooltip, this.color});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final button = BentoPressable(
      onTap: onPressed,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Bento.surface(dark),
          shape: BoxShape.circle,
          border: Border.all(color: Bento.border(dark)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(icon, size: 20, color: color ?? Bento.text(dark)),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Drop-in replacement for [AppBar] with the bento look:
/// round back button, bold left-aligned title, round action buttons.
/// Accepts the common AppBar parameters so existing screens keep compiling;
/// colour/elevation parameters are intentionally ignored for a consistent look.
class BentoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool automaticallyImplyLeading;
  final double toolbarHeight;

  // Accepted for AppBar compatibility (not used).
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? surfaceTintColor;
  final double? elevation;
  final double? scrolledUnderElevation;
  final bool? centerTitle;
  final double? titleSpacing;
  final double? leadingWidth;
  final IconThemeData? iconTheme;
  final IconThemeData? actionsIconTheme;
  final ShapeBorder? shape;
  final TextStyle? titleTextStyle;
  final Widget? flexibleSpace;
  final SystemUiOverlayStyle? systemOverlayStyle;

  const BentoAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.bottom,
    this.automaticallyImplyLeading = true,
    this.toolbarHeight = 64,
    this.backgroundColor,
    this.foregroundColor,
    this.surfaceTintColor,
    this.elevation,
    this.scrolledUnderElevation,
    this.centerTitle,
    this.titleSpacing,
    this.leadingWidth,
    this.iconTheme,
    this.actionsIconTheme,
    this.shape,
    this.titleTextStyle,
    this.flexibleSpace,
    this.systemOverlayStyle,
  });

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0));

  static const List<IconData> _backIcons = [
    Icons.arrow_back,
    Icons.arrow_back_rounded,
    Icons.arrow_back_ios,
    Icons.arrow_back_ios_new,
    Icons.arrow_back_ios_new_rounded,
    Icons.arrow_back_ios_rounded,
    Icons.chevron_left,
    Icons.chevron_left_rounded,
    Icons.close,
    Icons.close_rounded,
  ];

  /// Turns plain IconButtons into bento circle buttons; leaves custom widgets untouched.
  Widget _bentoize(Widget w) {
    if (w is IconButton && w.icon is Icon) {
      final icon = (w.icon as Icon).icon;
      if (icon != null) {
        final isBack = _backIcons.contains(icon);
        return BentoCircleButton(
          icon: isBack && icon != Icons.close && icon != Icons.close_rounded ? Icons.arrow_back_rounded : icon,
          onPressed: w.onPressed,
          tooltip: w.tooltip,
        );
      }
    }
    return w;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    Widget? lead;
    if (leading != null) {
      lead = _bentoize(leading!);
    } else if (automaticallyImplyLeading && canPop) {
      lead = BentoCircleButton(icon: Icons.arrow_back_rounded, onPressed: () => Navigator.of(context).maybePop());
    }

    Widget? titleWidget;
    if (title is Text) {
      final t = title as Text;
      titleWidget = Text(
        t.data ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.6, color: Bento.text(dark)),
      );
    } else if (title != null) {
      titleWidget = DefaultTextStyle.merge(
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.6, color: Bento.text(dark)),
        child: title!,
      );
    }

    final overlay = systemOverlayStyle ?? (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(statusBarColor: Colors.transparent),
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: toolbarHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      if (lead != null) ...[lead, const SizedBox(width: 12)],
                      Expanded(child: titleWidget ?? const SizedBox.shrink()),
                      if (actions != null)
                        for (final a in actions!) ...[const SizedBox(width: 8), _bentoize(a)],
                    ],
                  ),
                ),
              ),
              ?bottom,
            ],
          ),
        ),
      ),
    );
  }
}

class BentoNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const BentoNavItem({required this.icon, required this.activeIcon, required this.label});
}

/// Floating charcoal dock. The active tab becomes a teal pill with its label.
class BentoNavBar extends StatelessWidget {
  final List<BentoNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BentoNavBar({super.key, required this.items, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = MediaQuery.of(context).size.width >= 700;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(isTablet ? 32 : 14, 0, isTablet ? 32 : 14, 10),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 620 : 520),
            child: Container(
              height: 66,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF22262F) : Bento.ink,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withValues(alpha: dark ? 0.08 : 0.04)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.5 : 0.22),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, c) {
                  final narrow = c.maxWidth < 340;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(items.length, (i) {
                      final item = items[i];
                      final selected = i == currentIndex;
                      return Flexible(
                        flex: selected ? 5 : 3,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onTap(i);
                          },
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                              height: 46,
                              padding: EdgeInsets.symmetric(horizontal: selected ? (narrow ? 10 : 14) : 8),
                              decoration: BoxDecoration(
                                gradient: selected ? Bento.accentGradient : null,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    selected ? item.activeIcon : item.icon,
                                    size: 22,
                                    color: selected ? Colors.white : Colors.white.withValues(alpha: 0.55),
                                  ),
                                  if (selected) ...[
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        item.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.fade,
                                        softWrap: false,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft decorative glow used behind hero content.
class BentoGlow extends StatelessWidget {
  final double size;
  final Color color;

  const BentoGlow({super.key, this.size = 180, this.color = Bento.accentLight});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color.withValues(alpha: 0.45), color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
