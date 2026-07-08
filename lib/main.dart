import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/app_providers.dart';
import 'features/nutrition/nutrition_home_screen.dart';

void main() {
  runApp(const ProviderScope(child: ElizirFitApp()));
}

class ElizirFitApp extends StatelessWidget {
  const ElizirFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ElizirFit AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00A651)),
        useMaterial3: true,
      ),
      home: const _AppRoot(),
    );
  }
}

/// Waits on [appInitProvider] (DB open + food dataset seed) before showing
/// any real screen. On success, goes straight to Nutrition Home — this is
/// the app's actual entry point now that Step 2 is built.
class _AppRoot extends ConsumerWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initAsync = ref.watch(appInitProvider);

    return initAsync.when(
      data: (_) => const NutritionHomeScreen(),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, stack) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to start ElizirFit AI:\n$e', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
