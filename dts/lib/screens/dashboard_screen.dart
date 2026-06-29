import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/reports_provider.dart';
import '../widgets/bottom_nav_bar.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final reportsState = ref.watch(reportsProvider);
    final reportsNotifier = ref.read(reportsProvider.notifier);

    // Combine drafts (Pending) and submitted reports (Completed)
    final recentDrafts = reportsState.drafts.take(5).toList();
    final recentReports = reportsState.reports.take(5).toList();
    
    // Sort combined by date or just display drafts first, then submitted
    final combinedRecent = [...recentDrafts, ...recentReports].take(5).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await reportsNotifier.refresh();
        },
        child: CustomScrollView(
          slivers: [
            // Custom App Bar Header with Horizontal Stat Cards
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F2042), Color(0xFF1E3A8A)], // Deep Navy to Bright Blue
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24, top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good Morning, ${authState.userName ?? 'Siva'} 👋',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Here's what's happening today",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            // Notification Bell
                            Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('No new notifications.')),
                                    );
                                  },
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Horizontal row of stat cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCardHorizontal(
                                title: "Today's Reports",
                                value: reportsNotifier.todayReportsCount.toString(),
                                icon: Icons.description_outlined,
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCardHorizontal(
                                title: "Completed",
                                value: reportsNotifier.completedReportsCount.toString(),
                                icon: Icons.check_circle_outline,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCardHorizontal(
                                title: "Pending",
                                value: reportsNotifier.pendingReportsCount.toString(),
                                icon: Icons.schedule_outlined,
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCardHorizontal(
                                title: "Total Reports",
                                value: reportsNotifier.totalReportsCount.toString(),
                                icon: Icons.folder_open_outlined,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),

            // "+ Create New Service Report" Banner Button with Overlapping Clipboard
            SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.push('/create-report'),
      child: Hero(
        tag: "create_board",
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 4.2, // Adjust if needed
            child: Image.asset(
              'assets/images/create_board.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    ),
  ),
),

            // Recent Reports List Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 28, bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Reports',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.push('/reports');
                      },
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Recent Reports List
            if (combinedRecent.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No recent reports found.\nTap the button above to create one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textLight),
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final report = combinedRecent[index];
                    final isDraft = report.id == null || report.id!.isEmpty;
                    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(report.serviceAndCustomer.dateTime);

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        onTap: () {
                          // Draft check: pass draft query parameter
                          final id = isDraft ? report.serviceAndCustomer.jobRef : report.id!;
                          context.push('/report-details/$id?draft=$isDraft');
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.description_outlined, color: AppColors.primary),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                report.serviceAndCustomer.jobRef,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            _buildStatusBadge(isDraft),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              report.serviceAndCustomer.customerName,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textLight),
                      ),
                    );
                  },
                  childCount: combinedRecent.length,
                ),
              ),

            // Padding at the bottom so bottom bar doesn't cover list
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildStatCardHorizontal({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isDraft) {
    final text = isDraft ? 'Pending' : 'Completed';
    final bgColor = isDraft ? AppColors.warning.withOpacity(0.15) : AppColors.success.withOpacity(0.15);
    final textColor = isDraft ? AppColors.warning : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
