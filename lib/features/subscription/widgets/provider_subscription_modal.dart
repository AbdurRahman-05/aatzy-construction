import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/subscription_service.dart';
import '../../auth/auth_provider.dart';

class ProviderSubscriptionPaywallOverlay extends ConsumerWidget {
  final Widget child;

  const ProviderSubscriptionPaywallOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final subState = ref.watch(subscriptionProvider);

    // Only apply paywall if user is a PROVIDER and not active
    final bool shouldBlock = auth.role == 'PROVIDER' && !subState.isSubscribed && !subState.isLoading;

    return Stack(
      children: [
        child,
        if (shouldBlock)
          Positioned.fill(
            child: PopScope(
              canPop: false,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.72),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: const ProviderSubscriptionCard(isDismissible: false),
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

  const ProviderSubscriptionCard({super.key, this.isDismissible = true});

  @override
  ConsumerState<ProviderSubscriptionCard> createState() => _ProviderSubscriptionCardState();
}

class _ProviderSubscriptionCardState extends ConsumerState<ProviderSubscriptionCard> {
  bool _isProcessing = false;

  Future<void> _handlePayment() async {
    final auth = ref.read(authProvider);
    if (auth.id == null) return;

    setState(() => _isProcessing = true);

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
                  Expanded(child: Text(message)),
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
              content: Text(message),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(subscriptionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row with Crown Badge & Optional Close or Signout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'PRO MEMBERSHIP',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isDismissible)
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              else
                TextButton.icon(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout_rounded, size: 14, color: Colors.grey),
                  label: const Text('Sign Out', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // Title & Pricing Banner
          const Text(
            'Unlock BuildConnect Pro',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Activate your annual membership to unlock leads, submit project quotes, and start working with property owners.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),

          // Price Tag Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0F766E).withValues(alpha: 0.25), const Color(0xFF1E293B)]
                    : [const Color(0xFFECFDF5), const Color(0xFFF0FDF4)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF0F766E).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ANNUAL PLAN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F766E),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '365 Days Full Access',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '₹',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                        Text(
                          '5,999',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F766E),
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      '/ year',
                      style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Benefits List
          _buildBenefitItem(
            icon: Icons.flash_on_rounded,
            color: Colors.amber.shade600,
            title: 'Unlimited Consumer Project Leads',
            subtitle: 'Direct notification and contact info for high-budget jobs',
          ),
          _buildBenefitItem(
            icon: Icons.chat_bubble_rounded,
            color: const Color(0xFF0F766E),
            title: 'Direct Client Calling & Chat',
            subtitle: 'Instant messaging with home and commercial property owners',
          ),
          _buildBenefitItem(
            icon: Icons.request_quote_rounded,
            color: Colors.blue.shade600,
            title: 'Unlimited Quotation & Proposal Submissions',
            subtitle: 'Submit estimates and bid directly with zero commission fee',
          ),
          _buildBenefitItem(
            icon: Icons.storefront_rounded,
            color: Colors.purple.shade600,
            title: 'B2B Wholesale Materials & Factory Pricing',
            subtitle: 'Unlock exclusive contractor rates on cement, steel, tiles',
          ),
          _buildBenefitItem(
            icon: Icons.verified_rounded,
            color: Colors.green.shade600,
            title: 'Verified Pro Badge on Search',
            subtitle: 'Stand out at the top of client directories & search results',
          ),
          const SizedBox(height: 24),

          // Razorpay Action Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: const Color(0xFF0F766E).withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: (_isProcessing || subState.isLoading) ? null : _handlePayment,
            child: (_isProcessing || subState.isLoading)
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_open_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Subscribe & Continue (₹5,999/yr)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),

          // Security Trust Label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'Secured with Razorpay • UPI, Cards, NetBanking',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
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
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        left: 16,
        right: 16,
        top: 40,
      ),
      child: const ProviderSubscriptionCard(isDismissible: true),
    ),
  );
}
