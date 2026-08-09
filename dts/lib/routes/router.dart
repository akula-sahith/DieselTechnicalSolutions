import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report_model.dart';
import '../models/agreement_model.dart';
import '../models/estimate_model.dart';
import '../models/tax_invoice_model.dart';
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
import '../screens/estimates_screen.dart';
import '../screens/create_estimate_screen.dart';
import '../screens/estimate_details_screen.dart';
import '../screens/tax_invoices_screen.dart';
import '../screens/create_tax_invoice_screen.dart';
import '../screens/tax_invoice_details_screen.dart';
import '../screens/billing_invoices_screen.dart';
import '../screens/create_billing_invoice_screen.dart';
import '../screens/billing_invoice_details_screen.dart';
import '../models/billing_invoice_model.dart';
import '../screens/customers_screen.dart';
import '../screens/customer_details_screen.dart';
import '../screens/purchase_bills_screen.dart';

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
          final initialReport = state.extra as ReportModel?;
          return CreateReportScreen(draftId: draftId, initialReport: initialReport);
        },
      ),
      GoRoute(
        path: '/create-agreement',
        builder: (context, state) {
          final draftId = state.uri.queryParameters['draftId'];
          final initialAgreement = state.extra as AgreementModel?;
          return CreateAgreementScreen(draftId: draftId, initialAgreement: initialAgreement);
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
        path: '/estimates',
        builder: (context, state) => const EstimatesScreen(),
      ),
      GoRoute(
        path: '/tax-invoices',
        builder: (context, state) => const TaxInvoicesScreen(),
      ),
      GoRoute(
        path: '/create-estimate',
        builder: (context, state) {
          final initialEstimate = state.extra as EstimateModel?;
          return CreateEstimateScreen(initialEstimate: initialEstimate);
        },
      ),
      GoRoute(
        path: '/create-tax-invoice',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is EstimateModel) {
            return CreateTaxInvoiceScreen(initialEstimate: extra);
          } else if (extra is TaxInvoiceModel) {
            return CreateTaxInvoiceScreen(initialInvoice: extra);
          }
          return const CreateTaxInvoiceScreen();
        },
      ),
      GoRoute(
        path: '/estimate-details/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EstimateDetailsScreen(estimateId: id);
        },
      ),
      GoRoute(
        path: '/tax-invoice-details/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final initialInvoice = state.extra as TaxInvoiceModel?;
          return TaxInvoiceDetailsScreen(invoiceId: id, initialInvoice: initialInvoice);
        },
      ),
      GoRoute(
        path: '/billing-invoices',
        builder: (context, state) => const BillingInvoicesScreen(),
      ),
      GoRoute(
        path: '/create-billing-invoice',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is EstimateModel) {
            return CreateBillingInvoiceScreen(initialEstimate: extra);
          } else if (extra is BillingInvoiceModel) {
            return CreateBillingInvoiceScreen(initialInvoice: extra);
          }
          return const CreateBillingInvoiceScreen();
        },
      ),
      GoRoute(
        path: '/billing-invoice-details/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final initialInvoice = state.extra as BillingInvoiceModel?;
          return BillingInvoiceDetailsScreen(invoiceId: id, initialInvoice: initialInvoice);
        },
      ),
      GoRoute(
        path: '/drafts',
        builder: (context, state) => const DraftsListScreen(),
      ),
      GoRoute(
        path: '/customers',
        builder: (context, state) => const CustomersScreen(),
      ),
      GoRoute(
        path: '/customer-details/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CustomerDetailsScreen(customerId: id);
        },
      ),
      GoRoute(
        path: '/purchase-bills',
        builder: (context, state) => const PurchaseBillsScreen(),
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
