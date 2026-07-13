import 'package:flutter/material.dart';

import '../controllers/ground_flow_controller.dart';
import '../models/ground_registration_data.dart';
import 'slot_management_screen.dart';

class ConfigureSlotsScreen extends StatelessWidget {
  const ConfigureSlotsScreen({
    super.key,
    required this.data,
    this.controller,
  });

  final GroundRegistrationData data;
  final GroundFlowController? controller;

  @override
  Widget build(BuildContext context) {
    // Reuse the existing Summer Slots screen to keep this UI 1:1 with the approved layout.
    return SlotManagementScreen(controller: controller);
  }
}
