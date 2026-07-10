import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/activity_log.dart';
import '../../core/providers/app_providers.dart';

/// Activity Home screen (spec Section 5): log a walk/run/cycle/other
/// activity, see today's total calories burned (MET formula), and
/// history of past activities.
class ActivityHomeScreen extends ConsumerWidget {
  const ActivityHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caloriesAsync = ref.watch(todaysActivityCaloriesProvider);
    final activitiesAsync = ref.watch(todaysActivitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogActivitySheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Log activity'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(activityRefreshProvider.notifier).state++,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            caloriesAsync.when(
              data: (calories) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${calories.round()} kcal burned today',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Estimated using the MET formula: MET × body weight × hours.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),
            Text("Today's activities", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            activitiesAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'Nothing logged yet today.\nTap "Log activity" to add a walk, run, cycle, or other activity.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return Column(
                  children: [for (final e in entries) _ActivityTile(entry: e)],
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

  void _showLogActivitySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _LogActivitySheet(),
    );
  }
}

class _ActivityTile extends ConsumerWidget {
  const _ActivityTile({required this.entry});
  final ActivityLogModel entry;

  static const _icons = {
    'walk': Icons.directions_walk,
    'run': Icons.directions_run,
    'cycle': Icons.directions_bike,
    'other': Icons.sports_gymnastics,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dt = DateTime.parse(entry.startedAt);
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';

    final subtitleParts = <String>[
      '${entry.durationMinutes.round()} min',
      if (entry.distanceKm != null) '${entry.distanceKm!.toStringAsFixed(1)} km',
      '$h:$m $period',
    ];

    return Card(
      child: ListTile(
        leading: Icon(_icons[entry.activityType] ?? Icons.sports_gymnastics),
        title: Text(entry.activityType[0].toUpperCase() + entry.activityType.substring(1)),
        subtitle: Text(subtitleParts.join(' · ')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${entry.caloriesEstimated?.round() ?? 0} kcal'),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () async {
                await ref.read(activityRepositoryProvider).deleteActivity(entry.id);
                ref.read(activityRefreshProvider.notifier).state++;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LogActivitySheet extends ConsumerStatefulWidget {
  const _LogActivitySheet();

  @override
  ConsumerState<_LogActivitySheet> createState() => _LogActivitySheetState();
}

class _LogActivitySheetState extends ConsumerState<_LogActivitySheet> {
  String _type = 'walk';
  final _durationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _weightController = TextEditingController();
  bool _saving = false;
  bool _loadedWeight = false;

  static const _types = ['walk', 'run', 'cycle', 'other'];

  @override
  void dispose() {
    _durationController.dispose();
    _distanceController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pre-fill body weight from the user's profile the first time this
    // builds, so the field defaults sensibly without blocking the sheet
    // on a FutureBuilder.
    if (!_loadedWeight) {
      _loadedWeight = true;
      ref.read(currentUserProvider.future).then((user) {
        if (mounted && user.weightKg != null && _weightController.text.isEmpty) {
          setState(() => _weightController.text = user.weightKg!.toStringAsFixed(0));
        }
      });
    }

    final showDistance = _type == 'walk' || _type == 'run' || _type == 'cycle';

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Log activity', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final t in _types)
                ChoiceChip(
                  label: Text(t[0].toUpperCase() + t.substring(1)),
                  selected: _type == t,
                  onSelected: (_) => setState(() => _type = t),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Duration (minutes)'),
          ),
          if (showDistance) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _distanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Distance (km, optional)'),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Your body weight (kg)',
              helperText: 'Used to estimate calories burned — saved to your profile.',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: Text(_saving ? 'Saving...' : 'Log activity'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final duration = double.tryParse(_durationController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());

    if (duration == null || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid duration.')),
      );
      return;
    }
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your body weight to estimate calories.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final user = await ref.read(currentUserProvider.future);

      // Keep the profile's weight in sync so future logs (and later,
      // nutrition goal calculations) use the latest value.
      if (user.weightKg != weight) {
        await ref.read(userRepositoryProvider).updateUser(user.copyWith(weightKg: weight));
      }

      await ref.read(activityRepositoryProvider).logActivity(
            userId: user.id,
            activityType: _type,
            durationMinutes: duration,
            bodyWeightKg: weight,
            distanceKm: double.tryParse(_distanceController.text.trim()),
          );
      ref.read(activityRefreshProvider.notifier).state++;
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
