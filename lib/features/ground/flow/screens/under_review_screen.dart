import 'package:flutter/material.dart';

import '../../../../core/api/api_session.dart';
import '../../../../core/api/ground_wale_api.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/neon_button.dart';
import '../models/ground_registration_data.dart';

class UnderReviewScreen extends StatelessWidget {
  const UnderReviewScreen({super.key, required this.onFinish, this.offerType});

  final VoidCallback onFinish;
  final OfferType? offerType;

  @override
  Widget build(BuildContext context) {
    final String? groundId = ApiSession.instance.groundId;
    final bool academyFlow = offerType == OfferType.academyCoaching;
    final String entity = academyFlow
        ? 'Academy'
        : (offerType == OfferType.sportsNeo ? 'Sports Neo' : 'Ground');

    Widget statusTile({
      required String title,
      required String subtitle,
      required String badge,
    }) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0x0FFFFFFF),
          border: Border.all(color: const Color(0x22FFFFFF)),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.check_circle_outline, color: Color(0xFFDDF730)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF8AA39A)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0x29F59E0B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: FutureBuilder<Map<String, dynamic>>(
        future: groundId == null
            ? Future<Map<String, dynamic>>.value(<String, dynamic>{
                'reviewStatus': 'under_review',
              })
            : GroundWaleApi.instance.getReviewStatus(groundId),
        builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          final Map<String, dynamic> data =
              snapshot.data ?? <String, dynamic>{};
          final String reviewStatus =
              data['reviewStatus']?.toString() ?? 'under_review';
          final String groundName =
              data['groundName']?.toString() ?? 'Your Ground';
          final String reviewNotes =
              data['reviewNotes']?.toString() ??
              'Approval usually takes a short time. You can go to the dashboard while we complete the review.';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '$entity Under Review',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'We are verifying ${academyFlow ? 'your academy' : groundName}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0x1FF59E0B),
                  border: Border.all(color: const Color(0x40F59E0B)),
                ),
                child: Column(
                  children: <Widget>[
                    const Icon(
                      Icons.timelapse,
                      size: 56,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      reviewStatus == 'approved'
                          ? '$entity Approved'
                          : 'Your $entity is Under Review',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reviewNotes,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF8AA39A)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      reviewStatus.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Review Status',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      reviewNotes,
                      style: const TextStyle(color: Color(0xFF8AA39A)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              statusTile(
                title: 'Submitted',
                subtitle: '$entity details shared with our team',
                badge: 'Done',
              ),
              const SizedBox(height: 10),
              statusTile(
                title: 'In Review',
                subtitle: 'We are verifying your $entity details',
                badge: reviewStatus == 'approved' ? 'Done' : 'Ongoing',
              ),
              const SizedBox(height: 10),
              statusTile(
                title: 'Approved',
                subtitle: 'You will be notified once approval is complete',
                badge: reviewStatus == 'approved' ? 'Done' : 'Pending',
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'What you can do now',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You can continue to the dashboard and explore available features while your $entity review is in progress.',
                      style: const TextStyle(color: Color(0xFF8AA39A)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(
                    color: Color(0xFFDDF730),
                    backgroundColor: Color(0x33242424),
                  ),
                ),
              NeonButton(label: 'Go to Dashboard', onPressed: onFinish),
            ],
          );
        },
      ),
    );
  }
}
