import 'package:flutter/material.dart';

class FinarcAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FinarcAppBar({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
  });

  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title), actions: actions, bottom: bottom);
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(60 + (bottom?.preferredSize.height ?? 0));
}
