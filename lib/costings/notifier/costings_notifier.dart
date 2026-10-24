import 'dart:async';

import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:costing_master/costings/repository/costings_repository.dart';
import 'package:costing_master/model/costing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Costings of one client (the family argument is the client guid).
class CostingsNotifier extends AsyncNotifier<List<Costing>> {
  CostingsNotifier(this.clientGuid);

  final String clientGuid;

  @override
  Future<List<Costing>> build() async {
    final user = await ref.watch(authProvider.future);
    if (user == null) return const [];
    return ref
        .read(costingsRepositoryProvider)
        .getUserCostings(user.uid, clientGuid);
  }

  /// Saves [costing] and updates the list in place, without a refetch.
  Future<void> save(Costing costing) async {
    await ref.read(costingsRepositoryProvider).saveCosting(costing);
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      costing,
      for (final c in current)
        if (c.guid != costing.guid) c,
    ]);
  }
}

final costingsProvider =
    AsyncNotifierProvider.family<CostingsNotifier, List<Costing>, String>(
        CostingsNotifier.new);
