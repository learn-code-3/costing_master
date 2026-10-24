import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:costing_master/constant/firebase_constants.dart';
import 'package:costing_master/model/client.dart';
import 'package:costing_master/provider/firebase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final clientRepositoryProvider = Provider((ref) {
  return ClientRepository(firestore: ref.watch(firestoreProvider));
});

class ClientRepository {
  final FirebaseFirestore _firestore;

  ClientRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _clients =>
      _firestore.collection(FirebaseConstants.clientsCollection);

  Future<void> createClient(Client client) =>
      _clients.doc(client.guid).set(client.toMap());

  Future<List<Client>> getUserClients(String createdByUid) async {
    final snapshot =
        await _clients.where('createdBy', isEqualTo: createdByUid).get();
    return [for (final doc in snapshot.docs) Client.fromMap(doc.data())];
  }
}
