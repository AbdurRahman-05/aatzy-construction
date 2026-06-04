import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_settings_dialog.dart';
import '../../core/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  String? _selectedRole; // 'CONSUMER' or 'PROVIDER'

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'BuildConnect',
      subtitle: 'Connecting Dreams to Reality',
      description: 'Welcome to BuildConnect, the premium platform that seamlessly connects homeowners and project builders with top-tier construction and design professionals.',
      icon: Icons.architecture_rounded,
      gradientColors: [Color(0xFF2196F3), Color(0xFF1565C0)],
      bgImageUrl: 'https://images.unsplash.com/photo-1503387762-592ded58c454?auto=format&fit=crop&w=1200&q=80',
    ),
    OnboardingData(
      title: 'For Service Providers',
      subtitle: 'Grow & Scale Your Business',
      description: 'Access high-quality local project leads, showcase your work portfolio, submit transparent proposals, and manage your pipeline under one verified profile.',
      icon: Icons.construction_rounded,
      gradientColors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
      bgImageUrl: 'https://images.unsplash.com/photo-1541888946425-d81bb19240f5?auto=format&fit=crop&w=1200&q=80',
    ),
    OnboardingData(
      title: 'For Consumers',
      subtitle: 'Build with Confidence',
      description: 'Plan your project using our estimation tools, browse through verified builders, compare competitive bids, and track your milestones safely.',
      icon: Icons.home_work_rounded,
      gradientColors: [Color(0xFFFF9800), Color(0xFFE65100)],
      bgImageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
    ),
  ];

  final String _roleSelectionBgUrl = 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentBgUrl = _currentIndex < 3 ? _pages[_currentIndex].bgImageUrl : _roleSelectionBgUrl;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Image with Fade Transition
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: SizedBox(
              key: ValueKey(currentBgUrl),
              width: double.infinity,
              height: double.infinity,
              child: Image.network(
                currentBgUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.black87,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white70),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  // Elegant gradient fallback if network fails
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Premium Dark Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.65),
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.88),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // Main Layout Content
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Branding
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.asset(
                              'assets/logo.png',
                              width: 28,
                              height: 28,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'BuildConnect',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.wifi_tethering, color: Colors.white70),
                            tooltip: 'Network Settings',
                            onPressed: () => showApiSettingsDialog(context),
                          ),
                          if (_currentIndex < 3)
                            TextButton(
                              onPressed: () {
                                _pageController.animateToPage(
                                  3,
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.fastOutSlowIn,
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white.withOpacity(0.7),
                              ),
                              child: const Text(
                                'Skip',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content Slider
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    children: [
                      ..._pages.map((data) => _buildIntroPage(data)),
                      _buildRoleSelectionPage(),
                    ],
                  ),
                ),

                // Bottom Navigation Area
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_currentIndex < 3) ...[
                        // Indicators and Next button row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Page Indicators
                            Row(
                              children: List.generate(4, (index) {
                                bool isActive = _currentIndex == index;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.only(right: 8),
                                  height: 8,
                                  width: isActive ? 24 : 8,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }),
                            ),
                            // Next Button
                            ElevatedButton(
                              onPressed: _nextPage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 8,
                                shadowColor: Colors.black.withValues(alpha: 0.4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Next',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Selection page helper text
                        Text(
                          'Choose your path to shape the future of building.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glassmorphic Center Card containing the Icon
          ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: data.title == 'BuildConnect'
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(34),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        data.icon,
                        size: 60,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 48),

          // Subtitle
          Text(
            data.subtitle.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.white70,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              data.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.75),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelectionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          // Heading
          const Text(
            'Who are you?',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.8,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us how you intend to use BuildConnect to tailor your experience.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Glassmorphic cards for Roles
          Column(
            children: [
              _buildGlassRoleCard(
                role: 'CONSUMER',
                title: 'I am a Consumer',
                description: 'Seeking construction quotes, estimations, project planning, and hiring professionals.',
                icon: Icons.person_rounded,
                activeColor: AppTheme.primaryBlue,
              ),
              const SizedBox(height: 16),
              _buildGlassRoleCard(
                role: 'PROVIDER',
                title: 'I am a Service Provider',
                description: 'Contractor, architect, designer looking for leads, bidding, and showcasing portfolios.',
                icon: Icons.engineering_rounded,
                activeColor: AppTheme.primaryGreen,
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Dynamic authentication buttons
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _selectedRole == null
                ? Container(
                    height: 120,
                    alignment: Alignment.center,
                    child: Text(
                      'Please select a role to continue',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontStyle: FontStyle.italic,
                        fontSize: 15,
                      ),
                    ),
                  )
                : Column(
                    key: ValueKey(_selectedRole),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (_selectedRole == 'CONSUMER') {
                            context.push('/login');
                          } else {
                            context.push('/provider-login');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedRole == 'CONSUMER'
                              ? AppTheme.primaryBlue
                              : AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: (_selectedRole == 'CONSUMER'
                                  ? AppTheme.primaryBlue
                                  : AppTheme.primaryGreen)
                              .withValues(alpha: 0.4),
                        ),
                        child: Text(
                          _selectedRole == 'CONSUMER'
                              ? 'Login as Consumer'
                              : 'Login as Service Provider',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: OutlinedButton(
                            onPressed: () {
                              if (_selectedRole == 'CONSUMER') {
                                context.push('/register');
                              } else {
                                context.push('/provider-register');
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: _selectedRole == 'CONSUMER'
                                    ? AppTheme.primaryBlue
                                    : AppTheme.primaryGreen,
                                width: 2,
                              ),
                              backgroundColor: Colors.white.withValues(alpha: 0.05),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              _selectedRole == 'CONSUMER'
                                  ? 'New Consumer? Register Here'
                                  : 'New Provider? Register Here',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildGlassRoleCard({
    required String role,
    required String title,
    required String description,
    required IconData icon,
    required Color activeColor,
  }) {
    bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? activeColor : Colors.white.withValues(alpha: 0.15),
                width: isSelected ? 2.5 : 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Badge
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? activeColor : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.6),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // Radio Indicator
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? activeColor : Colors.white.withValues(alpha: 0.4),
                      width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: activeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final String bgImageUrl;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradientColors,
    required this.bgImageUrl,
  });
}
