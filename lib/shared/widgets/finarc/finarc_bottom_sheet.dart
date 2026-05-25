import 'package:flutter/material.dart';

class FinarcBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    bool isScrollControlled = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      showDragHandle: true,
      builder: (context) => SafeArea(child: child),
    );
  }
}
