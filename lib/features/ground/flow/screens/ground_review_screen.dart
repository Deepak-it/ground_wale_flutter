import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/neon_button.dart';
import '../controllers/ground_flow_controller.dart';

class GroundReviewScreen extends StatelessWidget {
  const GroundReviewScreen({super.key, required this.controller});

  final GroundFlowController controller;

  @override
  Widget build(BuildContext context) {
    final data = controller.data;

    Widget item(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 120,
              child: Text(label, style: const TextStyle(color: Colors.white70)),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Ground Review',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                item('Ground Name', data.groundName),
                item('State', data.state),
                item('City', data.city),
                item(
                  'Sports',
                  data.selectedSports.isEmpty
                      ? 'Not selected'
                      : data.selectedSports.join(', '),
                ),
                item(
                  'Phone',
                  data.contactNumber.isEmpty
                      ? '+91 98765 43210'
                      : data.contactNumber,
                ),
                item(
                  'Address',
                  data.address.isEmpty
                      ? 'Flat 203, Green Park Society'
                      : data.address,
                ),
                item(
                  'Landmark',
                  data.landmark.isEmpty
                      ? 'Flower Shop, Hanuman Mandir'
                      : data.landmark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          NeonButton(label: 'Next', onPressed: controller.nextStep),
        ],
      ),
    );
  }
}
