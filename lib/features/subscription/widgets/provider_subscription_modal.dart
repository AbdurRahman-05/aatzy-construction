import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/subscription_service.dart';
import '../../auth/auth_provider.dart';

class ProviderSubscriptionPaywallOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const ProviderSubscriptionPaywallOverlay({super.key, required this.child});

  @override
  ConsumerState<ProviderSubscriptionPaywallOverlay> createState() =>
      _ProviderSubscriptionPaywallOverlayState();
}

class _ProviderSubscriptionPaywallOverlayState
    extends ConsumerState<ProviderSubscriptionPaywallOverlay> {
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final subState = ref.watch(subscriptionProvider);

    // Only apply paywall if user is a PROVIDER, not subscribed, and hasn't closed it via X button
    final bool shouldBlock =
        auth.role == 'PROVIDER' && !subState.isSubscribed && !_isDismissed;

    return Stack(
      children: [
        widget.child,
        if (shouldBlock)
          Positioned.fill(
            child: PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;
                setState(() => _isDismissed = true);
              },
              child: Material(
                type: MaterialType.transparency,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.78),
                    alignment: Alignment.center,
                    child: SafeArea(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 490),
                            child: ProviderSubscriptionCard(
                              isDismissible: true,
                              onDismiss: () {
                                setState(() => _isDismissed = true);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ProviderSubscriptionCard extends ConsumerStatefulWidget {
  final bool isDismissible;
  final VoidCallback? onDismiss;

  const ProviderSubscriptionCard({
    super.key,
    this.isDismissible = true,
    this.onDismiss,
  });

  @override
  ConsumerState<ProviderSubscriptionCard> createState() => _ProviderSubscriptionCardState();
}

class _ProviderSubscriptionCardState extends ConsumerState<ProviderSubscriptionCard> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Safety: ensure any stale global loading lock from prior cancellations is cleared
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subscriptionProvider.notifier).resetLoading();
    });
  }

  Future<void> _handlePayment() async {
    final auth = ref.read(authProvider);
    if (auth.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again to continue')),
      );
      return;
    }

    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await ref.read(subscriptionProvider.notifier).payAndSubscribe(
        context: context,
        providerId: auth.id!,
        businessName: auth.businessName ?? auth.name ?? 'Provider',
        email: auth.email ?? 'provider@buildconnect.com',
        phone: '',
        onComplete: (success, message) {
          if (!mounted) return;
          setState(() => _isProcessing = false);

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF0F766E),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
            if (widget.isDismissible) {
              Navigator.of(context).pop();
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  message,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment initiation failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(subscriptionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark
                ? const Color(0xFF334155).withValues(alpha: 0.8)
                : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
              blurRadius: 36,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Ambient warm golden glow at top right corner
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.22 : 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Ambient teal glow at bottom left corner
              Positioned(
                bottom: -50,
                left: -50,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF0F766E).withValues(alpha: isDark ? 0.22 : 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Card content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Bar: VIP Pill Badge & Action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 15),
                              const SizedBox(width: 5),
                              Text(
                                'PRO BUILDER PASS',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10.5,
                                  letterSpacing: 0.8,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (widget.onDismiss != null) {
                                widget.onDismiss!();
                              } else if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Title & Description
                    Text(
                      'Accelerate Your Growth with Pro',
                      style: GoogleFonts.inter(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Direct client leads, zero-commission quote submissions, and bulk wholesale rates — all in one membership.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        height: 1.4,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ticket / Pass Showcase Box
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF064E3B).withValues(alpha: 0.35),
                                  const Color(0xFF0F172A),
                                ]
                              : [
                                  const Color(0xFFECFDF5),
                                  const Color(0xFFF0FDF4),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ALL-ACCESS ANNUAL PASS',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF0F766E),
                                      letterSpacing: 0.8,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'SAVE 45%',
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '₹',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF0F766E),
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              Text(
                                '5,999',
                                style: GoogleFonts.inter(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF0F766E),
                                  letterSpacing: -1,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '/ year',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.bolt_rounded, size: 13, color: Color(0xFF10B981)),
                                    const SizedBox(width: 3),
                                    Text(
                                      '₹499 / mo',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.25)
                                  : const Color(0xFF0F766E).withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome_rounded, size: 13, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '1 closed lead easily covers more than 5x the annual fee',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Superpowers Section Header
                    Text(
                      'EVERYTHING INCLUDED IN YOUR PASS',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        letterSpacing: 0.8,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Structured Perks
                    _buildBenefitItem(
                      context: context,
                      icon: Icons.bolt_rounded,
                      iconBgColor: const Color(0xFFF59E0B),
                      title: 'Direct Verified Project Leads',
                      subtitle: 'Direct phone & WhatsApp contact for high-budget jobs',
                    ),
                    _buildBenefitItem(
                      context: context,
                      icon: Icons.chat_bubble_outline_rounded,
                      iconBgColor: const Color(0xFF10B981),
                      title: 'Direct Client Calling & Chat',
                      subtitle: 'Real-time discussions with property owners without delays',
                    ),
                    _buildBenefitItem(
                      context: context,
                      icon: Icons.description_outlined,
                      iconBgColor: const Color(0xFF3B82F6),
                      title: 'Unlimited 0% Commission Quotes',
                      subtitle: 'Submit proposals directly and keep 100% of your earnings',
                    ),
                    _buildBenefitItem(
                      context: context,
                      icon: Icons.inventory_2_outlined,
                      iconBgColor: const Color(0xFF8B5CF6),
                      title: 'B2B Wholesale Materials Pricing',
                      subtitle: 'Exclusive contractor rates on cement, steel, bricks & tiles',
                    ),
                    _buildBenefitItem(
                      context: context,
                      icon: Icons.verified_outlined,
                      iconBgColor: const Color(0xFF0D9488),
                      title: 'Verified Pro Badge on Search',
                      subtitle: 'Priority placement at the top of client search results',
                    ),
                    const SizedBox(height: 16),

                    // Primary Action CTA Button
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F766E), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.36),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isProcessing ? null : _handlePayment,
                        child: _isProcessing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.bolt_rounded, size: 20, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Subscribe & Unlock Pro (₹5,999/yr)',
                                    style: GoogleFonts.inter(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Security Label
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 13,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Secured by Razorpay • UPI, Cards & NetBanking',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required BuildContext context,
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBgColor.withValues(alpha: isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: iconBgColor.withValues(alpha: isDark ? 0.35 : 0.22),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconBgColor, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    height: 1.25,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF10B981),
              size: 13,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showProviderSubscriptionModal(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 16,
          right: 16,
          top: 40,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: const ProviderSubscriptionCard(isDismissible: true),
        ),
      ),
    ),
  );
}
