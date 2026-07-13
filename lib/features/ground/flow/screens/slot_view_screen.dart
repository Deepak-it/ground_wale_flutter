import 'package:flutter/material.dart';

import '../../../box_cricket/home/box_cricket_manage_slots_screen.dart';

class SlotViewScreen extends StatelessWidget {
  const SlotViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BoxCricketManageSlotsScreen(
      showBottomNav: false,
      showGroundNotFoundError: false,
    );
  }
}
