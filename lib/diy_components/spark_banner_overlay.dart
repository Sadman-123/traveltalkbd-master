import 'package:flutter/material.dart';

/// Wraps a widget with a left-to-right spark/splash animation overlay.
/// Used for text-type promotional banners to add a shimmer effect.
/// The spark is clipped to stay inside the banner bounds.
class SparkBannerOverlay extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color sparkColor;
  final BorderRadius borderRadius;

  const SparkBannerOverlay({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 2500),
    this.sparkColor = Colors.white,
    required this.borderRadius,
  }) : super(key: key);

  @override
  State<SparkBannerOverlay> createState() => _SparkBannerOverlayState();
}

class _SparkBannerOverlayState extends State<SparkBannerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..forward();
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          widget.child,
          Positioned.fill(
            child: ClipRect(
              child: LayoutBuilder(
                builder: (context, constraints) {
              final sparkWidth = constraints.maxWidth * 0.25;
              return IgnorePointer(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) {
                    // Keep spark within bounds, end before right edge
                    final endInset = constraints.maxWidth * 0.08;
                    final maxLeft = constraints.maxWidth - sparkWidth - endInset;
                    final left = maxLeft * _animation.value;
                    return Transform.translate(
                      offset: Offset(left, 0),
                      child: SizedBox(
                        width: sparkWidth,
                        height: constraints.maxHeight,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.transparent,
                                widget.sparkColor.withOpacity(0.0),
                                widget.sparkColor.withOpacity(0.5),
                                widget.sparkColor.withOpacity(0.8),
                                widget.sparkColor.withOpacity(0.5),
                                widget.sparkColor.withOpacity(0.0),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.2, 0.4, 0.5, 0.6, 0.8, 1.0],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
            ),
          ),
        ],
      ),
    );
  }
}
