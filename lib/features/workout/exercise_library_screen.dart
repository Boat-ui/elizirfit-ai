import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import 'exercise_detail_screen.dart';

/// Searchable/filterable exercise library (spec Section 5). When
/// [pickerMode] is true, tapping an exercise pops this screen with the
/// exercise name — used by Active Workout's "Add exercise" flow.
class ExerciseLibraryScreen extends ConsumerWidget {
  const ExerciseLibraryScreen({super.key, this.pickerMode = false});
  final bool pickerMode;

  static const _categories = [
    'chest', 'back', 'legs', 'shoulders', 'arms', 'core', 'cardio',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(exerciseSearchProvider);
    final selectedCategory = ref.watch(exerciseSearchCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: pickerMode,
          decoration: const InputDecoration(
            hintText: 'Search exercises (e.g. squat, curl)',
            border: InputBorder.none,
          ),
          onChanged: (value) => ref.read(exerciseSearchQueryProvider.notifier).state = value,
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
                  onTap: () => ref.read(exerciseSearchCategoryProvider.notifier).state = null,
                ),
                for (final c in _categories)
                  _CategoryChip(
                    label: c[0].toUpperCase() + c.substring(1),
                    selected: selectedCategory == c,
                    onTap: () => ref.read(exerciseSearchCategoryProvider.notifier).state = c,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: resultsAsync.when(
              data: (exercises) {
                if (exercises.isEmpty) {
                  return const Center(child: Text('No exercises found.'));
                }
                return ListView.separated(
                  itemCount: exercises.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final exercise = exercises[i];
                    return ListTile(
                      title: Text(exercise.name),
                      subtitle: Text([
                        if (exercise.difficulty != null) exercise.difficulty!,
                        if (exercise.equipment != null) exercise.equipment!,
                      ].join(' · ')),
                      trailing: pickerMode ? const Icon(Icons.add_circle_outline) : null,
                      onTap: () async {
                        final result = await Navigator.of(context).push<String>(
                          MaterialPageRoute(
                            builder: (_) => ExerciseDetailScreen(
                              exerciseId: exercise.id,
                              pickerMode: pickerMode,
                            ),
                          ),
                        );
                        if (result != null && context.mounted) {
                          Navigator.of(context).pop(result);
                        }
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
