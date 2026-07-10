import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/workout_set.dart';
import '../../core/providers/app_providers.dart';
import 'exercise_library_screen.dart';

/// Active Workout screen (spec Section 5): exercise picker, set logger
/// (reps/weight/RPE), running session list, "Finish".
class ActiveWorkoutScreen extends ConsumerWidget {
  const ActiveWorkoutScreen({super.key, required this.workoutId});
  final String workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(workoutSetsProvider(workoutId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active workout'),
        actions: [
          TextButton(
            onPressed: () => _finish(context, ref),
            child: const Text('Finish'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addExercise(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add exercise'),
      ),
      body: setsAsync.when(
        data: (grouped) {
          if (grouped.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No exercises yet.\nTap "Add exercise" to pick one from the library.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              for (final entry in grouped.entries)
                _ExerciseSection(
                  workoutId: workoutId,
                  exerciseName: entry.key,
                  sets: entry.value,
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _addExercise(BuildContext context, WidgetRef ref) async {
    final exerciseName = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen(pickerMode: true)),
    );
    if (exerciseName == null || !context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddSetSheet(
        workoutId: workoutId,
        exerciseName: exerciseName,
      ),
    );
  }

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finish workout?'),
        content: const Text('This will mark the session as complete.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Finish')),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(workoutRepositoryProvider).finishWorkout(workoutId);
    ref.read(workoutRefreshProvider.notifier).state++;
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _ExerciseSection extends ConsumerWidget {
  const _ExerciseSection({
    required this.workoutId,
    required this.exerciseName,
    required this.sets,
  });

  final String workoutId;
  final String exerciseName;
  final List<WorkoutSetModel> sets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(exerciseName, style: Theme.of(context).textTheme.titleSmall),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Add set',
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (ctx) => _AddSetSheet(
                      workoutId: workoutId,
                      exerciseName: exerciseName,
                      previousSet: sets.isNotEmpty ? sets.last : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final set in sets)
            ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                child: Text('${set.setNumber}', style: const TextStyle(fontSize: 12)),
              ),
              title: Text(_setLabel(set)),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () async {
                  await ref.read(workoutRepositoryProvider).deleteSet(set.id);
                  ref.read(workoutRefreshProvider.notifier).state++;
                },
              ),
            ),
        ],
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

class _AddSetSheet extends ConsumerStatefulWidget {
  const _AddSetSheet({
    required this.workoutId,
    required this.exerciseName,
    this.previousSet,
  });

  final String workoutId;
  final String exerciseName;
  final WorkoutSetModel? previousSet;

  @override
  ConsumerState<_AddSetSheet> createState() => _AddSetSheetState();
}

class _AddSetSheetState extends ConsumerState<_AddSetSheet> {
  late final TextEditingController _repsController;
  late final TextEditingController _weightController;
  late final TextEditingController _rpeController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final prev = widget.previousSet;
    _repsController = TextEditingController(text: prev?.reps?.toString() ?? '');
    _weightController = TextEditingController(text: prev?.weightKg?.toString() ?? '');
    _rpeController = TextEditingController(text: prev?.rpe?.toString() ?? '');
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    _rpeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.exerciseName, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _repsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Reps'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Weight (kg)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rpeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'RPE (optional, 1-10)'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: Text(_saving ? 'Saving...' : 'Log set'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(workoutRepositoryProvider).addSet(
            workoutId: widget.workoutId,
            exerciseName: widget.exerciseName,
            reps: int.tryParse(_repsController.text.trim()),
            weightKg: double.tryParse(_weightController.text.trim()),
            rpe: double.tryParse(_rpeController.text.trim()),
          );
      ref.read(workoutRefreshProvider.notifier).state++;
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
