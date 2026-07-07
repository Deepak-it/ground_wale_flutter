import 'package:flutter/material.dart';

import '../../../../core/widgets/neon_button.dart';
import '../controllers/ground_flow_controller.dart';
import '../models/ground_registration_data.dart';

class WhatToOfferScreen extends StatelessWidget {
  const WhatToOfferScreen({super.key, required this.controller});

  final GroundFlowController controller;

  @override
  Widget build(BuildContext context) {
    Widget offerCard({
      required OfferType type,
      required String title,
      required String subtitle,
      required String imageAsset,
    }) {
      final bool selected = controller.data.offerType == type;
      return GestureDetector(
        onTap: () {
          controller.data.offerType = type;
          controller.update();
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: selected ? const Color(0x33DDF730) : const Color(0x14FFFFFF),
            border: Border.all(
              color: selected
                  ? const Color(0xFFDDF730)
                  : const Color(0x66FFFFFF),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 128,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  color: const Color(0x3322332D),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  child: Image.asset(
                    imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (
                          BuildContext context,
                          Object error,
                          StackTrace? stackTrace,
                        ) {
                          return const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.white70,
                              size: 40,
                            ),
                          );
                        },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
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

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'What do you Want to Offer?',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose one option to continue',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: <Widget>[
                offerCard(
                  type: OfferType.cricketGround,
                  title: 'Cricket Ground',
                  subtitle: 'Create slots for T10/T20/full day matches',
                  imageAsset: 'assets/images/offer_1.png',
                ),
                const SizedBox(height: 14),
                offerCard(
                  type: OfferType.academyCoaching,
                  title: 'Academy / Coaching',
                  subtitle: 'Run regular training batches',
                  imageAsset: 'assets/images/offer_2.png',
                ),
                const SizedBox(height: 14),
                offerCard(
                  type: OfferType.boxCricket,
                  title: 'Box Cricket',
                  subtitle: 'Users can book compact box slots',
                  imageAsset: 'assets/images/offer_3.png',
                )
              ],
            ),
          ),
          const SizedBox(height: 12),
          NeonButton(
            label: 'Next',
            onPressed: () {
              if (controller.data.offerType == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Select an offering first')),
                );
                return;
              }

              controller.nextStep();
            },
          ),
        ],
      ),
    );
  }
}
