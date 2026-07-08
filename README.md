# ElizirFit AI

**Personalized Fitness, Built around you.**

Offline-first fitness & nutrition tracker built for Ghana — Ghanaian food database, barcode scanning for local packaged products, workout logging, and activity tracking. Full spec: `docs/spec.md`.

## Stack

- Flutter (Dart) — single codebase, iOS + Android
- Riverpod — state management
- sqflite (SQLite) — local, offline-first database
- Supabase — hosted backend, added once the local app works

## Status: Build Order step 2 — Ghana food dataset + search + meal logging ✅

- [x] Flutter project scaffold
- [x] SQLite schema (`lib/core/database/database_helper.dart`) — all 9 tables from the spec
- [x] Data models (`lib/core/models/`) — one per table, with `toMap`/`fromMap`
- [x] Ghana food dataset seed (`lib/core/database/seed/food_seed_data.dart`) — 87 real dishes across all 8 categories, auto-seeded on first launch
- [x] Food search (by name/local name + category filter)
- [x] Food detail screen — serving-size adjuster, meal-type selector, live calorie preview, add-to-meal
- [x] Nutrition Home — today's meals grouped by type, daily calorie/macro totals, delete a logged meal
- [x] Guest user auto-created on first launch (v1 "guest mode" per spec)
- [ ] Workout logging, exercise library, PR tracking (Build Order step 3)
- [ ] Activity logging with MET-based calories (Build Order step 4)
- [ ] Barcode/QR scanning + product dataset (Build Order step 5)
- [ ] Supabase auth + sync (Build Order step 6)

## Getting started

```bash
flutter pub get
flutter run
```

On launch you should see a "ElizirFit AI — DB Check" screen listing all 9 tables (`users`, `foods`, `products`, `meal_logs`, `exercises`, `workouts`, `workout_sets`, `activity_logs`, `water_logs`). If any are missing, something went wrong in `database_helper.dart` — that's the file to check first.

## Project structure

```
lib/
  main.dart                      # app entry point, temporary DB-check screen
  core/
    database/
      database_helper.dart       # SQLite schema + singleton DB access
    models/
      user.dart
      food.dart
      product.dart
      meal_log.dart
      exercise.dart
      workout.dart
      workout_set.dart
      activity_log.dart
      water_log.dart
  features/                      # screen-by-screen UI, added as we build each module
```

## Notes

- Every write-table (`meal_logs`, `workouts`, `activity_logs`) has a `synced` flag for the future Supabase sync — last-write-wins, no custom conflict resolution needed at this scale.
- `foods.verified` distinguishes cited nutrition data (1) from estimated data (0) — never presented as certain in the UI when it isn't.
- Calorie burn uses the standard MET formula: `calories = MET_value × body_weight_kg × duration_hours`.
- The local SQLite file is `elizirfit_ai.db`.
