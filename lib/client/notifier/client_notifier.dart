import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:costing_master/client/repository/client_repository.dart';
import 'package:costing_master/model/client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DuplicateClientException implements Exception {
  final String name;
  const DuplicateClientException(this.name);
}

class ClientNotifier extends AsyncNotifier<List<Client>> {
  @override
  Future<List<Client>> build() async {
    final user = await ref.watch(authProvider.future);
    if (user == null) return const [];
    final clients =
        await ref.read(clientRepositoryProvider).getUserClients(user.uid);
    return clients..sort(_byName);
  }

  /// Adds a client; throws [DuplicateClientException] if the name exists.
  Future<Client> createClient(String name) async {
    final trimmed = name.trim();
    final current = state.value ?? const <Client>[];
    if (current.any((c) => c.name.toLowerCase() == trimmed.toLowerCase())) {
      throw DuplicateClientException(trimmed);
    }
    final user = (await ref.read(authProvider.future))!;
    final client = Client(name: trimmed, createdBy: user.uid);
    await ref.read(clientRepositoryProvider).createClient(client);
    state = AsyncData([...current, client]..sort(_byName));
    return client;
  }

  static int _byName(Client a, Client b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

final clientsProvider =
    AsyncNotifierProvider<ClientNotifier, List<Client>>(ClientNotifier.new);
