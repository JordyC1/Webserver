// animations/fade_scale_transition.dart
import 'package:flutter/material.dart';

class FadeScaleTransitionWrapper extends StatelessWidget {
  final Widget child;

  const FadeScaleTransitionWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.9, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        builder: (context, scale, child) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, opacity, child) {
              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: child,
                ),
              );
            },
            child: child,
          );
        },
        child: child,
      ),
    );
  }
}
