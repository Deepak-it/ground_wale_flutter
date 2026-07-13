import 'package:flutter/material.dart';

import 'core/api/api_session.dart';
import 'core/theme/app_theme.dart';
import 'features/ground_court/home/ground_court_owner_shell_screen.dart';
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
      return 'owner';
    }

    if (role == 'academy_owner' || role == 'academy' || role == 'coach') {
      return 'owner';
    }

    if (role == 'ground_owner' ||
        role == 'owner' ||
        role == 'ground' ||
        role == 'turf' ||
        role == 'turf_owner') {
      return 'owner';
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
    if (role == 'owner') {
      return const GroundCourtOwnerShellScreen();
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
      builder: (BuildContext context, Widget? child) {
        return SafeArea(
          top: true,
          bottom: true,
          child: child!,
        );
      },
    );
  }
}
