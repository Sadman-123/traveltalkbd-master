import 'dart:async';
import 'package:flutter/material.dart';

/// Shows an animated splash (logo drops from top + subtle bounce)
/// until [loadFuture] completes, then reveals [child].
class AppSplashGate extends StatefulWidget {
  final Future<void> loadFuture;
  final Widget child;

  /// Ensures the splash is visible for at least this duration
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
  late final Animation<double> _drop;
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

    // Top → Center drop animation
    _drop = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

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

    _gateFuture =
        _combineFutures(widget.loadFuture, widget.minDisplayDuration);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _combineFutures(
      Future<void> load, Duration minDuration) async {
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
          child: ready ? widget.child : _SplashView(_drop, _scale, _fade),
        );
      },
    );
  }
}

class _SplashView extends StatelessWidget {
  final Animation<double> drop;
  final Animation<double> scale;
  final Animation<double> fade;

  const _SplashView(this.drop, this.scale, this.fade);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: fade,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Start ABOVE the center
              final startY = -constraints.maxHeight * 0.45;

              return AnimatedBuilder(
                animation: drop,
                builder: (context, child) {
                  // drop=0 → above center
                  // drop=1 → center (with small overshoot)
                  final y = (1 - drop.value) * startY;
                  return Transform.translate(
                    offset: Offset(0, y),
                    child: child,
                  );
                },
                child: ScaleTransition(
                  scale: scale,
                  child: Image.asset(
                    'assets/trv2.png',
                    width: 140,
                    height: 140,
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
