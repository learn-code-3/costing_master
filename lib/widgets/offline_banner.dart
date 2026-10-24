import 'package:costing_master/connectivity/notifier/connectivity_notifier.dart';
import 'package:costing_master/theme/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A slim bar that slides in at the bottom while the device is offline.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline =
        ref.watch(connectivityProvider.select((state) => state.value == false));
    final scheme = Theme.of(context).colorScheme;

    return AnimatedSize(
      duration: Motion.of(context, Motion.medium),
      curve: Motion.emphasized,
      child: offline
          ? Material(
              color: scheme.errorContainer,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded,
                          size: 18, color: scheme.onErrorContainer),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'ઇન્ટરનેટ નથી · No internet connection',
                          style: TextStyle(
                            color: scheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
