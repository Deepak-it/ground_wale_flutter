import 'package:flutter/material.dart';

import '../../slots/manage_slot_turf_screen.dart';
import '../../profile/profile_turf_screen.dart';
import '../../auth/ground_management_auth_screen.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/neon_button.dart';
import 'manage_slot_screen.dart';
import 'register_ground_flow_screen.dart';

class GroundManagementScreen extends StatelessWidget {
  const GroundManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFF1C2C1A), Color(0xFF1D1D1D), Color(0xFF111311)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 20),
                const Text('Ground Management', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('Register your ground and configure booking slots.', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 24),
                const GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Owner dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                      SizedBox(height: 10),
                      Text('Use Register Ground for onboarding and Slot Management to configure schedules.', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                const Spacer(),
                NeonButton(
                  label: 'Register Ground',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RegisterGroundFlowScreen(
                          forceCreateGround: true,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                NeonButton(
                  label: 'Slot Management',
                  outline: true,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const ManageSlotScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                NeonButton(
                  label: 'Slot-Turf',
                  outline: true,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const ManageSlotTurfScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                NeonButton(
                  label: 'Login',
                  outline: true,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const GroundManagementAuthScreen()),
                    );
                  },
                ),
                
                const SizedBox(height: 12),
                NeonButton(
                  label: 'Profile-Turf',
                  outline: true,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const ProfileTurfScreen()),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
