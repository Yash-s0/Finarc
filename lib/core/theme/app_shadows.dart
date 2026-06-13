import 'package:flutter/material.dart';

class AppShadows {
  static const card = [
    BoxShadow(color: Color(0x50030A12), blurRadius: 16, offset: Offset(0, 8)),
  ];

  static const cardLight = [
    BoxShadow(color: Color(0x14030A12), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const fab = [
    BoxShadow(color: Color(0x1F4A58FF), blurRadius: 8, offset: Offset(0, 3)),
  ];

  static const heroGlow = [
    BoxShadow(
      color: Color(0x186366F1),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: 2,
    ),
  ];

  static const heroGlowLight = [
    BoxShadow(
      color: Color(0x0F6366F1),
      blurRadius: 20,
      offset: Offset(0, 6),
      spreadRadius: 1,
    ),
  ];

  static const bottomSheet = [
    BoxShadow(color: Color(0x28000000), blurRadius: 24, offset: Offset(0, -4)),
  ];
}
