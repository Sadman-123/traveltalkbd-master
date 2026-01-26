import 'package:flutter/material.dart';

class AdaptiveHelper extends StatelessWidget {
  final Widget mobile;
  final Widget web;

  const AdaptiveHelper({
    super.key,
    required this.mobile,
    required this.web,
  });

  static const double webBreakpoint = 720;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    return width >= webBreakpoint ? web : mobile;
  }
}
