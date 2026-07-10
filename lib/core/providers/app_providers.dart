import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/user.dart';
import '../repositories/exercise_repository.dart';
import '../repositories/food_repository.dart';
import '../repositories/meal_log_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/workout_repository.dart';

/// Opens the database and seeds the Ghana food dataset and exercise
/// library if needed. This is the single startup gate the UI waits on
/// before showing any real screen.
final appInitProvider = FutureProvider<Database>((ref) async {
  final db = await DatabaseHelper.instance.database;
  await FoodRepository(db).seedIfEmpty();
  await ExerciseRepository(db).seedIfEmpty();
  return db;
});

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  final db = ref.watch(appInitProvider).requireValue;
  return FoodRepository(db);
});

final mealLogRepositoryProvider = Provider<MealLogRepository>((ref) {
  final db = ref.watch(appInitProvider).requireValue;
  return MealLogRepository(db);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final db = ref.watch(appInitProvider).requireValue;
  return UserRepository(db);
});

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  final db = ref.watch(appInitProvider).requireValue;
  return ExerciseRepository(db);
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final db = ref.watch(appInitProvider).requireValue;
  return WorkoutRepository(db);
});

/// The current local user. Guest by default until Step 6 (Supabase auth).
final currentUserProvider = FutureProvider<UserModel>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getOrCreateCurrentUser();
});

/// Search text typed into the Food Search screen.
final foodSearchQueryProvider = StateProvider<String>((ref) => '');

/// Selected category filter on the Food Search screen (null = all).
final foodSearchCategoryProvider = StateProvider<String?>((ref) => null);

/// Re-runs whenever the query or category changes.
final foodSearchProvider = FutureProvider.autoDispose((ref) {
  final query = ref.watch(foodSearchQueryProvider);
  final category = ref.watch(foodSearchCategoryProvider);
  final repo = ref.watch(foodRepositoryProvider);
  return repo.search(query, category: category);
});

/// Bumped after every log/delete so screens watching today's meals refetch.
final mealLogRefreshProvider = StateProvider<int>((ref) => 0);

final todaysMealsProvider = FutureProvider.autoDispose((ref) async {
  ref.watch(mealLogRefreshProvider);
  final user = await ref.watch(currentUserProvider.future);
  final repo = ref.watch(mealLogRepositoryProvider);
  return repo.getEntriesForDay(userId: user.id);
});

final todaysTotalsProvider = FutureProvider.autoDispose((ref) async {
  ref.watch(mealLogRefreshProvider);
  final user = await ref.watch(currentUserProvider.future);
  final repo = ref.watch(mealLogRepositoryProvider);
  return repo.getTotalsForDay(userId: user.id);
});

// ---- Exercise library ----

final exerciseSearchQueryProvider = StateProvider<String>((ref) => '');
final exerciseSearchCategoryProvider = StateProvider<String?>((ref) => null);

final exerciseSearchProvider = FutureProvider.autoDispose((ref) {
  final query = ref.watch(exerciseSearchQueryProvider);
  final category = ref.watch(exerciseSearchCategoryProvider);
  final repo = ref.watch(exerciseRepositoryProvider);
  return repo.search(query, category: category);
});

// ---- Workouts ----

/// Bumped after any workout/set change so screens watching workout state
/// refetch.
final workoutRefreshProvider = StateProvider<int>((ref) => 0);

/// The user's in-progress workout, if any (null once finished).
final activeWorkoutProvider = FutureProvider.autoDispose((ref) async {
  ref.watch(workoutRefreshProvider);
  final user = await ref.watch(currentUserProvider.future);
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.getActiveWorkout(user.id);
});

final workoutHistoryProvider = FutureProvider.autoDispose((ref) async {
  ref.watch(workoutRefreshProvider);
  final user = await ref.watch(currentUserProvider.future);
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.getHistory(user.id);
});

final personalRecordsProvider = FutureProvider.autoDispose((ref) async {
  ref.watch(workoutRefreshProvider);
  final user = await ref.watch(currentUserProvider.future);
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.getPersonalRecords(user.id);
});

/// Sets for one workout, grouped by exercise name — used by Active
/// Workout and Workout Detail screens.
final workoutSetsProvider = FutureProvider.autoDispose.family((ref, String workoutId) async {
  ref.watch(workoutRefreshProvider);
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.getSetsGrouped(workoutId);
});
