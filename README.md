# ElizirFit AI

**Personalized Fitness, Built around you.**

Offline-first fitness & nutrition tracker built for Ghana — Ghanaian food database, barcode scanning for local packaged products, workout logging, and activity tracking. Full spec: `docs/spec.md`.

## Stack

- Flutter (Dart) — single codebase, iOS + Android
- Riverpod — state management
- sqflite (SQLite) — local, offline-first database
- Supabase — hosted backend, added once the local app works

## Status: Build Order step 4 — Activity logging with MET-based calories ✅

- [x] Flutter project scaffold
- [x] SQLite schema (`lib/core/database/database_helper.dart`) — all 9 tables from the spec
- [x] Data models (`lib/core/models/`) — one per table, with `toMap`/`fromMap`
- [x] Ghana food dataset seed — 87 real dishes across all 8 categories, auto-seeded on first launch
- [x] Food search, food detail, meal logging, Nutrition Home with daily totals
- [x] Exercise library seed — 68 exercises across all 7 categories, auto-seeded on first launch
- [x] Exercise Library screen — searchable/filterable by category, also used as an in-workout exercise picker
- [x] Active Workout — add exercises, log sets (reps/weight/RPE), delete sets, finish workout
- [x] Workout Home, Workout Detail, Personal Records (Epley-formula estimated 1RM)
- [x] Activity Home — log walk/run/cycle/other activities, MET-formula calorie estimate, daily total, delete a logged activity
- [x] `HomeShell` — bottom navigation; Nutrition, Workout, and Activity are live, Progress and Profile are "coming soon" placeholders
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
    activity/                    # Activity Home — log + MET-based calorie estimate
    placeholder/
      coming_soon_screen.dart    # stand-in for modules not yet built
```

## Notes

- Every write-table (`meal_logs`, `workouts`, `activity_logs`) has a `synced` flag for the future Supabase sync — last-write-wins, no custom conflict resolution needed at this scale.
- `foods.verified` distinguishes cited nutrition data (1) from estimated data (0) — never presented as certain in the UI when it isn't.
- Calorie burn uses the standard MET formula: `calories = MET_value × body_weight_kg × duration_hours`. MET values: walk 3.5, run 9.8, cycle 7.5, other 4.0.
- Logging an activity asks for body weight and saves it to the user's profile so later logs don't need to ask again.
- The local SQLite file is `elizirfit_ai.db`.
