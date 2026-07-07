import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import '../../sports_neo/home/sports_neo_onboarding_flow.dart';
import 'profile_turf_ui.dart';

class LogoutTurfScreen extends StatelessWidget {
  const LogoutTurfScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      await GroundWaleApi.instance.logout();
    } catch (_) {
    } finally {
      ApiSession.instance.clear();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const SportsNeoWelcomeScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TurfPageScaffold(
      title: 'TAp on Logout',
      child: Center(
        child: TurfCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.logout_rounded, color: Color(0xFFE3220D), size: 36),
              const SizedBox(height: 10),
              const Text('Are you sure you want to logout?', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('You can login again anytime.', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _logout(context),
                      child: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
