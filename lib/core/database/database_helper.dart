import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton wrapper around the local SQLite database.
///
/// This is the offline-first source of truth (spec Section 3): every
/// write-table below carries a `synced` flag so a future background sync
/// job can push unsynced rows to Supabase once online. Nothing here talks
/// to a network — that's added in Build Order step 6.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'elizirfit_ai.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        // Foreign keys are off by default in sqflite; the schema below
        // relies on them for meal_logs -> foods/products and
        // workout_sets -> workouts.
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        age INTEGER,
        sex TEXT,
        height_cm REAL,
        weight_kg REAL,
        goal TEXT,
        activity_level TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE foods (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        local_names TEXT,
        category TEXT,
        serving_size_g REAL NOT NULL,
        calories REAL NOT NULL,
        protein_g REAL NOT NULL,
        carbs_g REAL NOT NULL,
        fat_g REAL NOT NULL,
        fiber_g REAL,
        sugar_g REAL,
        sodium_mg REAL,
        source TEXT,
        verified INTEGER DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        barcode TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        brand TEXT,
        manufacturer TEXT,
        serving_size_g REAL NOT NULL,
        calories REAL NOT NULL,
        protein_g REAL NOT NULL,
        carbs_g REAL NOT NULL,
        fat_g REAL NOT NULL,
        sugar_g REAL,
        sodium_mg REAL,
        ingredients TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE meal_logs (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        logged_at TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        food_id TEXT,
        product_id TEXT,
        quantity_servings REAL NOT NULL DEFAULT 1,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (food_id) REFERENCES foods(id),
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    batch.execute('''
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT,
        difficulty TEXT,
        primary_muscles TEXT,
        secondary_muscles TEXT,
        equipment TEXT,
        instructions TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE workouts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        notes TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE workout_sets (
        id TEXT PRIMARY KEY,
        workout_id TEXT NOT NULL,
        exercise_name TEXT NOT NULL,
        set_number INTEGER NOT NULL,
        reps INTEGER,
        weight_kg REAL,
        rpe REAL,
        duration_seconds INTEGER,
        FOREIGN KEY (workout_id) REFERENCES workouts(id)
      )
    ''');

    batch.execute('''
      CREATE TABLE activity_logs (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        activity_type TEXT NOT NULL,
        started_at TEXT NOT NULL,
        duration_minutes REAL NOT NULL,
        distance_km REAL,
        calories_estimated REAL,
        synced INTEGER DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE water_logs (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        logged_at TEXT NOT NULL,
        amount_ml REAL NOT NULL
      )
    ''');

    // Indexes that matter from day one — meal/workout/activity history
    // screens all query "everything for this user, most recent first".
    batch.execute('CREATE INDEX idx_meal_logs_user ON meal_logs(user_id, logged_at)');
    batch.execute('CREATE INDEX idx_workouts_user ON workouts(user_id, started_at)');
    batch.execute('CREATE INDEX idx_workout_sets_workout ON workout_sets(workout_id)');
    batch.execute('CREATE INDEX idx_activity_logs_user ON activity_logs(user_id, started_at)');
    batch.execute('CREATE INDEX idx_water_logs_user ON water_logs(user_id, logged_at)');
    batch.execute('CREATE INDEX idx_foods_category ON foods(category)');
    batch.execute('CREATE INDEX idx_products_barcode ON products(barcode)');

    await batch.commit(noResult: true);
  }

  /// Wipes and recreates the database. Useful during development when the
  /// schema changes — never call this from a release build.
  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'elizirfit_ai.db');
    await deleteDatabase(path);
    _db = null;
    await database;
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
