import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/onboarding_screen.dart';
import '../features/home/main_layout.dart';
import '../features/project/create_project_screen.dart';
import '../features/project/project_detail_screen.dart';
import '../features/project/cost_estimation_screen.dart';
import '../features/project/compare_quotes_screen.dart';
import '../features/providers/provider_listing_screen.dart';
import '../features/providers/provider_profile_screen.dart';
import '../features/providers/provider_layout.dart';
import '../features/providers/provider_lead_detail.dart';
import '../features/providers/provider_profile_edit_screen.dart';

import '../features/auth/provider/provider_registration_stepper.dart';
import '../features/auth/provider/verification_pending_screen.dart';
import '../features/providers/provider_job_detail.dart';
import '../features/home/settings_screen.dart';
import '../features/home/help_support_screen.dart';
import '../features/b2b/presentation/product_list_screen.dart';
import '../features/b2b/presentation/product_detail_screen.dart';
import '../features/b2b/presentation/inquiry_form_screen.dart';
import '../features/b2b/presentation/my_inquiries_screen.dart';
import '../features/b2b/presentation/news_screen.dart';
import '../features/b2b/presentation/supplier_catalog_screen.dart';
import '../features/b2b/presentation/supplier_product_management_screen.dart';
import '../features/b2b/presentation/lead_management_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final role = state.uri.queryParameters['role'];
          return LoginScreen(initialRole: role);
        },
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
            path: 'compare-quotes/:id',
            builder: (context, state) => CompareQuotesScreen(projectId: state.pathParameters['id']!),
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
      GoRoute(
        path: '/provider-home',
        builder: (context, state) => const ProviderLayout(),
      ),
      GoRoute(
        path: '/provider-lead/:id',
        builder: (context, state) => ProviderLeadDetail(leadId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/provider-job/:id',
        builder: (context, state) => ProviderJobDetail(projectId: state.pathParameters['id']!),
      ),

      GoRoute(
        path: '/provider-register',
        builder: (context, state) => const ProviderRegistrationStepper(),
      ),
      GoRoute(
        path: '/provider-verification-pending',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>?;
          return VerificationPendingScreen(
            email: extra?['email'] ?? '',
            password: extra?['password'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/provider-profile-edit',
        builder: (context, state) => const ProviderProfileEditScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/help-support',
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: '/b2b-products',
        builder: (context, state) => const ProductListScreen(),
      ),
      GoRoute(
        path: '/b2b-product-detail/:id',
        builder: (context, state) => ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/b2b-inquiry-form',
        builder: (context, state) => InquiryFormScreen(
          supplierId: state.uri.queryParameters['supplierId'],
          productId: state.uri.queryParameters['productId'],
          productName: state.uri.queryParameters['productName'],
          productImage: state.uri.queryParameters['productImage'],
        ),
      ),
      GoRoute(
        path: '/b2b-my-inquiries',
        builder: (context, state) => const MyInquiriesScreen(),
      ),
      GoRoute(
        path: '/b2b-news',
        builder: (context, state) => const NewsScreen(),
      ),
      GoRoute(
        path: '/supplier-products',
        builder: (context, state) => const SupplierCatalogScreen(),
      ),
      GoRoute(
        path: '/supplier-add-product',
        builder: (context, state) => SupplierProductManagementScreen(
          editItem: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: '/supplier-leads',
        builder: (context, state) => const LeadManagementScreen(),
      ),
    ],
  );
});
