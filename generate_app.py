import os

files = {
    "lib/main.dart": """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme.dart';
import 'core/router.dart';

void main() {
  runApp(const ProviderScope(child: ConstructionApp()));
}

class ConstructionApp extends ConsumerWidget {
  const ConstructionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Construction Platform',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
""",
    "lib/core/theme.dart": """import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color primaryGreen = Color(0xFF43A047);
  static const Color backgroundWhite = Color(0xFFF5F7FA);
  static const Color textDark = Color(0xFF2C3E50);
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: primaryGreen,
        background: backgroundWhite,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundWhite,
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
""",
    "lib/core/router.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/home/main_layout.dart';
import '../features/project/create_project_screen.dart';
import '../features/project/project_detail_screen.dart';
import '../features/project/cost_estimation_screen.dart';
import '../features/providers/provider_listing_screen.dart';
import '../features/providers/provider_profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainLayout(),
        routes: [
          GoRoute(
            path: 'create-project',
            builder: (context, state) => const CreateProjectScreen(),
          ),
          GoRoute(
            path: 'project-detail/:id',
            builder: (context, state) => ProjectDetailScreen(projectId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'cost-estimation',
            builder: (context, state) => const CostEstimationScreen(),
          ),
          GoRoute(
            path: 'providers/:category',
            builder: (context, state) => ProviderListingScreen(category: state.pathParameters['category']!),
          ),
          GoRoute(
            path: 'provider-profile/:id',
            builder: (context, state) => ProviderProfileScreen(providerId: state.pathParameters['id']!),
          ),
        ]
      ),
    ],
  );
});
""",
    "lib/models/project.dart": """class Project {
  final String id;
  final String type;
  final String location;
  final double plotSize;
  final double budget;
  final String timeline;
  final String currentStage;
  
  Project({
    required this.id,
    required this.type,
    required this.location,
    required this.plotSize,
    required this.budget,
    required this.timeline,
    required this.currentStage,
  });
}

class Quote {
  final String id;
  final String providerId;
  final String providerName;
  final double estimatedCost;
  final String timeline;
  final String notes;

  Quote({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.estimatedCost,
    required this.timeline,
    required this.notes,
  });
}
""",
    "lib/features/auth/login_screen.dart": """import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isProvider = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.architecture, size: 80, color: Color(0xFF1E88E5)),
              const SizedBox(height: 24),
              Text(
                'Welcome to BuildConnect',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Consumer'),
                    selected: !isProvider,
                    onSelected: (val) => setState(() => isProvider = false),
                  ),
                  const SizedBox(width: 16),
                  ChoiceChip(
                    label: const Text('Provider'),
                    selected: isProvider,
                    onSelected: (val) => setState(() => isProvider = true),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Phone Number or Email',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Simulate login
                  context.go('/');
                },
                child: const Text('Login / Send OTP'),
              ),
              TextButton(
                onPressed: () => context.push('/register'),
                child: const Text('New here? Register'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
""",
    "lib/features/auth/register_screen.dart": """import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Register'),
            )
          ],
        ),
      ),
    );
  }
}
""",
    "lib/features/home/main_layout.dart": """import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../services/services_screen.dart';
import '../chat/chat_list_screen.dart';
import 'profile_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final screens = [
    const HomeScreen(),
    const Center(child: Text('Projects (Use Home)')),
    const ServicesScreen(),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.business), label: 'Projects'),
          NavigationDestination(icon: Icon(Icons.grid_view), label: 'Services'),
          NavigationDestination(icon: Icon(Icons.chat), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
""",
    "lib/features/home/home_screen.dart": """import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {})
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back, John!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            // Create Project Action
            InkWell(
              onTap: () => context.push('/create-project'),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF64B5F6)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_circle, color: Colors.white, size: 40),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Create New Project', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Start planning your dream home', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ongoing Projects', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(onPressed: (){}, child: const Text('View All'))
              ],
            ),
            
            // Dummy Project Card
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.home, color: Colors.blue),
                ),
                title: const Text('Villa Construction', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Current Stage: Design & Planning'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/project-detail/1'),
              ),
            ),

            const SizedBox(height: 24),
            Text('Tools', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calculate, color: Colors.green),
                title: const Text('Cost Estimator', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Get instant construction estimates'),
                onTap: () => context.push('/cost-estimation'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
""",
    "lib/features/home/profile_screen.dart": """import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          const SizedBox(height: 16),
          const Text('John Doe', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          ListTile(leading: const Icon(Icons.settings), title: const Text('Settings'), onTap: (){}),
          ListTile(leading: const Icon(Icons.help), title: const Text('Help & Support'), onTap: (){}),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Logout', style: TextStyle(color: Colors.red)), onTap: (){}),
        ],
      ),
    );
  }
}
""",
    "lib/features/project/create_project_screen.dart": """import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreateProjectScreen extends StatelessWidget {
  const CreateProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Project')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Project Type', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: const [
                DropdownMenuItem(value: 'house', child: Text('House')),
                DropdownMenuItem(value: 'office', child: Text('Office')),
              ],
              onChanged: (v) {},
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(labelText: 'Location', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 16),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Plot Size (sq ft)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(labelText: 'Budget Range', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(labelText: 'Timeline (e.g. 6 months)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project created successfully!')));
              },
              child: const Text('Save & Continue'),
            )
          ],
        ),
      ),
    );
  }
}
""",
    "lib/features/project/project_detail_screen.dart": """import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProjectDetailScreen extends StatelessWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final currentStage = "Design & Planning"; // Dummy

    return Scaffold(
      appBar: AppBar(title: const Text('Villa Construction')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Budget', style: TextStyle(color: Colors.grey)),
                        Text('$150,000', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Location', style: TextStyle(color: Colors.grey)),
                        Text('Downtown Ave', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Text('Project Progress', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const LinearProgressIndicator(value: 0.3, minHeight: 10, borderRadius: BorderRadius.all(Radius.circular(5))),
            const SizedBox(height: 8),
            Text('Current Stage: $currentStage', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.blue)),
            
            const SizedBox(height: 24),
            Text('Recommended Services', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // Logic based on workflow
            if (currentStage == "Design & Planning") ...[
              _buildServiceRecommendation(context, 'Architects', 'Design & Planning'),
              _buildServiceRecommendation(context, 'Structural Engineers', 'Engineering (MEP)'),
            ],
            
            const SizedBox(height: 24),
            Text('Cost Tracking', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildCostRow('Estimated Total', '$150,000', Colors.black),
                    const Divider(),
                    _buildCostRow('Quoted so far', '$45,000', Colors.orange),
                    const Divider(),
                    _buildCostRow('Spent', '$10,000', Colors.green),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildServiceRecommendation(BuildContext context, String title, String category) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.architecture, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Find professionals for this stage'),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => context.push('/providers/$category'),
      ),
    );
  }

  Widget _buildCostRow(String label, String amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
      ],
    );
  }
}
""",
    "lib/features/project/cost_estimation_screen.dart": """import 'package:flutter/material.dart';

class CostEstimationScreen extends StatefulWidget {
  const CostEstimationScreen({super.key});

  @override
  State<CostEstimationScreen> createState() => _CostEstimationScreenState();
}

class _CostEstimationScreenState extends State<CostEstimationScreen> {
  double area = 1000;
  String quality = 'Standard';
  double estimatedTotal = 0;

  void calculate() {
    double baseRate = 100;
    if (quality == 'Premium') baseRate = 150;
    if (quality == 'Basic') baseRate = 70;
    
    setState(() {
      estimatedTotal = area * baseRate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cost Estimator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              initialValue: '1000',
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Area (sq ft)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              onChanged: (v) => area = double.tryParse(v) ?? 0,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: quality,
              decoration: InputDecoration(labelText: 'Material Quality', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: ['Basic', 'Standard', 'Premium'].map((q) => DropdownMenuItem(value: q, child: Text(q))).toList(),
              onChanged: (v) => setState(() => quality = v!),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: calculate,
              child: const Text('Calculate Estimate'),
            ),
            const SizedBox(height: 32),
            if (estimatedTotal > 0) ...[
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text('Estimated Total Cost', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text('$${estimatedTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 24),
                      _buildBreakdown('Materials (60%)', estimatedTotal * 0.6),
                      _buildBreakdown('Labor (30%)', estimatedTotal * 0.3),
                      _buildBreakdown('Other (10%)', estimatedTotal * 0.1),
                    ],
                  ),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdown(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('$${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
""",
    "lib/services/services_screen.dart": """import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  final List<Map<String, dynamic>> categories = const [
    {'name': 'Land & Legal', 'icon': Icons.landscape},
    {'name': 'Finance & Approvals', 'icon': Icons.account_balance},
    {'name': 'Survey & Analysis', 'icon': Icons.map},
    {'name': 'Design & Planning', 'icon': Icons.architecture},
    {'name': 'Construction', 'icon': Icons.construction},
    {'name': 'Engineering (MEP)', 'icon': Icons.engineering},
    {'name': 'Materials & Supply', 'icon': Icons.inventory},
    {'name': 'Utilities', 'icon': Icons.power},
    {'name': 'Interiors & Finishing', 'icon': Icons.format_paint},
    {'name': 'Project Management', 'icon': Icons.assignment},
    {'name': 'Inspection & Compliance', 'icon': Icons.fact_check},
    {'name': 'Smart & Security', 'icon': Icons.security},
    {'name': 'Logistics & Equipment', 'icon': Icons.local_shipping},
    {'name': 'Insurance', 'icon': Icons.shield},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return InkWell(
            onTap: () => context.push('/providers/${cat['name']}'),
            child: Card(
              elevation: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(cat['icon'] as IconData, size: 40, color: Colors.blue),
                  const SizedBox(height: 12),
                  Text(cat['name'] as String, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
""",
    "lib/features/providers/provider_listing_screen.dart": """import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProviderListingScreen extends StatelessWidget {
  final String category;
  const ProviderListingScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: (){})
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5, // dummy count
        itemBuilder: (context, index) {
          return Card(
            child: InkWell(
              onTap: () => context.push('/provider-profile/$index'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey.shade200,
                      child: const Icon(Icons.business, size: 30, color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Provider ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('10 years exp • $category', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.orange, size: 16),
                              const Text(' 4.8 (120 reviews)', style: TextStyle(fontSize: 12)),
                            ],
                          )
                        ],
                      ),
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Starts at', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('$5k', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
""",
    "lib/features/providers/provider_profile_screen.dart": """import 'package:flutter/material.dart';

class ProviderProfileScreen extends StatelessWidget {
  final String providerId;
  const ProviderProfileScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provider Details')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 200,
              color: Colors.blue.shade100,
              child: const Center(child: Icon(Icons.business, size: 80, color: Colors.blue)),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Stellar Architects', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.star, color: Colors.orange, size: 20),
                      Text(' 4.9 (240 reviews) • 12 years experience', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('We specialize in modern and sustainable architectural designs for residential and commercial projects. Our team ensures the highest quality from planning to execution.'),
                  
                  const SizedBox(height: 24),
                  const Text('Services Offered', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Design & Planning', 'Interiors', 'Consulting'].map((s) => Chip(label: Text(s))).toList(),
                  ),
                  
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      _showQuoteModal(context);
                    },
                    child: const Text('Request Quote'),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showQuoteModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Request Quote', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              maxLines: 4,
              decoration: InputDecoration(labelText: 'Describe your requirements', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quote request sent!')));
              },
              child: const Text('Submit Request'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
""",
    "lib/features/chat/chat_list_screen.dart": """import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text('Provider ${index + 1}'),
            subtitle: const Text('Sure, we can start next week.'),
            trailing: const Text('10:42 AM', style: TextStyle(color: Colors.grey, fontSize: 12)),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(name: 'Provider ${index + 1}')));
            },
          );
        },
      ),
    );
  }
}
""",
    "lib/features/chat/chat_detail_screen.dart": """import 'package:flutter/material.dart';

class ChatDetailScreen extends StatelessWidget {
  final String name;
  const ChatDetailScreen({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMessage('Hello, I sent a quote for your project.', false),
                _buildMessage('Thanks! I will review and get back to you.', true),
                _buildMessage('Sure, let me know if you need any changes.', false),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send, color: Colors.blue), onPressed: (){})
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMessage(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black)),
      ),
    );
  }
}
"""
}

for filepath, content in files.items():
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with open(filepath, 'w') as f:
        f.write(content)
print("Files generated successfully.")
