import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:costing_master/auth/screens/sign_in_button.dart';
import 'package:costing_master/client/screen/client_listing.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/widgets/app_snack.dart';
import 'package:costing_master/widgets/brand_mark.dart';
import 'package:costing_master/widgets/entrance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authProvider, (previous, next) {
      switch (next) {
        case AsyncData(value: _?):
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ClientListing()));
        case AsyncError():
          showAppSnack(
              context, 'સાઇન ઇન ન થયું, ફરી પ્રયત્ન કરો · Sign-in failed',
              type: SnackType.error);
        default:
      }
    });

    const features = [
      (Icons.diamond_outlined, 'ડાયમંડ, સગડી, મજૂરી – એક જ સ્ક્રીન પર'),
      (Icons.bolt_rounded, 'ટાઇપ કરતાં જ અંતિમ ભાવ તૈયાર'),
      (Icons.share_rounded, 'તમારા બિઝનેસના નામ સાથે WhatsApp પર શેર'),
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: context.brand.heroGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        children: [
                          SizedBox(height: 24),
                          Hero(tag: 'brand-mark', child: BrandMark(size: 112)),
                          SizedBox(height: 20),
                          BrandWordmark(color: Colors.white),
                          SizedBox(height: 12),
                          Text(
                            'સાડીની કોસ્ટિંગ સેકન્ડમાં',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Column(
                        children: [
                          for (final (i, (icon, text)) in features.indexed)
                            Entrance(
                              index: i + 2,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(icon,
                                          color: context.brand.gold, size: 20),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        text,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                          const SignInButton(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
