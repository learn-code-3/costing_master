import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:costing_master/constant/firebase_constants.dart';
import 'package:costing_master/provider/firebase_provider.dart';
import 'package:costing_master/settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Business profile, quote style and theme, stored on `users/{uid}`.
class SettingsNotifier extends AsyncNotifier<AppSettings> {
  DocumentReference<Map<String, dynamic>>? _doc;

  @override
  Future<AppSettings> build() async {
    final user = await ref.watch(authProvider.future);
    if (user == null) return const AppSettings();
    _doc = ref
        .read(firestoreProvider)
        .collection(FirebaseConstants.usersCollection)
        .doc(user.uid);
    final snapshot = await _doc!.get();
    return AppSettings.fromMap(snapshot.data());
  }

  String? get uid => _doc?.id;

  AppSettings get current => state.value ?? const AppSettings();

  /// Applies the change locally right away, then persists it.
  Future<void> save(AppSettings settings) async {
    final previous = state.value;
    state = AsyncData(settings);
    try {
      await _doc?.set(settings.toMap(), SetOptions(merge: true));
    } catch (_) {
      if (previous != null) state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> edit(AppSettings Function(AppSettings) change) =>
      save(change(state.value ?? const AppSettings()));
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

final themeModeProvider = Provider<ThemeMode>((ref) => ref.watch(
    settingsProvider.select((s) => s.value?.themeMode ?? ThemeMode.system)));
