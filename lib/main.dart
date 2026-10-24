import 'package:costing_master/screens/splash_screen.dart';
import 'package:costing_master/settings/settings_notifier.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/widgets/offline_banner.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: CostingMasterApp()));
}

class CostingMasterApp extends ConsumerWidget {
  const CostingMasterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Costing Master',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      builder: (context, child) => Column(
        children: [
          Expanded(child: child ?? const SizedBox.shrink()),
          const OfflineBanner(),
        ],
      ),
      home: const SplashScreen(),
    );
  }
}
