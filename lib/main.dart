import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/database_helper.dart';

void main() {
  runApp(const ProviderScope(child: ElizirFitApp()));
}

class ElizirFitApp extends StatelessWidget {
  const ElizirFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ElizirFit AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00A651)),
        useMaterial3: true,
      ),
      home: const _DbCheckScreen(),
    );
  }
}

/// Temporary home screen for Build Order step 1: confirms the local
/// SQLite database opens and every table from the spec exists.
/// This gets replaced by the real Dashboard screen in a later step.
class _DbCheckScreen extends StatefulWidget {
  const _DbCheckScreen();

  @override
  State<_DbCheckScreen> createState() => _DbCheckScreenState();
}

class _DbCheckScreenState extends State<_DbCheckScreen> {
  String _status = 'Opening database...';
  List<String> _tables = [];

  static const expectedTables = [
    'users',
    'foods',
    'products',
    'meal_logs',
    'exercises',
    'workouts',
    'workout_sets',
    'activity_logs',
    'water_logs',
  ];

  @override
  void initState() {
    super.initState();
    _checkDatabase();
  }

  Future<void> _checkDatabase() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'",
      );
      final tableNames = rows.map((r) => r['name'] as String).toList()..sort();

      final missing = expectedTables.where((t) => !tableNames.contains(t)).toList();

      setState(() {
        _tables = tableNames;
        _status = missing.isEmpty
            ? 'All ${tableNames.length} tables created successfully.'
            : 'Missing tables: ${missing.join(", ")}';
      });
    } catch (e) {
      setState(() => _status = 'Database error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ElizirFit AI — DB Check')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_status, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (_tables.isNotEmpty) ...[
              Text('Tables:', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: _tables.map((t) => Text('• $t')).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
