import 'package:flutter/material.dart';

import '../activity/activity_home_screen.dart';
import '../nutrition/nutrition_home_screen.dart';
import '../placeholder/coming_soon_screen.dart';
import '../workout/workout_home_screen.dart';

/// App shell with bottom navigation across the five top-level modules
/// from the spec's screen inventory (Section 5). Nutrition, Workout, and
/// Activity are live; Progress and Profile show a "coming soon" screen
/// until their own Build Order steps land.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    NutritionHomeScreen(),
    WorkoutHomeScreen(),
    ActivityHomeScreen(),
    ComingSoonScreen(
      title: 'Progress',
      icon: Icons.trending_up,
      buildStep: 'Weight trend chart — added alongside later steps.',
    ),
    ComingSoonScreen(
      title: 'Profile',
      icon: Icons.person_outline,
      buildStep: 'Profile, goals, and settings — added alongside Supabase auth, Build Order step 6.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.restaurant_outlined), selectedIcon: Icon(Icons.restaurant), label: 'Nutrition'),
          NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Workout'),
          NavigationDestination(icon: Icon(Icons.directions_run_outlined), selectedIcon: Icon(Icons.directions_run), label: 'Activity'),
          NavigationDestination(icon: Icon(Icons.trending_up), label: 'Progress'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
