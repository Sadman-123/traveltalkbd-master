import 'dart:async';

import 'package:flutter/material.dart';

/// Shows an animated splash (logo rises + bounce) until [loadFuture] completes,
/// then reveals [child].
class AppSplashGate extends StatefulWidget {
  final Future<void> loadFuture;
  final Widget child;

  /// Ensures the splash is visible for at least this duration (prevents flicker
  /// when data is cached and loads instantly).
  final Duration minDisplayDuration;

  const AppSplashGate({
    super.key,
    required this.loadFuture,
    required this.child,
    this.minDisplayDuration = const Duration(milliseconds: 900),
  });

  @override
  State<AppSplashGate> createState() => _AppSplashGateState();
}

class _AppSplashGateState extends State<AppSplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rise;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  late final Future<void> _gateFuture;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // 0 -> 1 (with a small overshoot due to easeOutBack).
    // We'll convert this progress into a pixel-translate so the logo always
    // moves "from down to center" regardless of its own size.
    _rise = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.05, 0.55, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    _gateFuture = _combineFutures(widget.loadFuture, widget.minDisplayDuration);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _combineFutures(Future<void> load, Duration minDuration) async {
    final start = DateTime.now();
    await load;
    final elapsed = DateTime.now().difference(start);
    final remaining = minDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _gateFuture,
      builder: (context, snapshot) {
        final ready = snapshot.connectionState == ConnectionState.done;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: ready ? widget.child : _SplashView(_rise, _scale, _fade),
        );
      },
    );
  }
}

class _SplashView extends StatelessWidget {
  final Animation<double> rise;
  final Animation<double> scale;
  final Animation<double> fade;

  const _SplashView(this.rise, this.scale, this.fade);

  @override
  Widget build(BuildContext context) {
    // Match your app vibe but keep it neutral; logo is the focus.
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: Center(
        child: FadeTransition(
          opacity: fade,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // How far below center the logo starts (pixels).
              // Feel free to tune this number (0.40 - 0.55 are common).
              final startY = constraints.maxHeight * 0.45;

              return AnimatedBuilder(
                animation: rise,
                builder: (context, child) {
                  // When rise=0 => y = startY (below center)
                  // When rise=1 => y = 0 (exact center)
                  // With overshoot => y becomes slightly negative (bounce)
                  final y = (1 - rise.value) * startY;
                  return Transform.translate(offset: Offset(0, y), child: child);
                },
                child: ScaleTransition(
                  scale: scale,
                  child: Image.asset(
                    'assets/trv.png',
                    width: 240,
                    height: 240,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
