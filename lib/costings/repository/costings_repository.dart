import 'dart:isolate';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:costing_master/constant/firebase_constants.dart';
import 'package:costing_master/model/costing.dart';
import 'package:costing_master/provider/firebase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final costingsRepositoryProvider = Provider((ref) {
  return CostingsRepository(firestore: ref.watch(firestoreProvider));
});

/// Above this many documents, parsing moves to a background isolate so
/// scrolling and transitions stay smooth.
const _isolateParseThreshold = 50;

class CostingsRepository {
  final FirebaseFirestore _firestore;

  CostingsRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _costings =>
      _firestore.collection(FirebaseConstants.costingsColletion);

  Future<List<Costing>> getUserCostings(
      String createdBy, String clientGuid) async {
    final snapshot = await _costings
        .where('createdBy', isEqualTo: createdBy)
        .where('clientGuid', isEqualTo: clientGuid)
        .get();
    final maps = [for (final doc in snapshot.docs) doc.data()];
    if (maps.length < _isolateParseThreshold) return _parse(maps);
    return Isolate.run(() => _parse(maps));
  }

  /// Creates or overwrites the costing document (its id is the costing guid).
  Future<void> saveCosting(Costing costing) =>
      _costings.doc(costing.guid).set(costing.toMap());

  static List<Costing> _parse(List<Map<String, dynamic>> maps) =>
      [for (final map in maps) Costing.fromMap(map)];
}
