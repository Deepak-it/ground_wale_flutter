import 'package:flutter/material.dart';

import 'core/api/api_session.dart';
import 'core/theme/app_theme.dart';
import 'features/ground_court/home/ground_court_owner_shell_screen.dart';
import 'features/sports_neo/home/sports_neo_dashboard_screen.dart';
import 'features/sports_neo/home/sports_neo_onboarding_flow.dart';

class GroundWaleApp extends StatefulWidget {
  const GroundWaleApp({super.key});

  @override
  State<GroundWaleApp> createState() => _GroundWaleAppState();
}

class _GroundWaleAppState extends State<GroundWaleApp> {
  bool _sessionBootstrapped = false;

  @override
  void initState() {
    super.initState();
    _bootstrapSession();
  }

  Future<void> _bootstrapSession() async {
    bool restored = false;
    for (int attempt = 0; attempt < 5; attempt++) {
      restored = await ApiSession.instance.restoreFromStorage();
      if (restored) {
        break;
      }
      await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _sessionBootstrapped = true;
    });
  }

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
    if (!_sessionBootstrapped) {
      return MaterialApp(
        title: 'Cric Info',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          backgroundColor: Color(0xFF0A0F1E),
          body: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Cric Info',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: AnimatedBuilder(
        animation: ApiSession.instance,
        builder: (BuildContext context, Widget? _) {
          return _homeForCurrentSession();
        },
      ),
      builder: (BuildContext context, Widget? child) {
        return SafeArea(top: true, bottom: true, child: child!);
      },
    );
  }
}
