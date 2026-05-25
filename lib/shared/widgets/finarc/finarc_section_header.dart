import 'package:flutter/material.dart';

class FinarcSectionHeader extends StatelessWidget {
  const FinarcSectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        ?trailing,
      ],
    );
  }
}
