import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';

class BoxCricketHelpSupportScreen extends StatefulWidget {
  const BoxCricketHelpSupportScreen({super.key});

  @override
  State<BoxCricketHelpSupportScreen> createState() =>
      _BoxCricketHelpSupportScreenState();
}

class _BoxCricketHelpSupportScreenState
    extends State<BoxCricketHelpSupportScreen> {
  bool _isSubmitting = false;
  int? _expandedFaqIndex;

  static const List<_FaqItemData> _faqItems = <_FaqItemData>[
    _FaqItemData(
      question: 'How do I change my ground Pricing?',
      answer:
          'Open Manage Slots, select the slot or pricing section, update the amount, and save changes.',
    ),
    _FaqItemData(
      question: 'When will be receive my payments?',
      answer:
          'Payments are usually settled as per your payout cycle after booking completion.',
    ),
    _FaqItemData(
      question: 'How do I handle booking cancellations?',
      answer:
          'Open booking details and use the reject or cancel flow with a reason based on policy.',
    ),
    _FaqItemData(
      question: 'Can I block specific Time Slots?',
      answer:
          'Yes. Go to Manage Slots, choose a slot, and use Block Slot to make it unavailable.',
    ),
  ];

  Future<void> _createSupportTicket(String channel) async {
    final ApiSession session = ApiSession.instance;
    final String? ownerId = session.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await GroundWaleApi.instance.createSupportTicket(<String, dynamic>{
        'ownerId': ownerId,
        'groundId': session.groundId,
        'subject': 'Box Cricket Support Request',
        'message':
            'Support requested via $channel from Flutter app. Please contact the owner.',
      });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Support request submitted')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1F1B),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: <Widget>[
            Row(
              children: <Widget>[
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFFDDF730),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Help & Support',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Contact Support',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0x08FFFFFF),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x17000000),
                    blurRadius: 12,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: <Widget>[
                  _contactTile(
                    icon: Icons.call_outlined,
                    iconColor: Colors.white,
                    iconBg: const Color(0x1F08B36A),
                    title: 'Call Support',
                    subtitle: '1800-123-4567',
                    onTap: _isSubmitting
                        ? null
                        : () => _createSupportTicket('Call Support'),
                  ),
                  const SizedBox(height: 16),
                  _contactTile(
                    icon: Icons.mail_outline_rounded,
                    iconColor: const Color(0xFF2563EB),
                    iconBg: const Color(0x1F2563EB),
                    title: 'Email Support',
                    subtitle: 'Support@groundbook.com',
                    onTap: _isSubmitting
                        ? null
                        : () => _createSupportTicket('Email Support'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Frequantly Asked Questions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ..._faqItems.asMap().entries.map(
              (MapEntry<int, _FaqItemData> entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _faqTile(
                  question: entry.value.question,
                  answer: entry.value.answer,
                  expanded: _expandedFaqIndex == entry.key,
                  onTap: () {
                    setState(() {
                      _expandedFaqIndex = _expandedFaqIndex == entry.key
                          ? null
                          : entry.key;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x1FFFFFFF)),
          color: const Color(0x08FFFFFF),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x17000000),
              blurRadius: 12,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _faqTile({
    required String question,
    required String answer,
    required bool expanded,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: expanded
                  ? const Color(0xFF08B36A)
                  : const Color(0x1FFFFFFF),
            ),
            color: const Color(0x08FFFFFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      question,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 24,
                      color: expanded ? const Color(0xFF08B36A) : Colors.white,
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    answer,
                    style: const TextStyle(
                      color: Color(0xCCFFFFFF),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ),
                crossFadeState: expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 180),
                sizeCurve: Curves.easeInOut,
                firstCurve: Curves.easeInOut,
                secondCurve: Curves.easeInOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqItemData {
  const _FaqItemData({required this.question, required this.answer});

  final String question;
  final String answer;
}
