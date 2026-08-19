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

    return Scaffold(
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
