import 'package:flutter/material.dart';

/// Ultra-smooth Instagram & Swiggy-style Shimmer / Skeleton Loading System.
///
/// Features:
/// - Smooth continuous gradient wave sheen with customizable direction and duration.
/// - Adaptive light/dark theme color mapping (soft cool slates in light mode, deep obsidian in dark mode).
/// - Atomic building blocks: [ShimmerBox], [ShimmerCircle], [ShimmerLine].
/// - Pre-configured layout skeletons matching the app's real data cards:
///   [ShimmerProjectList], [ShimmerOrderList], [ShimmerSocialFeed],
///   [ShimmerProviderList], [ShimmerProductGrid], [ShimmerLeadsList],
///   [ShimmerStatsGrid], and [ShimmerChatList].
class Shimmer extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;
  final bool enabled;

  const Shimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1400),
    this.enabled = true,
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void didUpdateWidget(Shimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Instagram / Swiggy signature neutral tones
    final defaultBase = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);

    final defaultHighlight = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFF8FAFC);

    final base = widget.baseColor ?? defaultBase;
    final highlight = widget.highlightColor ?? defaultHighlight;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        // Sweep gradient from left (-1.5) to right (+2.5)
        final beginX = -1.5 + (progress * 4.0);
        final endX = beginX + 1.2;

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(beginX, -0.3),
              end: Alignment(endX, 0.3),
              colors: [
                base,
                highlight,
                base,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A placeholder rectangular box with rounded corners
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.color,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? defaultColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// A placeholder circular shape for avatars and round icons
class ShimmerCircle extends StatelessWidget {
  final double diameter;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  const ShimmerCircle({
    super.key,
    required this.diameter,
    this.color,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);

    return Container(
      width: diameter,
      height: diameter,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? defaultColor,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// A placeholder line for text
class ShimmerLine extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerLine({
    super.key,
    this.width,
    this.height = 12.0,
    this.borderRadius = 6.0,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(
      width: width,
      height: height,
      borderRadius: borderRadius,
      margin: margin,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAILORED SKELETON LAYOUTS
// ─────────────────────────────────────────────────────────────────────────────

/// Shimmer skeleton for Active Projects list
class ShimmerProjectList extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const ShimmerProjectList({
    super.key,
    this.itemCount = 3,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF131F28) : Colors.white;
    final border = isDark
        ? Border.all(color: Colors.white.withValues(alpha: 0.06))
        : Border.all(color: const Color(0xFFE5E7EB));

    return Shimmer(
      child: Padding(
        padding: padding,
        child: Column(
          children: List.generate(itemCount, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: border,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Category tag + location pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      ShimmerBox(width: 80, height: 18, borderRadius: 6),
                      ShimmerBox(width: 100, height: 16, borderRadius: 6),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Project Title
                  const ShimmerLine(width: 220, height: 18, borderRadius: 6),
                  const SizedBox(height: 8),

                  // Subtitle / Scope
                  const ShimmerLine(width: 150, height: 12, borderRadius: 4),
                  const SizedBox(height: 16),

                  // Progress Bar placeholder
                  const ShimmerBox(height: 6, borderRadius: 3),
                  const SizedBox(height: 14),

                  // Bottom Row: Budget tag + action button placeholder
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      ShimmerBox(width: 90, height: 22, borderRadius: 6),
                      ShimmerBox(width: 70, height: 26, borderRadius: 8),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Shimmer skeleton for Material Orders list
class ShimmerOrderList extends StatelessWidget {
  final int itemCount;

  const ShimmerOrderList({
    super.key,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF131F28) : Colors.white;
    final border = isDark
        ? Border.all(color: Colors.white.withValues(alpha: 0.06))
        : Border.all(color: const Color(0xFFE5E7EB));

    return Shimmer(
      child: Column(
        children: List.generate(itemCount, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: border,
            ),
            child: Row(
              children: [
                // Thumbnail icon box
                const ShimmerBox(width: 52, height: 52, borderRadius: 12),
                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerLine(width: 160, height: 15, borderRadius: 5),
                      SizedBox(height: 8),
                      ShimmerLine(width: 110, height: 12, borderRadius: 4),
                      SizedBox(height: 6),
                      ShimmerLine(width: 80, height: 10, borderRadius: 4),
                    ],
                  ),
                ),

                // Status chip & price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    ShimmerBox(width: 65, height: 20, borderRadius: 6),
                    SizedBox(height: 10),
                    ShimmerLine(width: 50, height: 14, borderRadius: 4),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// Horizontal Instagram-style showcase feed shimmer
class ShimmerSocialFeed extends StatelessWidget {
  final int itemCount;

  const ShimmerSocialFeed({
    super.key,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF131F28) : Colors.white;

    return Shimmer(
      child: SizedBox(
        height: 230,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            return Container(
              width: 180,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post image placeholder
                  const ShimmerBox(
                    width: double.infinity,
                    height: 125,
                    borderRadius: 18,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ShimmerLine(width: 130, height: 14, borderRadius: 4),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            ShimmerCircle(diameter: 18),
                            SizedBox(width: 6),
                            Expanded(child: ShimmerLine(height: 10, borderRadius: 3)),
                          ],
                        ),
                        SizedBox(height: 10),
                        ShimmerBox(width: 70, height: 16, borderRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Shimmer skeleton for Provider & Contractor listings
class ShimmerProviderList extends StatelessWidget {
  final int itemCount;

  const ShimmerProviderList({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF131F28) : Colors.white;

    return Shimmer(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar / Business Icon
                const ShimmerBox(width: 64, height: 64, borderRadius: 16),
                const SizedBox(width: 14),

                // Info details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerLine(width: 170, height: 16, borderRadius: 4),
                      SizedBox(height: 8),
                      ShimmerLine(width: 110, height: 12, borderRadius: 4),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          ShimmerBox(width: 45, height: 18, borderRadius: 6),
                          SizedBox(width: 8),
                          ShimmerBox(width: 80, height: 18, borderRadius: 6),
                        ],
                      ),
                    ],
                  ),
                ),

                // Call / Action Button placeholder
                const ShimmerCircle(diameter: 36),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Shimmer skeleton for 2-column B2B Materials Store Grid
class ShimmerProductGrid extends StatelessWidget {
  final int itemCount;

  const ShimmerProductGrid({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF131F28) : Colors.white;

    return Shimmer(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                const Expanded(
                  flex: 3,
                  child: ShimmerBox(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 18,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: const [
                        ShimmerLine(width: 120, height: 13, borderRadius: 4),
                        ShimmerLine(width: 80, height: 11, borderRadius: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ShimmerLine(width: 60, height: 14, borderRadius: 4),
                            ShimmerBox(width: 24, height: 24, borderRadius: 6),
                          ],
                        ),
                      ],
                    ),
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

/// Shimmer skeleton for Contractor Leads list
class ShimmerLeadsList extends StatelessWidget {
  final int itemCount;

  const ShimmerLeadsList({
    super.key,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF131F28) : Colors.white;

    return Shimmer(
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    ShimmerBox(width: 90, height: 20, borderRadius: 6),
                    ShimmerBox(width: 70, height: 16, borderRadius: 6),
                  ],
                ),
                const SizedBox(height: 12),
                const ShimmerLine(width: 200, height: 18, borderRadius: 5),
                const SizedBox(height: 8),
                const ShimmerLine(width: 260, height: 12, borderRadius: 4),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    ShimmerBox(width: 100, height: 24, borderRadius: 6),
                    ShimmerBox(width: 110, height: 32, borderRadius: 10),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Shimmer skeleton for Provider Dashboard statistics
class ShimmerStatsGrid extends StatelessWidget {
  const ShimmerStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF131F28) : Colors.white;

    return Shimmer(
      child: Column(
        children: [
          // Banner card placeholder
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 16),
          // 4 Grid stats boxes
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 95,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 95,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 95,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 95,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shimmer skeleton for Direct Messages / Chat List
class ShimmerChatList extends StatelessWidget {
  final int itemCount;

  const ShimmerChatList({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (context, index) => const Divider(indent: 74, height: 1),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const ShimmerCircle(diameter: 50),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerLine(width: 140, height: 15, borderRadius: 4),
                      SizedBox(height: 8),
                      ShimmerLine(width: 210, height: 12, borderRadius: 4),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const ShimmerLine(width: 40, height: 10, borderRadius: 4),
              ],
            ),
          );
        },
      ),
    );
  }
}
