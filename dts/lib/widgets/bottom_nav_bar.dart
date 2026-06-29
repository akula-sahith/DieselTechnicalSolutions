import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class CustomBottomNavBar extends ConsumerWidget {
  final int currentIndex;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _handleNavigation(BuildContext context, int index, WidgetRef ref) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/reports');
        break;
      case 2: // Search page - route to reports and focus search
        context.go('/reports');
        break;
      case 3: // Profile - show simple signout sheet
        _showProfileSheet(context, ref);
        break;
    }
  }

  void _showProfileSheet(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.secondary,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  authState.userName ?? 'Technician',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  authState.email ?? 'siva@dts.com',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: AppColors.border),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: AppColors.error),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(authProvider.notifier).logout();
                    context.go('/login');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Dashboard Icon
              _buildNavItem(
                icon: Icons.grid_view_rounded,
                label: 'Dashboard',
                isActive: currentIndex == 0,
                onTap: () => _handleNavigation(context, 0, ref),
              ),
              // Reports Icon
              _buildNavItem(
                icon: Icons.description_rounded,
                label: 'Reports',
                isActive: currentIndex == 1,
                onTap: () => _handleNavigation(context, 1, ref),
              ),
              // Spacer for middle FAB
              const SizedBox(width: 48),
              // Search Icon
              _buildNavItem(
                icon: Icons.search_rounded,
                label: 'Search',
                isActive: currentIndex == 2,
                onTap: () => _handleNavigation(context, 2, ref),
              ),
              // Profile Icon
              _buildNavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isActive: currentIndex == 3,
                onTap: () => _handleNavigation(context, 3, ref),
              ),
            ],
          ),
          
          // Floating Center Button
          Positioned(
            top: -24,
            left: MediaQuery.of(context).size.width / 2 - 28,
            child: GestureDetector(
              onTap: () {
                context.push('/create-report');
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.secondary : AppColors.textLight,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AppColors.secondary : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
