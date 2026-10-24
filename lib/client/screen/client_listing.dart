import 'dart:async';

import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:costing_master/auth/screens/login.dart';
import 'package:costing_master/client/notifier/client_notifier.dart';
import 'package:costing_master/costings/screens/costing_listing.dart';
import 'package:costing_master/model/client.dart';
import 'package:costing_master/settings/app_settings.dart';
import 'package:costing_master/settings/settings_notifier.dart';
import 'package:costing_master/settings/settings_screen.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/widgets/app_snack.dart';
import 'package:costing_master/widgets/brand_mark.dart';
import 'package:costing_master/widgets/empty_state.dart';
import 'package:costing_master/widgets/entrance.dart';
import 'package:costing_master/widgets/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClientListing extends ConsumerStatefulWidget {
  const ClientListing({super.key});

  @override
  ConsumerState<ClientListing> createState() => _ClientListingState();
}

class _ClientListingState extends ConsumerState<ClientListing> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
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

  Future<void> _logOut() async {
    final navigator = Navigator.of(context);
    await ref.read(authProvider.notifier).logOut();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _openClient(Client client) {
    _animateEntrance = false;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CostingListing(client: client),
    ));
  }

  Future<void> _addClient() async {
    final created = await showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddClientSheet(),
    );
    if (created != null && mounted) {
      showAppSnack(context, '${created.name} ઉમેરાયા', type: SnackType.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientsProvider);
    final userName = ref.watch(authProvider.select((u) => u.value?.name ?? ''));
    final businessName = ref.watch(
        settingsProvider.select((s) => s.value?.profile.businessName ?? ''));
    final firstName = userName.trim().split(' ').first;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addClient,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('ગ્રાહક ઉમેરો'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(clientsProvider.future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 168,
              foregroundColor: Colors.white,
              backgroundColor: context.brand.plumDeep,
              title: const Text('ગ્રાહકો'),
              actions: [
                IconButton(
                  tooltip: 'મારો બિઝનેસ',
                  icon: const Icon(Icons.storefront_outlined),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const SettingsScreen())),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Account',
                  icon: const Icon(Icons.account_circle_outlined),
                  onSelected: (value) {
                    if (value == 'logout') _logOut();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'logout',
                      child: ListTile(
                        leading: Icon(Icons.logout_rounded),
                        title: Text('લૉગ આઉટ'),
                        subtitle: Text('Log out'),
                      ),
                    ),
                  ],
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: DecoratedBox(
                  decoration:
                      BoxDecoration(gradient: context.brand.heroGradient),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  firstName.isEmpty
                                      ? 'નમસ્તે 🙏'
                                      : 'નમસ્તે, $firstName 🙏',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  businessName.isEmpty
                                      ? 'આજે કોની કોસ્ટિંગ બનાવીશું?'
                                      : businessName,
                                  style: TextStyle(
                                    color: context.brand.gold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const BrandMark(size: 56),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: TextField(
                  controller: _search,
                  onChanged: _onSearch,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'ગ્રાહક શોધો · Search clients',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: ValueListenableBuilder(
                      valueListenable: _search,
                      builder: (_, value, __) => value.text.isEmpty
                          ? const SizedBox.shrink()
                          : IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _search.clear();
                                _onSearch('');
                              },
                            ),
                    ),
                  ),
                ),
              ),
            ),
            ...switch (clients) {
              AsyncValue(:final value?) => _clientSlivers(value),
              AsyncError() => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: 'ગ્રાહકો લોડ ન થયા',
                      message: 'ઇન્ટરનેટ તપાસીને ફરી પ્રયત્ન કરો',
                      actionLabel: 'ફરી પ્રયત્ન કરો',
                      onAction: () => ref.invalidate(clientsProvider),
                    ),
                  ),
                ],
              _ => [
                  SliverList.builder(
                    itemCount: 6,
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Skeleton(height: 72),
                    ),
                  ),
                ],
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _clientSlivers(List<Client> all) {
    if (all.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.groups_2_outlined,
            title: 'હજુ કોઈ ગ્રાહક નથી',
            message: 'પહેલો ગ્રાહક ઉમેરો અને તેમની સાડીની કોસ્ટિંગ બનાવો.',
            actionLabel: 'ગ્રાહક ઉમેરો',
            onAction: _addClient,
          ),
        ),
      ];
    }
    final clients = _query.isEmpty
        ? all
        : all.where((c) => c.name.toLowerCase().contains(_query)).toList();
    if (clients.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.search_off_rounded,
            title: 'કોઈ ગ્રાહક મળ્યા નહીં',
            message: '"${_search.text}" નામે કોઈ ગ્રાહક નથી',
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        sliver: SliverList.builder(
          itemCount: clients.length,
          itemBuilder: (context, index) {
            final client = clients[index];
            return Entrance(
              key: ValueKey(client.guid),
              index: index,
              enabled: _animateEntrance,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _ClientTile(
                    client: client, onTap: () => _openClient(client)),
              ),
            );
          },
        ),
      ),
    ];
  }
}

class _ClientTile extends StatelessWidget {
  final Client client;
  final VoidCallback onTap;

  const _ClientTile({required this.client, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color =
        quoteAccents[client.name.hashCode.abs() % quoteAccents.length];
    final initials = client.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w.characters.first.toUpperCase())
        .join();
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            initials,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(
          client.name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16.5),
        ),
        subtitle: const Text('કોસ્ટિંગ જુઓ · View costings'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _AddClientSheet extends ConsumerStatefulWidget {
  const _AddClientSheet();

  @override
  ConsumerState<_AddClientSheet> createState() => _AddClientSheetState();
}

class _AddClientSheetState extends ConsumerState<_AddClientSheet> {
  final _name = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'નામ લખો · Enter a name');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final client =
          await ref.read(clientsProvider.notifier).createClient(name);
      unawaited(HapticFeedback.lightImpact());
      if (mounted) Navigator.pop(context, client);
    } on DuplicateClientException {
      setState(() => _error = 'આ નામે ગ્રાહક પહેલેથી છે · Already exists');
    } catch (_) {
      setState(() => _error = 'સેવ ન થયું, ઇન્ટરનેટ તપાસો');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('નવો ગ્રાહક',
              style: context.text.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          Text('New client',
              style: context.text.bodyMedium
                  ?.copyWith(color: context.colors.onSurfaceVariant)),
          const SizedBox(height: 18),
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'ગ્રાહકનું નામ',
              hintText: 'Client name',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              errorText: _error,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Text('સેવ કરો'),
          ),
        ],
      ),
    );
  }
}
