import 'package:flutter/material.dart';

import '../controllers/ground_flow_controller.dart';
import '../models/ground_registration_data.dart';

class WhatToOfferScreen extends StatelessWidget {
  const WhatToOfferScreen({super.key, required this.controller});

  final GroundFlowController controller;

  static const Color _neon = Color(0xFFD7FF00);
  static const Color _bg = Color(0xFF1D1D1D);
  static const Color _card = Color(0x05FFFFFF);

  @override
  Widget build(BuildContext context) {
    Widget featureItem({required IconData icon, required String label}) {
      return Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: const Color(0xCCE2E8F0)),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 8,
                height: 1.25,
              ),
            ),
          ],
        ),
      );
    }

    Widget offerCard({
      required OfferType offerType,
      required String title,
      required String subtitle,
      required String greatFor,
      required List<Widget> features,
      required IconData icon,
    }) {
      final bool selected = controller.data.offerType == offerType;
      return GestureDetector(
        onTap: () {
          controller.data.offerType = offerType;
          controller.update();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _card,
            border: Border.all(
              color: selected ? const Color(0x80D7FF00) : const Color(0x1AFFFFFF),
            ),
            boxShadow: selected
                ? const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 28,
                      offset: Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Color(0x16000000),
                      blurRadius: 14,
                      offset: Offset(0, 4),
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? const Color(0x4DD7FF00)
                            : const Color(0x26FFFFFF),
                      ),
                      color: selected
                          ? const Color(0x14D7FF00)
                          : const Color(0x0DFFFFFF),
                    ),
                    child: Icon(
                      icon,
                      color: selected ? _neon : Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xFFB8B8B8),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: selected ? _neon : const Color(0xFFB8B8B8),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(children: features),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? const Color(0x26D7FF00) : const Color(0x14FFFFFF),
                  ),
                  color: selected ? const Color(0x0DD7FF00) : const Color(0x08FFFFFF),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: selected ? _neon : const Color(0x26FFFFFF),
                      ),
                      child: Text(
                        'GREAT FOR',
                        style: TextStyle(
                          color: selected ? const Color(0xFF050505) : Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.55,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        greatFor,
                        style: TextStyle(
                          color: selected ? _neon : const Color(0xFFB8B8B8),
                          fontSize: 9,
                          height: 1.4,
                        ),
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

    return Container(
      color: _bg,
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              children: <Widget>[
                const SizedBox(height: 4),
                const Text(
                  'List & Manage',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.76,
                  ),
                ),
                const SizedBox(height: 6),
                const Text.rich(
                  TextSpan(
                    children: <TextSpan>[
                      TextSpan(
                        text: 'List your facilities or programs and manage ',
                        style: TextStyle(color: Color(0xFFA9B0B8), fontSize: 12),
                      ),
                      TextSpan(
                        text: 'Bookings, available ',
                        style: TextStyle(color: Color(0xFFD7FF00), fontSize: 12),
                      ),
                      TextSpan(
                        text: '& More',
                        style: TextStyle(color: Color(0xFFA9B0B8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'What would you like to manage?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose the option that best fits your service.',
                  style: TextStyle(
                    color: Color(0xFFB8B8B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),
                offerCard(
                  offerType: OfferType.cricketGround,
                  title: 'Create Slots for Ground / Courts',
                  subtitle:
                      'List your sports venues and create time slots for bookings.',
                  icon: Icons.dashboard_customize_outlined,
                  features: <Widget>[
                    featureItem(
                      icon: Icons.calendar_month_outlined,
                      label: 'Create & manage\nslots easily',
                    ),
                    featureItem(
                      icon: Icons.sell_outlined,
                      label: 'Set pricing, discounts\n& peak hours',
                    ),
                    featureItem(
                      icon: Icons.event_available_outlined,
                      label: 'Manage bookings\n& availability',
                    ),
                    featureItem(
                      icon: Icons.bar_chart_rounded,
                      label: 'Track earnings\n& performance',
                    ),
                  ],
                  greatFor:
                      'Cricket Grounds, Football Turfs, Badminton Courts, Indoor Courts & more',
                ),
                const SizedBox(height: 16),
                offerCard(
                  offerType: OfferType.academyCoaching,
                  title: 'List Academies / Gym Admissions',
                  subtitle:
                      'List your academies, coaching programs, gyms, swimming pools, yoga classes and more.',
                  icon: Icons.waves_rounded,
                  features: <Widget>[
                    featureItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Manage fees\n& payments',
                    ),
                    featureItem(
                      icon: Icons.task_alt_outlined,
                      label: 'Track attendance\n& progress',
                    ),
                    featureItem(
                      icon: Icons.groups_2_outlined,
                      label: 'Create batches\n& programs',
                    ),
                    featureItem(
                      icon: Icons.support_agent_outlined,
                      label: 'Manage coaches\n& trainers',
                    ),
                  ],
                  greatFor:
                      'Sports Academies, Gyms, Swimming Pools, Yoga Studios & more',
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0x1AFFFFFF)),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0x4DFFFFFF),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Color(0xFFB8B8B8),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'You can add more services later',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Don\'t worry, you can always add or change services from your dashboard.',
                              style: TextStyle(
                                color: Color(0xFFB8B8B8),
                                fontSize: 9,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFB8B8B8),
                        size: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0x00050505), Color(0xFF050505)],
                stops: <double>[0, 0.4],
              ),
            ),
            child: Row(
              children: <Widget>[
                SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: controller.previousStep,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0x80D7FF00)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        color: _neon,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        final OfferType? selected = controller.data.offerType;
                        if (selected != OfferType.cricketGround &&
                            selected != OfferType.academyCoaching) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Select an offering first'),
                            ),
                          );
                          return;
                        }
                        controller.nextStep();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _neon,
                        foregroundColor: const Color(0xFF242424),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
