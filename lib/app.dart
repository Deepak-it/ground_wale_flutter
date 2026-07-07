import 'package:flutter/material.dart';

import 'core/api/api_session.dart';
import 'core/theme/app_theme.dart';
import 'features/academy/home/academy_dashboard_screen.dart';
import 'features/box_cricket/home/box_cricket_dashboard_screen.dart';
import 'features/ground/dashboard/dashboard_turf_screen.dart';
import 'features/sports_neo/home/sports_neo_dashboard_screen.dart';
import 'features/sports_neo/home/sports_neo_onboarding_flow.dart';

class GroundWaleApp extends StatelessWidget {
  const GroundWaleApp({super.key});

  String _normalizeRole(dynamic raw) {
    if (raw == null) {
      return '';
    }

    final String role = raw.toString().toLowerCase().trim();
    if (role.isEmpty) {
      return '';
    }

    if (role == 'box_cricket_owner' ||
        role == 'box-cricket' ||
        role == 'box cricket' ||
        role == 'box_cricket' ||
        role == 'boxcricket' ||
        role == 'box') {
      return 'box_cricket_owner';
    }

    if (role == 'academy_owner' || role == 'academy' || role == 'coach') {
      return 'academy_owner';
    }

    if (role == 'ground_owner' ||
        role == 'owner' ||
        role == 'ground' ||
        role == 'turf' ||
        role == 'turf_owner') {
      return 'ground_owner';
    }

    if (role == 'player' ||
        role == 'captain' ||
        role == 'sportsneo' ||
        role == 'sports neo' ||
        role == 'sports_neo' ||
        role == 'sports-neo') {
      return 'player';
    }

    return role;
  }

  Widget _homeForCurrentSession() {
    if (!ApiSession.instance.isAuthenticated) {
      return const SportsNeoWelcomeScreen();
    }

    final String role = _normalizeRole(ApiSession.instance.role);
    if (role == 'academy_owner') {
      return const AcademyDashboardScreen();
    }
    if (role == 'box_cricket_owner') {
      return const BoxCricketDashboardScreen();
    }
    if (role == 'ground_owner') {
      return const DashboardTurfScreen();
    }

    return const SportsNeoDashboardScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ground Wale',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _homeForCurrentSession(),
    );
  }
}
