import 'dart:async';

import 'package:animations/animations.dart';
import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:costing_master/costings/calculator/costing_calculator_screen.dart';
import 'package:costing_master/costings/notifier/costings_notifier.dart';
import 'package:costing_master/costings/quote/quote_screen.dart';
import 'package:costing_master/domain/costing_calculator.dart';
import 'package:costing_master/domain/money.dart';
import 'package:costing_master/model/client.dart';
import 'package:costing_master/model/costing.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/theme/motion.dart';
import 'package:costing_master/widgets/empty_state.dart';
import 'package:costing_master/widgets/entrance.dart';
import 'package:costing_master/widgets/network_thumb.dart';
import 'package:costing_master/widgets/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _Sort { newest, price, designNo }

/// A client's designs as a searchable grid of photo cards.
class CostingListing extends ConsumerStatefulWidget {
  final Client client;

  const CostingListing({super.key, required this.client});

  @override
  ConsumerState<CostingListing> createState() => _CostingListingState();
}

class _CostingListingState extends ConsumerState<CostingListing> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
  _Sort _sort = _Sort.newest;
  bool _animateEntrance = true;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _query = text.trim().toLowerCase());
    });
  }

  List<Costing> _visible(List<Costing> all) {
    final filtered = _query.isEmpty
        ? [...all]
        : all
            .where((c) =>
                c.sariName.toLowerCase().contains(_query) ||
                (c.designNo?.toString().contains(_query) ?? false))
            .toList();
    switch (_sort) {
      case _Sort.newest:
        filtered.sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));
      case _Sort.price:
        filtered.sort((a, b) => _price(b).compareTo(_price(a)));
      case _Sort.designNo:
        filtered.sort(
            (a, b) => (a.designNo ?? 1 << 30).compareTo(b.designNo ?? 1 << 30));
    }
    return filtered;
  }

  static double _price(Costing c) => CostingCalculator.compute(c).grandTotal;

  Widget _calculator(Costing? costing) => CostingCalculatorScreen(
        clientGuid: widget.client.guid,
        clientName: widget.client.name,
        userUid: ref.read(authProvider).value?.uid ?? widget.client.createdBy,
        costing: costing,
      );

  void _openQuote(Costing costing) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          QuoteScreen(costing: costing, clientName: widget.client.name),
    ));
  }

  Future<void> _showActions(Costing costing) async {
    unawaited(HapticFeedback.selectionClick());
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('કોસ્ટિંગ જુઓ / શેર કરો'),
              subtitle: const Text('View & share quote'),
              onTap: () => Navigator.pop(context, 'quote'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('સુધારો'),
              subtitle: const Text('Edit costing'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'quote') _openQuote(costing);
    if (action == 'edit') {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => _calculator(costing)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = costingsProvider(widget.client.guid);
    final costings = ref.watch(provider);
    final count = costings.value?.length;

    return Scaffold(
      floatingActionButton: OpenContainer(
        transitionType: ContainerTransitionType.fadeThrough,
        transitionDuration: Motion.of(context, Motion.slow),
        closedColor: context.colors.primary,
        openColor: context.colors.surface,
        closedElevation: 6,
        closedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onClosed: (_) => _animateEntrance = false,
        openBuilder: (_, __) => _calculator(null),
        closedBuilder: (_, open) => SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: context.colors.onPrimary),
                const SizedBox(width: 8),
                Text(
                  'નવી કોસ્ટિંગ',
                  style: TextStyle(
                    color: context.colors.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(provider.future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.client.name),
                  AnimatedSwitcher(
                    duration: Motion.of(context, Motion.fast),
                    child: Text(
                      count == null ? ' ' : '$count ડિઝાઇન',
                      key: ValueKey(count),
                      style: context.text.labelMedium
                          ?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: _onSearch,
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          hintText: 'નામ કે ડિઝાઇન નંબર',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<_Sort>(
                      tooltip: 'Sort',
                      initialValue: _sort,
                      onSelected: (s) => setState(() => _sort = s),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: _Sort.newest,
                            child: Text('નવી પહેલા · Newest')),
                        PopupMenuItem(
                            value: _Sort.price, child: Text('ભાવ · Price')),
                        PopupMenuItem(
                            value: _Sort.designNo,
                            child: Text('ડિઝાઇન નંબર · Design no.')),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceContainerHighest
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.sort_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ...switch (costings) {
              AsyncValue(:final value?) => _grid(value),
              AsyncError() => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: 'કોસ્ટિંગ લોડ ન થઈ',
                      message: 'ઇન્ટરનેટ તપાસીને ફરી પ્રયત્ન કરો',
                      actionLabel: 'ફરી પ્રયત્ન કરો',
                      onAction: () => ref.invalidate(provider),
                    ),
                  ),
                ],
              _ => [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid.builder(
                      gridDelegate: _gridDelegate,
                      itemCount: 6,
                      itemBuilder: (_, __) => const Skeleton(
                          borderRadius: BorderRadius.all(Radius.circular(20))),
                    ),
                  ),
                ],
            },
          ],
        ),
      ),
    );
  }

  static const _gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 240,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 0.68,
  );

  List<Widget> _grid(List<Costing> all) {
    if (all.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.diamond_outlined,
            title: 'હજુ કોઈ કોસ્ટિંગ નથી',
            message: 'નીચે "નવી કોસ્ટિંગ" દબાવીને પહેલી ડિઝાઇનનો ભાવ કાઢો.',
          ),
        ),
      ];
    }
    final visible = _visible(all);
    if (visible.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.search_off_rounded,
            title: 'કંઈ મળ્યું નહીં',
            message: 'બીજું નામ અથવા ડિઝાઇન નંબર અજમાવો',
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        sliver: SliverGrid.builder(
          gridDelegate: _gridDelegate,
          itemCount: visible.length,
          itemBuilder: (context, index) {
            final costing = visible[index];
            return Entrance(
              key: ValueKey(costing.guid),
              index: index,
              enabled: _animateEntrance,
              child: OpenContainer(
                transitionType: ContainerTransitionType.fadeThrough,
                transitionDuration: Motion.of(context, Motion.slow),
                closedColor: context.colors.surfaceContainerLow,
                openColor: context.colors.surface,
                closedElevation: 0,
                closedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                      color:
                          context.colors.outlineVariant.withValues(alpha: 0.5)),
                ),
                onClosed: (_) => _animateEntrance = false,
                openBuilder: (_, __) => _calculator(costing),
                closedBuilder: (_, __) => _DesignCard(
                  costing: costing,
                  onLongPress: () => _showActions(costing),
                  onShare: () => _openQuote(costing),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }
}

class _DesignCard extends StatelessWidget {
  final Costing costing;
  final VoidCallback onLongPress;
  final VoidCallback onShare;

  const _DesignCard({
    required this.costing,
    required this.onLongPress,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final price = CostingCalculator.compute(costing).grandTotal;
    return RepaintBoundary(
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetworkThumb(url: costing.imageUrl),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.black45,
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'શેર · Share',
                        visualDensity: VisualDensity.compact,
                        onPressed: onShare,
                        icon: const Icon(Icons.ios_share_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                  if (costing.designNo != null)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${costing.designNo}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    costing.sariName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatRupees(price),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? context.brand.gold
                          : const Color(0xFF8A6D00),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
