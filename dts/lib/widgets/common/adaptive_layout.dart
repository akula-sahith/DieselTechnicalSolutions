import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../manage_reporters_dialog.dart';

class AdaptiveLayout extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const AdaptiveLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 800;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isDesktop(context)) {
      return child;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          DesktopSidebar(currentRoute: currentRoute),
          const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
          Expanded(
            child: ClipRect(
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class DesktopSidebar extends ConsumerWidget {
  final String currentRoute;

  const DesktopSidebar({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    final isReporter = authState.isReporter;

    final navItems = [
      _SidebarNavItem(
        title: 'Dashboard',
        icon: Icons.grid_view_rounded,
        route: '/dashboard',
      ),
      _SidebarNavItem(
        title: 'Service Reports',
        icon: Icons.description_outlined,
        route: '/reports',
        accentColor: AppColors.reportOrange,
      ),
      if (!isReporter) ...[
        _SidebarNavItem(
          title: 'AMC Proposals',
          icon: Icons.handshake_outlined,
          route: '/agreements',
          accentColor: AppColors.agreementGreen,
        ),
        _SidebarNavItem(
          title: 'Estimates',
          icon: Icons.request_quote_outlined,
          route: '/estimates',
          accentColor: AppColors.quotationBlue,
        ),
        _SidebarNavItem(
          title: 'Tax Invoices',
          icon: Icons.receipt_long_outlined,
          route: '/tax-invoices',
          accentColor: AppColors.primary,
        ),
        _SidebarNavItem(
          title: 'Cash Invoices',
          icon: Icons.subtitles_outlined,
          route: '/billing-invoices',
          accentColor: const Color(0xFF0284C7),
        ),
        _SidebarNavItem(
          title: 'Delivery Challans',
          icon: Icons.local_shipping_outlined,
          route: '/delivery-challans',
          accentColor: const Color(0xFF059669),
        ),
        _SidebarNavItem(
          title: 'Purchase Bills',
          icon: Icons.shopping_bag_outlined,
          route: '/purchase-bills',
          accentColor: const Color(0xFF7C3AED),
        ),
        _SidebarNavItem(
          title: 'Unpaid Bills',
          icon: Icons.pending_actions_outlined,
          route: '/unpaid-bills',
          accentColor: const Color(0xFFDC2626),
        ),
        _SidebarNavItem(
          title: 'Customers',
          icon: Icons.people_rounded,
          route: '/customers',
          accentColor: AppColors.customerPurple,
        ),
      ],
    ];

    return Container(
      width: 270,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // ── APP BRANDING HEADER ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Diesel Technical',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: -0.2,
                            height: 1.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Solutions ERP',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                            height: 1.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'v1.2.1 DESKTOP',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // ── QUICK ACTION CREATE BUTTON ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: ElevatedButton.icon(
                onPressed: () => _showQuickCreateMenu(context, ref),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'New Document',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            // ── NAVIGATION LIST ──
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: navItems.length,
                itemBuilder: (context, index) {
                  final item = navItems[index];
                  final isActive = currentRoute == item.route;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (!isActive) {
                            context.go(item.route);
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: isActive
                                ? (item.accentColor ?? AppColors.primary).withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 20,
                                color: isActive
                                    ? (item.accentColor ?? AppColors.primary)
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                    color: isActive
                                        ? (item.accentColor ?? AppColors.primary)
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (isActive)
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: item.accentColor ?? AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1, color: AppColors.border),

            // ── USER PROFILE FOOTER ──
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.secondary,
                          child: Icon(Icons.person, size: 18, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authState.userName ?? 'User',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                authState.role.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: authState.isAdmin
                                      ? AppColors.primary
                                      : AppColors.reportOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textSecondary),
                          tooltip: 'Account Menu',
                          onSelected: (value) {
                            if (value == 'reporters') {
                              showDialog(
                                context: context,
                                builder: (context) => const ManageReportersDialog(),
                              );
                            } else if (value == 'logout') {
                              ref.read(authProvider.notifier).logout();
                              context.go('/login');
                            }
                          },
                          itemBuilder: (context) => [
                            if (authState.isAdmin)
                              const PopupMenuItem(
                                value: 'reporters',
                                child: Row(
                                  children: [
                                    Icon(Icons.admin_panel_settings_outlined, size: 18, color: AppColors.primary),
                                    SizedBox(width: 8),
                                    Text('Manage Reporters', style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.exit_to_app_rounded, size: 18, color: AppColors.error),
                                  SizedBox(width: 8),
                                  Text('Logout', style: TextStyle(fontSize: 13, color: AppColors.error)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickCreateMenu(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authProvider);

    if (authState.isReporter) {
      context.push('/create-report');
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.note_add_rounded, color: AppColors.primary),
              SizedBox(width: 10),
              Text('Create New Document', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCreateOption(
                  context,
                  icon: Icons.description_outlined,
                  iconColor: AppColors.reportOrange,
                  title: 'Service Report',
                  subtitle: 'Create a field service report',
                  route: '/create-report',
                ),
                const SizedBox(height: 8),
                _buildCreateOption(
                  context,
                  icon: Icons.handshake_outlined,
                  iconColor: AppColors.agreementGreen,
                  title: 'AMC Proposal',
                  subtitle: 'Draft an agreement or quotation',
                  route: '/create-agreement',
                ),
                const SizedBox(height: 8),
                _buildCreateOption(
                  context,
                  icon: Icons.request_quote_outlined,
                  iconColor: AppColors.quotationBlue,
                  title: 'Estimate',
                  subtitle: 'Create a new cost estimate',
                  route: '/create-estimate',
                ),
                const SizedBox(height: 8),
                _buildCreateOption(
                  context,
                  icon: Icons.receipt_outlined,
                  iconColor: AppColors.primary,
                  title: 'Tax Invoice',
                  subtitle: 'Generate a direct tax invoice',
                  route: '/create-tax-invoice',
                ),
                const SizedBox(height: 8),
                _buildCreateOption(
                  context,
                  icon: Icons.subtitles_outlined,
                  iconColor: const Color(0xFF0284C7),
                  title: 'Cash Invoice',
                  subtitle: 'Generate a cash invoice without GST',
                  route: '/create-billing-invoice',
                ),
                const SizedBox(height: 8),
                _buildCreateOption(
                  context,
                  icon: Icons.local_shipping_outlined,
                  iconColor: const Color(0xFF059669),
                  title: 'Delivery Challan',
                  subtitle: 'Create a new delivery challan',
                  route: '/create-delivery-challan',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCreateOption(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.pop(context);
          context.push(route);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: iconColor.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: iconColor.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarNavItem {
  final String title;
  final IconData icon;
  final String route;
  final Color? accentColor;

  _SidebarNavItem({
    required this.title,
    required this.icon,
    required this.route,
    this.accentColor,
  });
}
