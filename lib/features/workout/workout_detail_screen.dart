import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/workout.dart';
import '../../core/models/workout_set.dart';
import '../../core/providers/app_providers.dart';

/// Full past-session breakdown (spec Section 5).
class WorkoutDetailScreen extends ConsumerWidget {
  const WorkoutDetailScreen({super.key, required this.workoutId});
  final String workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(workoutRepositoryProvider).getWorkoutById(workoutId);
    final setsAsync = ref.watch(workoutSetsProvider(workoutId));

    return Scaffold(
      appBar: AppBar(title: const Text('Workout detail')),
      body: FutureBuilder<WorkoutModel?>(
        future: workoutAsync,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final workout = snapshot.data;
          if (workout == null) {
            return const Center(child: Text('Workout not found.'));
          }

          final started = DateTime.parse(workout.startedAt);
          final ended = workout.endedAt != null ? DateTime.parse(workout.endedAt!) : null;
          final durationLabel = ended != null
              ? '${ended.difference(started).inMinutes} min'
              : 'In progress';

          return setsAsync.when(
            data: (grouped) {
              final totalSets = grouped.values.fold<int>(0, (sum, l) => sum + l.length);
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    '${started.day}/${started.month}/${started.year}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text('$durationLabel · ${grouped.length} exercises · $totalSets sets'),
                  if (workout.notes != null && workout.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(workout.notes!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                  const SizedBox(height: 20),
                  for (final entry in grouped.entries) _ExerciseBlock(entry.key, entry.value),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
      ),
    );
  }
}

class _ExerciseBlock extends StatelessWidget {
  const _ExerciseBlock(this.exerciseName, this.sets);
  final String exerciseName;
  final List<WorkoutSetModel> sets;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exerciseName, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final set in sets)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('Set ${set.setNumber}: ${_setLabel(set)}'),
              ),
          ],
        ),
      ),
    );
  }

  String _setLabel(WorkoutSetModel set) {
    final parts = <String>[];
    if (set.reps != null) parts.add('${set.reps} reps');
    if (set.weightKg != null) parts.add('${_trimZero(set.weightKg!)} kg');
    if (set.durationSeconds != null) parts.add('${set.durationSeconds}s');
    if (set.rpe != null) parts.add('RPE ${_trimZero(set.rpe!)}');
    return parts.isEmpty ? 'No data logged' : parts.join(' · ');
  }

  String _trimZero(double v) => v == v.roundToDouble() ? v.round().toString() : v.toString();
}
