import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/create_report_screen.dart';
import '../screens/report_details_screen.dart';
import '../screens/success_screen.dart';
import '../screens/agreements_screen.dart';
import '../screens/create_agreement_screen.dart';
import '../screens/agreement_details_screen.dart';
import '../screens/drafts_list_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/agreements',
        builder: (context, state) => const AgreementsScreen(),
      ),
      GoRoute(
        path: '/create-report',
        builder: (context, state) {
          final draftId = state.uri.queryParameters['draftId'];
          return CreateReportScreen(draftId: draftId);
        },
      ),
      GoRoute(
        path: '/create-agreement',
        builder: (context, state) {
          final draftId = state.uri.queryParameters['draftId'];
          return CreateAgreementScreen(draftId: draftId);
        },
      ),
      GoRoute(
        path: '/report-details/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final isLocalDraft = state.uri.queryParameters['draft'] == 'true';
          return ReportDetailsScreen(reportId: id, isLocalDraft: isLocalDraft);
        },
      ),
      GoRoute(
        path: '/agreement-details/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final isLocalDraft = state.uri.queryParameters['draft'] == 'true';
          return AgreementDetailsScreen(agreementId: id, isLocalDraft: isLocalDraft);
        },
      ),
      GoRoute(
        path: '/drafts',
        builder: (context, state) => const DraftsListScreen(),
      ),
      GoRoute(
        path: '/report-success/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SuccessScreen(reportId: id, isAgreement: false);
        },
      ),
      GoRoute(
        path: '/agreement-success/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SuccessScreen(reportId: id, isAgreement: true);
        },
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isGoingToSplash = state.matchedLocation == '/splash';
      final isGoingToLogin = state.matchedLocation == '/login';

      if (isGoingToSplash) {
        return null; // Let the splash screen finish loading and handle navigation
      }

      if (!isLoggedIn && !isGoingToLogin) {
        return '/login';
      }

      if (isLoggedIn && isGoingToLogin) {
        return '/dashboard';
      }

      return null;
    },
  );
});
