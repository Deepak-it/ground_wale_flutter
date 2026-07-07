import 'package:flutter/material.dart';

import '../../../../core/widgets/neon_button.dart';
import '../controllers/ground_flow_controller.dart';

class GroundPhotosScreen extends StatelessWidget {
  const GroundPhotosScreen({super.key, required this.controller});

  final GroundFlowController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Ground Photos', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Step 3 of 5', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                controller.data.groundImages.add('image_${DateTime.now().millisecondsSinceEpoch}.jpg');
                controller.update();
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0x14FFFFFF),
                  border: Border.all(color: const Color(0x66DDF730), style: BorderStyle.solid, width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.file_upload_outlined, size: 48, color: Color(0xFFDDF730)),
                    const SizedBox(height: 12),
                    const Text('Upload Image', style: TextStyle(color: Color(0xFF94A3B8))),
                    const SizedBox(height: 12),
                    Text(
                      controller.data.groundImages.isEmpty
                          ? 'Tap to add main ground image'
                          : '${controller.data.groundImages.length} image(s) added',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          NeonButton(label: 'Next', onPressed: controller.nextStep),
          const SizedBox(height: 10),
          NeonButton(label: 'Skip for Now', outline: true, onPressed: controller.nextStep),
        ],
      ),
    );
  }
}
