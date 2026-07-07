import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'profile_turf_ui.dart';

class HelpSupportTurfScreen extends StatefulWidget {
  const HelpSupportTurfScreen({super.key});

  @override
  State<HelpSupportTurfScreen> createState() => _HelpSupportTurfScreenState();
}

class _HelpSupportTurfScreenState extends State<HelpSupportTurfScreen> {
  bool _isSubmitting = false;

  Future<void> _contactSupport() async {
    final ApiSession session = ApiSession.instance;
    if (!session.isAuthenticated) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await GroundWaleApi.instance.createSupportTicket(<String, dynamic>{
        'ownerId': session.ownerId,
        'groundId': session.groundId,
        'subject': 'Help requested from app',
        'message': 'Please contact me regarding account and ground management support.',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Support ticket created')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget faq(String question, String answer) {
      return TurfCard(
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          collapsedIconColor: const Color(0xFFDDF730),
          iconColor: const Color(0xFFDDF730),
          title: Text(question),
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(answer, style: const TextStyle(color: Colors.white70)),
              ),
            ),
          ],
        ),
      );
    }

    return TurfPageScaffold(
      title: 'Tap on help & Support',
      child: ListView(
        children: <Widget>[
          faq('How do I block slots?', 'Open view-all-slots and use the block action for any slot.'),
          faq('When do I receive payouts?', 'Payouts settle as per weekly settlement cycle.'),
          faq('How can I edit bank details?', 'Go to Bank Account and tap edit bank text button.'),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _isSubmitting ? null : _contactSupport, child: const Text('Contact Support')),
        ],
      ),
    );
  }
}
