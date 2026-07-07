import 'package:flutter/material.dart';

import '../../../../core/widgets/neon_button.dart';
import '../controllers/ground_flow_controller.dart';

class OwnershipVerificationScreen extends StatelessWidget {
  const OwnershipVerificationScreen({super.key, required this.controller});

  final GroundFlowController controller;

  @override
  Widget build(BuildContext context) {
    final bool academyFlow = controller.isAcademyFlow;
    final String entity = academyFlow ? 'Academy' : 'Ground';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Ownership Verification',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                controller.data.ownershipProof =
                    'ownership_proof_${DateTime.now().millisecondsSinceEpoch}.pdf';
                controller.update();
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0x14FFFFFF),
                  border: Border.all(
                    color: const Color(0x66DDF730),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(
                      Icons.upload_file,
                      size: 52,
                      color: Color(0xFFDDF730),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Upload Rent Agreement / Ownership Proof',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      controller.data.ownershipProof.isEmpty
                          ? 'Tap to upload proof'
                          : 'Proof uploaded. If not valid, upload other proof without going back.',
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          NeonButton(
            label: 'Submit $entity for Verification',
            onPressed: controller.canContinueStep5
                ? () async {
                    try {
                      await controller.submitGroundForVerification();
                      controller.nextStep();
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              error.toString().replaceFirst('Exception: ', ''),
                            ),
                          ),
                        );
                      }
                    }
                  }
                : null,
          ),
          if (controller.isBusy)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(
                color: Color(0xFFDDF730),
                backgroundColor: Color(0x33242424),
              ),
            ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '$entity verification takes up to 2 hours',
              style: const TextStyle(color: Color(0xFFDDF730)),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Next screen: $entity Under Review',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          if (controller.errorMessage != null) ...<Widget>[
            const SizedBox(height: 8),
            Center(
              child: Text(
                controller.errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
