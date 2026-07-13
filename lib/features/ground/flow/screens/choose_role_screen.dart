import 'package:flutter/material.dart';

import '../controllers/ground_flow_controller.dart';
import '../models/ground_registration_data.dart';

class ChooseRoleScreen extends StatelessWidget {
  const ChooseRoleScreen({super.key, required this.controller});

  final GroundFlowController controller;

  @override
  Widget build(BuildContext context) {
    const Color neon = Color(0xFFD7FF3F);

    Widget feature(IconData icon, String label, {required bool selected}) {
      return Row(
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0x1AD7FF3F)
                  : const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 15,
              color: selected ? neon : const Color(0xFF8C96A1),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    Widget roleCard({
      required UserRole role,
      required String title,
      required String subtitle,
      required String helper,
      required List<Widget> features,
      required bool enabled,
      required bool selected,
    }) {
      return InkWell(
        onTap: () {
          if (!enabled) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Player registration is currently disabled'),
              ),
            );
            return;
          }
          controller.data.role = role;
          controller.update();
        },
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: selected
                  ? const Color(0x40D7FF3F)
                  : const Color(0x26FFFFFF),
            ),
            color: selected ? const Color(0x11141414) : const Color(0x66141414),
            boxShadow: selected
                ? const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x2ED7FF3F),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Color(0x11000000),
                      blurRadius: 20,
                      offset: Offset(0, 4),
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? const Color(0x33D7FF3F)
                            : const Color(0x1AFFFFFF),
                      ),
                      color: selected
                          ? const Color(0x14D7FF3F)
                          : const Color(0x0DFFFFFF),
                    ),
                    child: Icon(
                      selected
                          ? Icons.sports_cricket_rounded
                          : Icons.dashboard_customize_outlined,
                      color: selected ? neon : const Color(0xFFA9B0B8),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xFFA9B0B8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.radio_button_checked_rounded,
                    color: selected ? neon : const Color(0xFF333333),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...features,
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x14FFFFFF)),
                  color: const Color(0x08FFFFFF),
                ),
                child: Text(
                  helper,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF8A8A8A),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bool ownerSelected = controller.data.role == UserRole.owner;
    final bool playerSelected = controller.data.role == UserRole.player;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1D1D1D),
        image: DecorationImage(
          image: AssetImage('assets/crick/images/ground.png'),
          fit: BoxFit.cover,
          opacity: 0.10,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      onPressed: controller.currentStep == 0
                          ? null
                          : controller.previousStep,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFFD7FF3F),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Back',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                children: <Widget>[
                  const Text(
                    'Choose Your Role',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Select how you want to get started with SportsNeo',
                    style: TextStyle(color: Color(0xFFA9B0B8), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  roleCard(
                    role: UserRole.player,
                    title: 'Play & Book',
                    subtitle:
                        'Book slots, join academies, gyms, yoga classes & more sports.',
                    helper: 'For players, teams & sports enthusiasts',
                    enabled: false,
                    selected: playerSelected,
                    features: <Widget>[
                      feature(
                        Icons.calendar_month_outlined,
                        'Book Slots',
                        selected: playerSelected,
                      ),
                      const SizedBox(height: 10),
                      feature(
                        Icons.groups_2_outlined,
                        'Join Academies',
                        selected: playerSelected,
                      ),
                      const SizedBox(height: 10),
                      feature(
                        Icons.account_balance_wallet_outlined,
                        'Split Payments',
                        selected: playerSelected,
                      ),
                      const SizedBox(height: 10),
                      feature(
                        Icons.manage_accounts_outlined,
                        'Manage Teams',
                        selected: playerSelected,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  roleCard(
                    role: UserRole.owner,
                    title: 'List & Manage',
                    subtitle:
                        'List and manage your facilities like courts, gyms, pools and more.',
                    helper: 'For facility owners & managers',
                    enabled: true,
                    selected: ownerSelected,
                    features: <Widget>[
                      feature(
                        Icons.location_on_outlined,
                        'List Facilities',
                        selected: ownerSelected,
                      ),
                      const SizedBox(height: 10),
                      feature(
                        Icons.calendar_today_outlined,
                        'Manage Bookings',
                        selected: ownerSelected,
                      ),
                      const SizedBox(height: 10),
                      feature(
                        Icons.stacked_line_chart_outlined,
                        'Track Earnings',
                        selected: ownerSelected,
                      ),
                      const SizedBox(height: 10),
                      feature(
                        Icons.payments_outlined,
                        'Handle Payouts',
                        selected: ownerSelected,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0x000B0F0F), Color(0xFF0B0F0F)],
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x40D7FF3F)),
                      color: const Color(0x0DD7FF3F),
                    ),
                    child: IconButton(
                      onPressed: controller.currentStep == 0
                          ? null
                          : controller.previousStep,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFFD7FF3F),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD7FF3F),
                          foregroundColor: const Color(0xFF050505),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          controller.data.role = UserRole.owner;
                          controller.update();
                          controller.nextStep();
                        },
                        child: const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
