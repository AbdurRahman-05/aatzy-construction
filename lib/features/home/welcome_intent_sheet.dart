import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/bento.dart';

/// What the customer told us they are planning on first entry.
enum UserIntent { buildHouse, renovate, interiors, buyMaterials, exploring }

/// Full-screen "What are you planning?" page shown every time a customer
/// opens the app (or logs in).
///
/// The caller decides where to navigate for the returned [UserIntent]; this
/// widget only asks the question and remembers the last choice.
class WelcomeIntentSheet extends StatelessWidget {
  final String? userName;
  const WelcomeIntentSheet({super.key, this.userName});

  static const choiceKey = 'welcome_intent_choice';

  /// Shows the page for a logged-in customer.
  ///
  /// Returns `null` when it was NOT shown (no user / screen gone),
  /// otherwise the user's choice ([UserIntent.exploring] when dismissed).
  static Future<UserIntent?> maybeShow(
    BuildContext context, {
    required String? userId,
    String? userName,
  }) async {
    if (userId == null || userId.isEmpty) return null;
    if (!context.mounted) return null;

    final choice = await Navigator.of(context, rootNavigator: true).push<UserIntent>(
      PageRouteBuilder<UserIntent>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, _, _) => WelcomeIntentSheet(userName: userName),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );

    final result = choice ?? UserIntent.exploring;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(choiceKey, result.name);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final firstName = (userName ?? '').trim().split(RegExp(r'\s+')).first;
    final greeting = firstName.isEmpty ? 'Welcome to Connectzy 👋' : 'Hi $firstName 👋';
    final pageBg = dark ? const Color(0xFF0E1015) : const Color(0xFFF6F5F2);

    void close() => Navigator.of(context).pop(UserIntent.exploring);

    return Scaffold(
      backgroundColor: pageBg,
      body: Stack(
        children: [
          const Positioned(top: -70, right: -60, child: BentoGlow(size: 260)),
          Positioned(
            bottom: 120,
            left: -90,
            child: BentoGlow(size: 220, color: Bento.violet.withValues(alpha: 0.6)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar: brand + close
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: Bento.accentGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.apartment_rounded, size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Connectzy',
                        style: TextStyle(
                          color: Bento.text(dark),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const Spacer(),
                      BentoPressable(
                        onTap: close,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Bento.surface(dark),
                            shape: BoxShape.circle,
                            border: Border.all(color: Bento.border(dark)),
                          ),
                          child: Icon(Icons.close_rounded, size: 19, color: Bento.muted(dark)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),

                  // Heading
                  Text(
                    greeting,
                    style: TextStyle(
                      color: Bento.accentText(dark),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'What are you\nplanning?',
                    style: TextStyle(
                      color: Bento.text(dark),
                      fontSize: 32,
                      height: 1.08,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pick one and we\'ll take you straight there.',
                    style: TextStyle(color: Bento.muted(dark), fontSize: 14),
                  ),
                  const SizedBox(height: 14),
                  const Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      BentoPill(label: 'Free quotes', color: Bento.accentDeep, icon: Icons.check_rounded),
                      BentoPill(label: 'Verified partners', color: Bento.accentDeep, icon: Icons.verified_rounded),
                      BentoPill(label: 'Live site tracking', color: Bento.accentDeep, icon: Icons.timeline_rounded),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // 2 x 2 intent grid fills the remaining height
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _IntentTile(
                                  intent: UserIntent.buildHouse,
                                  icon: Icons.villa_rounded,
                                  title: 'Build a\nnew house',
                                  caption: 'Get quotes from verified builders',
                                  color: Bento.accent,
                                  highlight: true,
                                  dark: dark,
                                ),
                              ),
                              const SizedBox(width: Bento.gap),
                              Expanded(
                                child: _IntentTile(
                                  intent: UserIntent.renovate,
                                  icon: Icons.home_repair_service_rounded,
                                  title: 'Renovate',
                                  caption: 'Repairs, remodel and extensions',
                                  color: Bento.blue,
                                  dark: dark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Bento.gap),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _IntentTile(
                                  intent: UserIntent.interiors,
                                  icon: Icons.chair_rounded,
                                  title: 'Interiors',
                                  caption: 'Design, flooring and painting',
                                  color: Bento.violet,
                                  dark: dark,
                                ),
                              ),
                              const SizedBox(width: Bento.gap),
                              Expanded(
                                child: _IntentTile(
                                  intent: UserIntent.buyMaterials,
                                  icon: Icons.inventory_2_rounded,
                                  title: 'Buy\nmaterials',
                                  caption: 'Cement, steel, tiles and more',
                                  color: Bento.green,
                                  dark: dark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Skip
                  BentoPressable(
                    onTap: close,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: Bento.surface(dark),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Bento.border(dark)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Just exploring',
                            style: TextStyle(
                              color: Bento.text(dark),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 17, color: Bento.muted(dark)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntentTile extends StatelessWidget {
  final UserIntent intent;
  final IconData icon;
  final String title;
  final String caption;
  final Color color;
  final bool highlight;
  final bool dark;

  const _IntentTile({
    required this.intent,
    required this.icon,
    required this.title,
    required this.caption,
    required this.color,
    required this.dark,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = highlight ? Colors.white : Bento.text(dark);
    final captionColor = highlight ? Colors.white.withValues(alpha: 0.82) : Bento.muted(dark);

    return BentoPressable(
      onTap: () => Navigator.of(context).pop(intent),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: highlight ? Bento.accentGradient : null,
          color: highlight ? null : Bento.surface(dark),
          borderRadius: BorderRadius.circular(Bento.radius),
          border: highlight ? null : Border.all(color: Bento.border(dark)),
          boxShadow: highlight
              ? [
                  BoxShadow(
                    color: Bento.accentDeep.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : Bento.shadow(dark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: highlight
                        ? Colors.white.withValues(alpha: 0.2)
                        : color.withValues(alpha: dark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, size: 25, color: highlight ? Colors.white : color),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: highlight ? Colors.white.withValues(alpha: 0.18) : Bento.surfaceAlt(dark),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_outward_rounded,
                    size: 16,
                    color: highlight ? Colors.white : Bento.muted(dark),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              style: TextStyle(
                color: titleColor,
                fontSize: 18,
                height: 1.12,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: captionColor, fontSize: 12, height: 1.3, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
