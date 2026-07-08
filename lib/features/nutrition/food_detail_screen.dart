import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/food.dart';
import '../../core/providers/app_providers.dart';

/// Covers both "Food Detail" and "Log Meal" from the spec's screen
/// inventory (Section 5) in one flow: macro breakdown, serving-size
/// adjuster, meal-type selector, live calorie preview, add-to-meal.
class FoodDetailScreen extends ConsumerStatefulWidget {
  const FoodDetailScreen({super.key, required this.foodId});
  final String foodId;

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  double _servings = 1;
  String _mealType = 'breakfast';
  bool _saving = false;

  static const _mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];

  @override
  Widget build(BuildContext context) {
    final foodAsync = ref.watch(foodRepositoryProvider).getById(widget.foodId);

    return Scaffold(
      appBar: AppBar(title: const Text('Food detail')),
      body: FutureBuilder<FoodModel?>(
        future: foodAsync,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final food = snapshot.data;
          if (food == null) {
            return const Center(child: Text('Food not found.'));
          }
          return _buildBody(context, food);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, FoodModel food) {
    final cal = food.calories * _servings;
    final protein = food.proteinG * _servings;
    final carbs = food.carbsG * _servings;
    final fat = food.fatG * _servings;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(food.name, style: Theme.of(context).textTheme.headlineSmall),
        if (food.localNamesList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Also known as: ${food.localNamesList.join(", ")}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (!food.verified)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Nutrition values are estimated from a standard recipe, not lab-verified.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),

        // Serving-size adjuster
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Servings (1 = ${food.servingSizeG.round()}g)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _servings > 0.5
                          ? () => setState(() => _servings = (_servings - 0.5).clamp(0.5, 20))
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        _servings.toStringAsFixed(_servings == _servings.roundToDouble() ? 0 : 1),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setState(() => _servings = (_servings + 0.5).clamp(0.5, 20)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Live macro preview
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('${cal.round()} kcal', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MacroText(label: 'Protein', grams: protein),
                    _MacroText(label: 'Carbs', grams: carbs),
                    _MacroText(label: 'Fat', grams: fat),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Meal-type selector
        Text('Add to', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final type in _mealTypes)
              ChoiceChip(
                label: Text(type[0].toUpperCase() + type.substring(1)),
                selected: _mealType == type,
                onSelected: (_) => setState(() => _mealType = type),
              ),
          ],
        ),
        const SizedBox(height: 24),

        FilledButton.icon(
          onPressed: _saving ? null : () => _addToMeal(food),
          icon: const Icon(Icons.check),
          label: Text(_saving ? 'Adding...' : 'Add to $_mealType'),
        ),
      ],
    );
  }

  Future<void> _addToMeal(FoodModel food) async {
    setState(() => _saving = true);
    try {
      final user = await ref.read(currentUserProvider.future);
      await ref.read(mealLogRepositoryProvider).logFood(
            userId: user.id,
            foodId: food.id,
            mealType: _mealType,
            quantityServings: _servings,
          );
      ref.read(mealLogRefreshProvider.notifier).state++;
      if (mounted) {
        Navigator.of(context)
          ..pop()
          ..pop(); // back through search screen to Nutrition Home
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _MacroText extends StatelessWidget {
  const _MacroText({required this.label, required this.grams});
  final String label;
  final double grams;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('${grams.round()}g', style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
