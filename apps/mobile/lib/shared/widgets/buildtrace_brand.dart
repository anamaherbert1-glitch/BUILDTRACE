import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BuildtraceBrand extends StatelessWidget {
  final double iconSize;
  final double wordmarkSize;
  final bool dark;
  const BuildtraceBrand({super.key, this.iconSize = 46, this.wordmarkSize = 23, this.dark = false});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: iconSize,
        height: iconSize,
        decoration: BoxDecoration(
          color: dark ? Colors.white : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(iconSize * .28),
        ),
        child: Icon(Icons.apartment_rounded, size: iconSize * .66, color: AppColors.primaryDark),
      ),
      const SizedBox(width: 9),
      RichText(text: TextSpan(children: [
        TextSpan(text: 'BUILD', style: TextStyle(fontSize: wordmarkSize, fontWeight: FontWeight.w800, color: dark ? Colors.white : AppColors.secondary, letterSpacing: -.7)),
        TextSpan(text: 'TRACE', style: TextStyle(fontSize: wordmarkSize, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: -.7)),
      ])),
    ],
  );
}
