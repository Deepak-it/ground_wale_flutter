import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/labeled_text_field.dart';
import '../../../../core/widgets/neon_button.dart';
import '../controllers/ground_flow_controller.dart';
import '../models/ground_registration_data.dart';

class GroundDetailsScreen extends StatefulWidget {
  const GroundDetailsScreen({super.key, required this.controller});

  final GroundFlowController controller;

  @override
  State<GroundDetailsScreen> createState() => _GroundDetailsScreenState();
}

class _GroundDetailsScreenState extends State<GroundDetailsScreen> {
  final TextEditingController searchController = TextEditingController();

  static const List<String> allFacilities = <String>[
    'Parking',
    'Cafeteria / Food',
    'First aid',
    'Rest Room',
    'Changing Room',
    'Dugout',
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GroundFlowController controller = widget.controller;
    final String query = searchController.text.toLowerCase();
    final List<String> filtered = allFacilities
        .where((String f) => query.isEmpty || f.toLowerCase().contains(query))
        .toList();

    Widget pitchChip(PitchType type, String label) {
      final bool selected = controller.data.pitchType == type;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: const Color(0xFFDDF730),
        labelStyle: TextStyle(
          color: selected ? const Color(0xFF242424) : Colors.white,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: const Color(0x14FFFFFF),
        side: const BorderSide(color: Color(0x66DDF730)),
        onSelected: (_) {
          controller.data.pitchType = type;
          controller.update();
        },
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Ground Details', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Step 4 of 5', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Pitch Type', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    pitchChip(PitchType.cement, 'Cement Pitch'),
                    pitchChip(PitchType.turf, 'Turf Pitch'),
                    pitchChip(PitchType.matting, 'Matting Pitch'),
                    pitchChip(PitchType.astroTurf, 'Astro Turf Pitch'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          LabeledTextField(
            label: 'Search facilities or add more',
            controller: searchController,
            hint: 'Search facilities',
            suffixIcon: const Icon(Icons.search),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: filtered.map((String facility) {
                final bool selected = controller.data.facilities.contains(facility);
                return FilterChip(
                  selected: selected,
                  label: Text(facility),
                  selectedColor: const Color(0x33DDF730),
                  side: const BorderSide(color: Color(0x66DDF730)),
                  onSelected: (bool value) {
                    if (value) {
                      controller.data.facilities.add(facility);
                    } else {
                      controller.data.facilities.remove(facility);
                    }
                    controller.update();
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          NeonButton(label: 'Next', onPressed: controller.nextStep),
          const SizedBox(height: 10),
          NeonButton(label: 'Skip', outline: true, onPressed: controller.nextStep),
        ],
      ),
    );
  }
}
