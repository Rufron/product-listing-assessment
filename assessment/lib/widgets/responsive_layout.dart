import 'package:flutter/widgets.dart';


class _Breakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _Breakpoints.desktop) return desktop;
        if (constraints.maxWidth >= _Breakpoints.tablet) return tablet;
        return mobile;
      },
    );
  }
}
