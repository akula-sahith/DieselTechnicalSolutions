import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../providers/delivery_challans_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/common/document_card.dart';
import '../widgets/common/search_bar_widget.dart';
import '../widgets/common/empty_state_widget.dart';
import '../widgets/common/adaptive_layout.dart';
import '../widgets/common/desktop_table_widget.dart';

class DeliveryChallansScreen extends ConsumerStatefulWidget {
  const DeliveryChallansScreen({super.key});

  @override
  ConsumerState<DeliveryChallansScreen> createState() =>
      _DeliveryChallansScreenState();
}

class _DeliveryChallansScreenState
    extends ConsumerState<DeliveryChallansScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deliveryChallansProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = ref.read(deliveryChallansProvider);
      if (!state.isLoading && state.hasMore) {
        ref.read(deliveryChallansProvider.notifier).loadDeliveryChallans();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final challansState = ref.watch(deliveryChallansProvider);
    final challansNotifier = ref.read(deliveryChallansProvider.notifier);

    return AdaptiveLayout(
      currentRoute: '/delivery-challans',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Delivery Challans'),
        ),
        body: Column(
          children: [
            Container(
              color: AppColors.background,
              child: SearchBarWidget(
                controller: _searchController,
                hintText: 'Search challans, customers, vehicles...',
                onChanged: (val) => challansNotifier.search(val),
                onClear: () => challansNotifier.search(''),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await challansNotifier.refresh();
                },
                child: _buildListContent(challansState),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'create_challan_fab',
          onPressed: () => context.push('/create-delivery-challan'),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
        bottomNavigationBar: const CustomBottomNavBar(currentIndex: -1),
      ),
    );
  }

  Widget _buildListContent(DeliveryChallansState state) {
    if (state.deliveryChallans.isEmpty && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.deliveryChallans.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          EmptyStateWidget(
            icon: Icons.error_outline_rounded,
            title: 'Something went wrong',
            subtitle: state.error!,
            actionLabel: 'Retry',
            onAction: () =>
                ref.read(deliveryChallansProvider.notifier).refresh(),
          ),
        ],
      );
    }

    if (state.deliveryChallans.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          EmptyStateWidget(
            icon: Icons.local_shipping_outlined,
            title: 'No Delivery Challans Found',
            subtitle: 'Create a delivery challan or convert from an estimate.',
            actionLabel: 'Create Challan',
            onAction: () => context.push('/create-delivery-challan'),
          ),
        ],
      );
    }

    if (AdaptiveLayout.isDesktop(context)) {
      final rows = state.deliveryChallans.map((challan) {
        final formattedDate = DateFormat('dd MMM yyyy').format(challan.challanDate);
        final id = challan.id ?? '';

        return DesktopTableRow(
          onTap: () => context.push('/delivery-challan-details/$id', extra: challan),
          cells: [
            Text(
              'Challan No. ${challan.challanNumber ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            Text(
              challan.deliveryChallanFor.customerName,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            Text(
              formattedDate,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            Text(
              'Qty: ${challan.totalQuantity}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                challan.status.toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            OutlinedButton(
              onPressed: () => context.push('/delivery-challan-details/$id', extra: challan),
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
              DesktopTableColumn(label: 'Challan #', flex: 2),
              DesktopTableColumn(label: 'Customer', flex: 3),
              DesktopTableColumn(label: 'Date', flex: 2),
              DesktopTableColumn(label: 'Total Qty', flex: 2),
              DesktopTableColumn(label: 'Status', flex: 2),
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
      itemCount: state.deliveryChallans.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.deliveryChallans.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final challan = state.deliveryChallans[index];
        final formattedDate =
            DateFormat('dd MMM yyyy').format(challan.challanDate);

        return DocumentCard(
          documentNumber: 'Challan No. ${challan.challanNumber ?? ''}',
          customerName: challan.deliveryChallanFor.customerName,
          formattedDate: formattedDate,
          documentType: DocumentType.report,
          statusText: challan.status.toUpperCase(),
          isPending: false,
          amount: 'Qty: ${challan.totalQuantity}',
          onTap: () {
            context.push('/delivery-challan-details/${challan.id}',
                extra: challan);
          },
        );
      },
    );
  }
}
