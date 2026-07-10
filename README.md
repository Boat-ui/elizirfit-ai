# ElizirFit AI

**Personalized Fitness, Built around you.**

Offline-first fitness & nutrition tracker built for Ghana — Ghanaian food database, barcode scanning for local packaged products, workout logging, and activity tracking. Full spec: `docs/spec.md`.

## Stack

- Flutter (Dart) — single codebase, iOS + Android
- Riverpod — state management
- sqflite (SQLite) — local, offline-first database
- Supabase — hosted backend, added once the local app works

## Status: Build Order step 3 — Workout logging, exercise library, PR tracking ✅

- [x] Flutter project scaffold
- [x] SQLite schema (`lib/core/database/database_helper.dart`) — all 9 tables from the spec
- [x] Data models (`lib/core/models/`) — one per table, with `toMap`/`fromMap`
- [x] Ghana food dataset seed — 87 real dishes across all 8 categories, auto-seeded on first launch
- [x] Food search, food detail, meal logging, Nutrition Home with daily totals
- [x] Exercise library seed (`lib/core/database/seed/exercise_seed_data.dart`) — 68 exercises across all 7 categories, auto-seeded on first launch
- [x] Exercise Library screen — searchable/filterable by category, also used as an in-workout exercise picker
- [x] Active Workout — add exercises, log sets (reps/weight/RPE), delete sets, finish workout
- [x] Workout Home — resume in-progress workout, history list
- [x] Workout Detail — full past-session breakdown
- [x] Personal Records — best set per exercise, ranked by Epley-formula estimated 1RM, most recent first
- [x] `HomeShell` — bottom navigation across Nutrition / Workout / Activity / Progress / Profile (last three are "coming soon" placeholders until their own steps)
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
  main.dart                      # app entry point, boots into HomeShell
  core/
    database/
      database_helper.dart       # SQLite schema + singleton DB access
      seed/
        food_seed_data.dart      # Ghana food dataset
        exercise_seed_data.dart  # exercise library dataset
    models/                      # one per table
    repositories/                # DB access + business logic per module
    providers/
      app_providers.dart         # all Riverpod wiring
  features/
    shell/
      home_shell.dart            # bottom nav across all top-level modules
    nutrition/                   # Nutrition Home, Food Search, Food Detail
    workout/                     # Workout Home, Active Workout, Exercise Library,
                                  # Exercise Detail, Workout Detail, Personal Records
    placeholder/
      coming_soon_screen.dart    # stand-in for modules not yet built
```

## Notes

- Every write-table (`meal_logs`, `workouts`, `activity_logs`) has a `synced` flag for the future Supabase sync — last-write-wins, no custom conflict resolution needed at this scale.
- `foods.verified` distinguishes cited nutrition data (1) from estimated data (0) — never presented as certain in the UI when it isn't.
- Calorie burn uses the standard MET formula: `calories = MET_value × body_weight_kg × duration_hours`.
- The local SQLite file is `elizirfit_ai.db`.
