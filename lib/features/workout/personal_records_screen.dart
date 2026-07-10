import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/repositories/workout_repository.dart';

/// Best set per exercise, most recent first (spec Section 5). Ranked by
/// estimated one-rep max via the Epley formula — see
/// WorkoutRepository.getPersonalRecords for the calculation.
class PersonalRecordsScreen extends ConsumerWidget {
  const PersonalRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(personalRecordsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Personal records')),
      body: recordsAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No personal records yet.\nLog a weighted set with reps to start tracking PRs.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: records.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _RecordTile(record: records[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});
  final PersonalRecord record;

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.parse(record.achievedAt);
    final dateLabel = '${dt.day}/${dt.month}/${dt.year}';
    final weight = record.weightKg == record.weightKg.roundToDouble()
        ? record.weightKg.round().toString()
        : record.weightKg.toString();

    return ListTile(
      leading: const Icon(Icons.emoji_events_outlined),
      title: Text(record.exerciseName),
      subtitle: Text('Best: $weight kg × ${record.reps} reps · $dateLabel'),
      trailing: Text(
        '~${record.estimatedOneRepMax.round()} kg 1RM',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
