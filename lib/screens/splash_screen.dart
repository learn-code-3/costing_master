import 'dart:async';

import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:costing_master/auth/screens/login.dart';
import 'package:costing_master/client/screen/client_listing.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/widgets/brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Plays the brand animation while the signed-in user is resolved, then
/// routes to the clients home or the login screen.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  /// Long enough for the mark to finish drawing, never longer.
  static const _minimumShowTime = Duration(milliseconds: 1300);

  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final results = await Future.wait<Object?>([
      ref
          .read(authProvider.future)
          .then<Object?>((u) => u, onError: (_) => null),
      Future<void>.delayed(_minimumShowTime),
    ]);
    if (!mounted) return;
    final signedIn = results.first != null;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) =>
          signedIn ? const ClientListing() : const LoginScreen(),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: context.brand.heroGradient),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                  tag: 'brand-mark',
                  child: BrandMark(size: 132, animate: true)),
              SizedBox(height: 24),
              _FadeIn(
                delay: Duration(milliseconds: 600),
                child: BrandWordmark(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FadeIn extends StatefulWidget {
  final Duration delay;
  final Widget child;
  const _FadeIn({required this.delay, required this.child});

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> {
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () => setState(() => _visible = true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, 0.2),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 450),
        child: widget.child,
      ),
    );
  }
}
