import 'package:flutter/material.dart';

import '../../../core/widgets/module_bottom_nav.dart';

class BoxCricketBottomNav extends StatelessWidget {
  const BoxCricketBottomNav({
    super.key,
    required this.currentIndex,
    required this.onHome,
    required this.onAnnouncement,
    required this.onSlots,
    required this.onProfile,
  });

  final int currentIndex;
  final VoidCallback onHome;
  final VoidCallback onAnnouncement;
  final VoidCallback onSlots;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return ModuleBottomNav(
      currentIndex: currentIndex,
      activeColor: const Color(0xFF00C9A7),
      inactiveColor: const Color(0xFF9FB9B3),
      backgroundColor: const Color(0x0FFFFFFF),
      borderColor: const Color(0x1FFFFFFF),
      horizontalPadding: 26,
      bottomPadding: 20,
      autoItemWidth: true,
      items: <ModuleBottomNavItem>[
        ModuleBottomNavItem(
          icon: Icons.home_outlined,
          label: 'Home',
          onTap: onHome,
        ),
        ModuleBottomNavItem(
          icon: Icons.confirmation_num_outlined,
          label: 'Bookings',
          onTap: onAnnouncement,
        ),
        ModuleBottomNavItem(
          icon: Icons.schedule_outlined,
          label: 'Slots',
          onTap: onSlots,
        ),
        ModuleBottomNavItem(
          icon: Icons.person_outline_rounded,
          label: 'Profile',
          onTap: onProfile,
        ),
      ],
    );
  }
}
