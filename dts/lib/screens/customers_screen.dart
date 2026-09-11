import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../providers/customers_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/common/search_bar_widget.dart';
import '../widgets/common/empty_state_widget.dart';
import '../widgets/common/adaptive_layout.dart';
import '../widgets/common/desktop_table_widget.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customersProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final state = ref.read(customersProvider);
      if (!state.isLoading && state.hasMore) {
        ref.read(customersProvider.notifier).loadCustomers();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customersProvider);
    final notifier = ref.read(customersProvider.notifier);

    return AdaptiveLayout(
      currentRoute: '/customers',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Customers'),
        ),
        body: Column(
          children: [
            Container(
              color: AppColors.background,
              child: SearchBarWidget(
                controller: _searchController,
                hintText: 'Search customers...',
                onChanged: (val) => notifier.search(val),
                onClear: () => notifier.search(''),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await notifier.refresh();
                },
                child: _buildListContent(state),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const CustomBottomNavBar(currentIndex: 4),
      ),
    );
  }

  Widget _buildListContent(CustomersState state) {
    if (state.customers.isEmpty && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.customers.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          EmptyStateWidget(
            icon: Icons.error_outline_rounded,
            title: 'Something went wrong',
            subtitle: state.error!,
            actionLabel: 'Retry',
            onAction: () => ref.read(customersProvider.notifier).refresh(),
          ),
        ],
      );
    }

    if (state.customers.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          EmptyStateWidget(
            icon: Icons.people_outline_rounded,
            title: 'No Customers Found',
            subtitle: 'Customers are automatically created when you convert estimates to tax invoices.',
          ),
        ],
      );
    }

    if (AdaptiveLayout.isDesktop(context)) {
      final rows = state.customers.map((customer) {
        final lastInvoice = customer.lastInvoiceDate != null
            ? DateFormat('dd MMM yyyy').format(customer.lastInvoiceDate!)
            : 'No invoices yet';

        return DesktopTableRow(
          onTap: () => context.push('/customer-details/${customer.id}'),
          cells: [
            Text(
              customer.customerName,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            Text(
              customer.companyName.isNotEmpty ? customer.companyName : '-',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            Text(
              customer.mobileNumber,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            Text(
              customer.gstNumber.isNotEmpty ? customer.gstNumber : '-',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${customer.totalInvoices} Invoice(s)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.accent),
                ),
                Text(
                  'Last: $lastInvoice',
                  style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                ),
              ],
            ),
            OutlinedButton(
              onPressed: () => context.push('/customer-details/${customer.id}'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('View', style: TextStyle(fontSize: 12)),
            ),
          ],
        );
      }).toList();

      return ListView(
        controller: _scrollController,
        children: [
          DesktopTableWidget(
            columns: const [
              DesktopTableColumn(label: 'Customer Name', flex: 3),
              DesktopTableColumn(label: 'Company Name', flex: 3),
              DesktopTableColumn(label: 'Mobile', flex: 2),
              DesktopTableColumn(label: 'GST Number', flex: 2),
              DesktopTableColumn(label: 'Invoices & Last Date', flex: 2),
              DesktopTableColumn(label: 'Action', flex: 1),
            ],
            rows: rows,
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 4, bottom: 80),
      itemCount: state.customers.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.customers.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final customer = state.customers[index];
        final lastInvoice = customer.lastInvoiceDate != null
            ? DateFormat('dd MMM yyyy').format(customer.lastInvoiceDate!)
            : 'No invoices yet';

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                context.push('/customer-details/${customer.id}');
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.customerPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppColors.customerPurple,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.customerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          if (customer.companyName.isNotEmpty) ...[
                            Text(
                              customer.companyName,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                          ],
                          Row(
                            children: [
                              const Icon(Icons.phone_rounded, size: 12, color: AppColors.textLight),
                              const SizedBox(width: 4),
                              Text(
                                customer.mobileNumber,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              if (customer.gstNumber.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    customer.gstNumber,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Divider(height: 12, color: AppColors.border),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Last Invoice: $lastInvoice',
                                style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                              ),
                              Text(
                                '${customer.totalInvoices} Invoice(s)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textLight,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
