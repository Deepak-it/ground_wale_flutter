import 'package:flutter/material.dart';

import '../controllers/ground_flow_controller.dart';
import 'slot_management_screen.dart';

class ManageSlotScreen extends StatelessWidget {
  const ManageSlotScreen({super.key, this.controller});

  final GroundFlowController? controller;

  @override
  Widget build(BuildContext context) {
    return SlotManagementScreen(controller: controller);
  }
}
