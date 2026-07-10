import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/repositories/workout_repository.dart';
import 'active_workout_screen.dart';
import 'exercise_library_screen.dart';
import 'personal_records_screen.dart';
import 'workout_detail_screen.dart';

class WorkoutHomeScreen extends ConsumerWidget {
  const WorkoutHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeWorkoutProvider);
    final historyAsync = ref.watch(workoutHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: 'Personal records',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PersonalRecordsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'Exercise library',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(workoutRefreshProvider.notifier).state++,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            activeAsync.when(
              data: (active) {
                if (active == null) {
                  return FilledButton.icon(
                    onPressed: () => _startWorkout(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Start workout'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  );
                }
                return Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.fitness_center),
                    title: const Text('Workout in progress'),
                    subtitle: Text('Started ${_formatTime(active.startedAt)}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ActiveWorkoutScreen(workoutId: active.id),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),
            Text('History', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            historyAsync.when(
              data: (history) {
                if (history.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('No finished workouts yet.')),
                  );
                }
                return Column(
                  children: [
                    for (final summary in history) _HistoryTile(summary: summary),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startWorkout(BuildContext context, WidgetRef ref) async {
    final user = await ref.read(currentUserProvider.future);
    final workout = await ref.read(workoutRepositoryProvider).startWorkout(user.id);
    ref.read(workoutRefreshProvider.notifier).state++;
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ActiveWorkoutScreen(workoutId: workout.id)),
      );
    }
  }

  static String _formatTime(String iso) {
    final dt = DateTime.parse(iso);
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.summary});
  final WorkoutSummary summary;

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.parse(summary.workout.startedAt);
    final dateLabel = '${dt.day}/${dt.month}/${dt.year}';
    final duration = summary.duration;
    final durationLabel = duration == null
        ? ''
        : ' · ${duration.inMinutes} min';

    return Card(
      child: ListTile(
        leading: const Icon(Icons.fitness_center),
        title: Text(dateLabel),
        subtitle: Text('${summary.exerciseCount} exercises · ${summary.setCount} sets$durationLabel'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WorkoutDetailScreen(workoutId: summary.workout.id),
          ),
        ),
      ),
    );
  }
}
