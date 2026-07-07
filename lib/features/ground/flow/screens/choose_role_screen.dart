import 'package:flutter/material.dart';

import '../../../../core/widgets/neon_button.dart';
import '../controllers/ground_flow_controller.dart';
import '../models/ground_registration_data.dart';

class ChooseRoleScreen extends StatelessWidget {
  const ChooseRoleScreen({super.key, required this.controller});

  final GroundFlowController controller;

  @override
  Widget build(BuildContext context) {
    Widget roleCard({
      required UserRole role,
      required String title,
      required String imageAsset,
      bool enabled = true,
    }) {
      final bool selected = controller.data.role == role;
      return Expanded(
        child: GestureDetector(
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
          child: Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0x14000000),
              border: Border.all(color: const Color(0x66DDF730)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(13),
                  ),
                  child: Image.asset(
                    imageAsset,
                    height: 232,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (
                          BuildContext context,
                          Object error,
                          StackTrace? stackTrace,
                        ) {
                          return Container(
                            height: 232,
                            width: double.infinity,
                            color: const Color(0x221C333B),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.white70,
                              size: 44,
                            ),
                          );
                        },
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                    color: selected
                        ? const Color(0x55DDF730)
                        : const Color(0x33DDF730),
                  ),
                  child: Text(
                    enabled ? title : '$title (Disabled)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Choose Your Role',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              roleCard(
                role: UserRole.owner,
                title: 'Cricket Ground Owner',
                imageAsset: 'assets/images/role_1.png',
              ),
              const SizedBox(width: 12),
              roleCard(
                role: UserRole.player,
                title: 'Player',
                imageAsset: 'assets/images/role_2.png',
                enabled: false,
              ),
            ],
          ),
          const Spacer(),
          NeonButton(
            label: 'Next',
            onPressed: () {
              controller.data.role = UserRole.owner;
              controller.update();
              controller.nextStep();
            },
          ),
        ],
      ),
    );
  }
}
