import os

files = {
    "lib/features/auth/provider/provider_registration_stepper.dart": """import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProviderRegistrationStepper extends StatefulWidget {
  const ProviderRegistrationStepper({super.key});

  @override
  State<ProviderRegistrationStepper> createState() => _ProviderRegistrationStepperState();
}

class _ProviderRegistrationStepperState extends State<ProviderRegistrationStepper> {
  int _currentStep = 0;
  
  // Multi-select categories
  final List<String> _categories = [
    'Land & Legal', 'Finance & Approvals', 'Survey & Analysis', 'Design & Planning',
    'Construction', 'Engineering (MEP)', 'Materials & Supply', 'Utilities',
    'Interiors & Finishing', 'Project Management', 'Inspection & Compliance',
    'Smart & Security', 'Logistics & Equipment', 'Insurance'
  ];
  final Set<String> _selectedCategories = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provider Registration')),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 5) {
            setState(() => _currentStep += 1);
          } else {
            // Final submit
            context.go('/provider-verification-pending');
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          } else {
            context.pop();
          }
        },
        steps: [
          Step(
            title: const Text('Basic Details'),
            content: Column(
              children: [
                TextFormField(decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 8),
                TextFormField(decoration: const InputDecoration(labelText: 'Phone Number')),
                const SizedBox(height: 8),
                TextFormField(decoration: const InputDecoration(labelText: 'Email (Optional)')),
                const SizedBox(height: 8),
                TextFormField(obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
              ],
            ),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('OTP Verification'),
            content: Column(
              children: [
                const Text('Enter OTP sent to your phone number'),
                const SizedBox(height: 8),
                TextFormField(decoration: const InputDecoration(labelText: 'OTP', hintText: '123456')),
              ],
            ),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('Service Category Selection'),
            content: Wrap(
              spacing: 8,
              children: _categories.map((c) {
                final isSelected = _selectedCategories.contains(c);
                return FilterChip(
                  label: Text(c),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) _selectedCategories.add(c);
                      else _selectedCategories.remove(c);
                    });
                  },
                );
              }).toList(),
            ),
            isActive: _currentStep >= 2,
          ),
          Step(
            title: const Text('Business Details'),
            content: Column(
              children: [
                TextFormField(decoration: const InputDecoration(labelText: 'Business Name')),
                const SizedBox(height: 8),
                TextFormField(decoration: const InputDecoration(labelText: 'Years of Experience')),
                const SizedBox(height: 8),
                TextFormField(decoration: const InputDecoration(labelText: 'Service Area (Location)')),
                const SizedBox(height: 8),
                TextFormField(maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
              ],
            ),
            isActive: _currentStep >= 3,
          ),
          Step(
            title: const Text('Document Upload'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.upload_file), label: const Text('Upload ID Proof (Aadhar/PAN)')),
                const SizedBox(height: 8),
                OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.upload_file), label: const Text('Upload Business Proof (Optional)')),
                const SizedBox(height: 8),
                OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.image), label: const Text('Upload Portfolio Images')),
              ],
            ),
            isActive: _currentStep >= 4,
          ),
          Step(
            title: const Text('Profile Completion'),
            content: Column(
              children: [
                TextFormField(decoration: const InputDecoration(labelText: 'Add specific services (comma separated)')),
                const SizedBox(height: 8),
                TextFormField(decoration: const InputDecoration(labelText: 'Approximate Pricing / Hourly Rate')),
              ],
            ),
            isActive: _currentStep >= 5,
          ),
        ],
      ),
    );
  }
}
""",
    "lib/features/auth/provider/verification_pending_screen.dart": """import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VerificationPendingScreen extends StatelessWidget {
  const VerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verification Pending')),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.hourglass_empty, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            Text('Your profile is under review', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            const Text('Our admins are verifying your documents. This usually takes 24-48 hours.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Edit Profile'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Simulate approval and login
                context.go('/provider-home');
              },
              child: const Text('Simulate Admin Approval -> Login'),
            )
          ],
        ),
      ),
    );
  }
}
""",
    "lib/features/auth/provider/provider_login_screen.dart": """import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProviderLoginScreen extends StatefulWidget {
  const ProviderLoginScreen({super.key});

  @override
  State<ProviderLoginScreen> createState() => _ProviderLoginScreenState();
}

class _ProviderLoginScreenState extends State<ProviderLoginScreen> {
  bool otpSent = false;
  
  // Dummy user state
  bool isVerified = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provider Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
            ),
            const SizedBox(height: 16),
            if (otpSent) ...[
              TextFormField(
                decoration: const InputDecoration(labelText: 'OTP', prefixIcon: Icon(Icons.password)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (!isVerified) {
                    context.go('/provider-verification-pending');
                  } else {
                    context.go('/provider-home');
                  }
                },
                child: const Text('Verify & Login'),
              ),
            ] else ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() => otpSent = true);
                },
                child: const Text('Send OTP'),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('New Provider?'),
                TextButton(
                  onPressed: () => context.push('/provider-register'),
                  child: const Text('Register Here'),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
"""
}

for filepath, content in files.items():
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
print("Provider Auth files generated successfully.")
