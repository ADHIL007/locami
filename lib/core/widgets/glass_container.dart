import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:locami/theme/theme_provider.dart';
import 'package:provider/provider.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final BorderRadius? customBorderRadius;
  final Color color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxBorder? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.1,
    this.borderRadius = 20.0,
    this.customBorderRadius,
    this.color = Colors.white,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final uiMode = themeProvider.uiMode;
    
    final currentBlur = uiMode == 'low' ? 0.0 : (uiMode == 'mid' ? blur / 2 : blur);
    final currentOpacity = uiMode == 'low' ? opacity * 1.5 : opacity;
    final isHigh = uiMode == 'high';

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: currentOpacity.clamp(0.0, 1.0)),
        gradient: isHigh
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (themeProvider.isDarkMode ? Colors.white : Colors.white).withValues(alpha: 0.05),
                  (themeProvider.isDarkMode ? Colors.black : Colors.black).withValues(alpha: 0.02),
                ],
              )
            : null,
        borderRadius:
            customBorderRadius ?? BorderRadius.circular(borderRadius),
        border: border ?? Border.all(
          color: (themeProvider.isDarkMode ? Colors.white : Colors.black).withValues(alpha: isHigh ? 0.12 : 0.08),
          width: isHigh ? 1.8 : 1.5,
        ),
        boxShadow: isHigh ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: -5,
          )
        ] : null,
      ),
      child: child,
    );

    if (currentBlur > 0) {
      content = ClipRRect(
        borderRadius: customBorderRadius ?? BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: currentBlur, sigmaY: currentBlur),
          child: content,
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: customBorderRadius ?? BorderRadius.circular(borderRadius),
        child: content,
      ),
    );
  }
}
