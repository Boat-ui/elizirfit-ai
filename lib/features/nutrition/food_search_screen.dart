import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import 'food_detail_screen.dart';

class FoodSearchScreen extends ConsumerWidget {
  const FoodSearchScreen({super.key});

  static const _categories = [
    'staple', 'soup', 'protein', 'snack', 'drink', 'breakfast', 'fruit', 'vegetable',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(foodSearchProvider);
    final selectedCategory = ref.watch(foodSearchCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search foods (e.g. jollof, tilapia)',
            border: InputBorder.none,
          ),
          onChanged: (value) => ref.read(foodSearchQueryProvider.notifier).state = value,
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _CategoryChip(
                  label: 'All',
                  selected: selectedCategory == null,
                  onTap: () => ref.read(foodSearchCategoryProvider.notifier).state = null,
                ),
                for (final c in _categories)
                  _CategoryChip(
                    label: c[0].toUpperCase() + c.substring(1),
                    selected: selectedCategory == c,
                    onTap: () => ref.read(foodSearchCategoryProvider.notifier).state = c,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: resultsAsync.when(
              data: (foods) {
                if (foods.isEmpty) {
                  return const Center(child: Text('No foods found.'));
                }
                return ListView.separated(
                  itemCount: foods.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final food = foods[i];
                    return ListTile(
                      title: Text(food.name),
                      subtitle: Text(
                        '${food.calories.round()} kcal per ${food.servingSizeG.round()}g'
                        '${food.verified ? '' : ' · estimated'}',
                      ),
                      trailing: food.verified
                          ? null
                          : const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => FoodDetailScreen(foodId: food.id)),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
