import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/finarc/finarc_widgets.dart';
import 'app_routes.dart';

class RouteFallbackScreen extends StatelessWidget {
  const RouteFallbackScreen({
    super.key,
    required this.title,
    required this.message,
    this.backRoute = AppRoutes.home,
  });

  final String title;
  final String message;
  final String backRoute;

  @override
  Widget build(BuildContext context) {
    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Navigation Error'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FinarcEmptyState(title: title, subtitle: message),
              const SizedBox(height: 12),
              FinarcSecondaryButton(
                onPressed: () => context.go(backRoute),
                label: 'Go Back',
                icon: Icons.arrow_back_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
