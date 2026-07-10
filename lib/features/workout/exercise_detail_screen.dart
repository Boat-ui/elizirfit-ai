import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/exercise.dart';
import '../../core/providers/app_providers.dart';

/// Shows one exercise's full detail. If [pickerMode] is true (opened from
/// Active Workout's "Add exercise" flow), an "Add to workout" button pops
/// this screen with the exercise name as the result.
class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId, this.pickerMode = false});
  final String exerciseId;
  final bool pickerMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(exerciseRepositoryProvider).getById(exerciseId);

    return Scaffold(
      appBar: AppBar(title: const Text('Exercise')),
      body: FutureBuilder<ExerciseModel?>(
        future: exerciseAsync,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final exercise = snapshot.data;
          if (exercise == null) {
            return const Center(child: Text('Exercise not found.'));
          }
          return _buildBody(context, exercise);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, ExerciseModel exercise) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(exercise.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (exercise.category != null) Chip(label: Text(exercise.category!)),
            if (exercise.difficulty != null) Chip(label: Text(exercise.difficulty!)),
            if (exercise.equipment != null) Chip(label: Text(exercise.equipment!)),
          ],
        ),
        const SizedBox(height: 20),
        if (exercise.primaryMusclesList.isNotEmpty) ...[
          Text('Primary muscles', style: Theme.of(context).textTheme.titleSmall),
          Text(exercise.primaryMusclesList.join(', ')),
          const SizedBox(height: 12),
        ],
        if (exercise.secondaryMusclesList.isNotEmpty) ...[
          Text('Secondary muscles', style: Theme.of(context).textTheme.titleSmall),
          Text(exercise.secondaryMusclesList.join(', ')),
          const SizedBox(height: 12),
        ],
        if (exercise.instructions != null) ...[
          Text('How to do it', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(exercise.instructions!),
        ],
        if (pickerMode) ...[
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(exercise.name),
            icon: const Icon(Icons.add),
            label: const Text('Add to workout'),
          ),
        ],
      ],
    );
  }
}
