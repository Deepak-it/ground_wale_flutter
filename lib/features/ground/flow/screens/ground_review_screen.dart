import 'package:flutter/material.dart';

import '../controllers/ground_flow_controller.dart';

class GroundReviewScreen extends StatelessWidget {
  const GroundReviewScreen({super.key, required this.controller});

  final GroundFlowController controller;

  @override
  Widget build(BuildContext context) {
    final data = controller.data;
    const Color neon = Color(0xFFD7FF00);

    Widget detailItem({
      required IconData icon,
      required String label,
      required String value,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x40D7FF00)),
                color: const Color(0x0DD7FF00),
              ),
              child: Icon(icon, color: neon, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF8A8A8A),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final String groundName = data.groundName.trim().isEmpty
        ? 'Alexa Ground'
        : data.groundName.trim();
    final String phone = data.contactNumber.trim().isEmpty
        ? '+91 98765 43210'
        : data.contactNumber.trim();
    final String address = data.address.trim().isEmpty
        ? 'Flat 203, Green Park Society, Sector 21, Mumbai - 400001'
        : data.address.trim();
    final String landmark = data.landmark.trim().isEmpty
        ? 'Flower Shop, Hanuman Mandir'
        : data.landmark.trim();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1D1D1D),
        image: DecorationImage(
          image: AssetImage('assets/crick/images/ground.png'),
          fit: BoxFit.cover,
          opacity: 0.12,
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: <Widget>[
            Row(
              children: <Widget>[
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    onPressed: controller.previousStep,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFFD7FF00),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Ground / Court  Review',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.88,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Review your details before proceeding',
              style: TextStyle(color: Color(0xFF9A9A9A), fontSize: 14),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0x2ED7FF00)),
                color: const Color(0xEB0F0F0F),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x1FD7FF00),
                    blurRadius: 26,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: neon, width: 1.6),
                          image: const DecorationImage(
                            image: AssetImage('assets/crick/images/ground.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Ground Name',
                              style: TextStyle(
                                color: Color(0xFF8A8A8A),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              groundName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.84,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                color: const Color(0x1FD7FF00),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    '●',
                                    style: TextStyle(
                                      color: Color(0xFFD7FF00),
                                      fontSize: 11,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Active',
                                    style: TextStyle(
                                      color: Color(0xFFD7FF00),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: Color(0x14FFFFFF), height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: detailItem(
                          icon: Icons.location_on_outlined,
                          label: 'State',
                          value: data.state,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: detailItem(
                          icon: Icons.location_city_outlined,
                          label: 'City',
                          value: data.city,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0x14FFFFFF), height: 1),
                  const SizedBox(height: 14),
                  detailItem(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: phone,
                  ),
                  const Divider(color: Color(0x14FFFFFF), height: 1),
                  const SizedBox(height: 14),
                  detailItem(
                    icon: Icons.map_outlined,
                    label: 'Address',
                    value: address,
                  ),
                  const Divider(color: Color(0x14FFFFFF), height: 1),
                  const SizedBox(height: 14),
                  detailItem(
                    icon: Icons.account_balance_outlined,
                    label: 'Landmark',
                    value: landmark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x1AD7FF00)),
                color: const Color(0xF2121212),
                boxShadow: const <BoxShadow>[
                  BoxShadow(color: Color(0x0ED7FF00), blurRadius: 15),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0x26D7FF00),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(color: Color(0x33D7FF00), blurRadius: 14),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFFD7FF00),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Looks good!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Your ground details are ready to go.',
                          style: TextStyle(
                            color: Color(0xFF8A8A8A),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: neon),
                    ),
                    child: const Icon(
                      Icons.assignment_turned_in_outlined,
                      color: Color(0xFFD7FF00),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0x66D7FF00),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFFD7FF00),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Need to make changes?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'You can go back and edit the details.',
                          style: TextStyle(
                            color: Color(0xFF8A8A8A),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: controller.previousStep,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD7FF00)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Edit Details',
                      style: TextStyle(
                        color: Color(0xFFD7FF00),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: controller.nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDDF730),
                  foregroundColor: const Color(0xFF1D1D1D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
