import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/repositories/meal_log_repository.dart';
import 'food_search_screen.dart';

class NutritionHomeScreen extends ConsumerWidget {
  const NutritionHomeScreen({super.key});

  static const _mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalsAsync = ref.watch(todaysTotalsProvider);
    final mealsAsync = ref.watch(todaysMealsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSearch(context),
        icon: const Icon(Icons.add),
        label: const Text('Log meal'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(mealLogRefreshProvider.notifier).state++,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            totalsAsync.when(
              data: (totals) => _TotalsCard(totals: totals),
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Error loading totals: $e'),
            ),
            const SizedBox(height: 24),
            Text("Today's meals", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            mealsAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'Nothing logged yet today.\nTap "Log meal" to search for a food.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final type in _mealTypes)
                      _MealTypeSection(
                        mealType: type,
                        entries: entries.where((e) => e.log.mealType == type).toList(),
                      ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Error loading meals: $e'),
            ),
          ],
        ),
      ),
    );
  }

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FoodSearchScreen()),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.totals});
  final DailyTotals totals;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${totals.calories.round()} kcal today',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MacroPill(label: 'Protein', grams: totals.proteinG, color: Colors.redAccent),
                _MacroPill(label: 'Carbs', grams: totals.carbsG, color: Colors.orangeAccent),
                _MacroPill(label: 'Fat', grams: totals.fatG, color: Colors.blueAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  const _MacroPill({required this.label, required this.grams, required this.color});
  final String label;
  final double grams;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text('${grams.round()}g', style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _MealTypeSection extends ConsumerWidget {
  const _MealTypeSection({required this.mealType, required this.entries});
  final String mealType;
  final List<MealLogEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final totalCal = entries.fold<double>(0, (sum, e) => sum + e.calories);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    mealType[0].toUpperCase() + mealType.substring(1),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text('${totalCal.round()} kcal'),
                ],
              ),
            ),
            for (final entry in entries)
              ListTile(
                dense: true,
                title: Text(entry.foodName),
                subtitle: Text(
                  '${entry.log.quantityServings.toStringAsFixed(entry.log.quantityServings == entry.log.quantityServings.roundToDouble() ? 0 : 1)}× serving'
                  '${entry.verified ? '' : ' · estimated'}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${entry.calories.round()} kcal'),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () async {
                        await ref.read(mealLogRepositoryProvider).deleteLog(entry.log.id);
                        ref.read(mealLogRefreshProvider.notifier).state++;
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
