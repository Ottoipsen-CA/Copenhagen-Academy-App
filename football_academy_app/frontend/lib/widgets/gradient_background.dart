import 'package:flutter/material.dart';
import '../theme/colors.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final List<double>? stops;
  final Alignment? begin;
  final Alignment? end;
  
  const GradientBackground({
    Key? key,
    required this.child,
    this.colors,
    this.stops,
    this.begin,
    this.end,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin ?? AppColors.gradientBegin,
          end: end ?? AppColors.gradientEnd,
          colors: colors ?? AppColors.gradientBackground,
          stops: stops ?? AppColors.gradientStops,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: child,
      ),
    );
  }
} 