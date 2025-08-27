import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets? padding;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.maxWidth = 600, // Maximum width for web
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      // On mobile, use full width with optional padding
      return padding != null 
          ? Padding(padding: padding!, child: child)
          : child;
    }

    // On web, constrain width and center content
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          minHeight: MediaQuery.of(context).size.height,
        ),
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
        child: child,
      ),
    );
  }
}

class ResponsiveFormField extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveFormField({
    super.key,
    required this.child,
    this.maxWidth = 400, // Narrower for form fields
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return child;
    }

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );
  }
}

class ResponsiveButton extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveButton({
    super.key,
    required this.child,
    this.maxWidth = 300, // Reasonable button width
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return child;
    }

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );
  }
}