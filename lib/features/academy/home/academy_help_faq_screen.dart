import 'package:flutter/material.dart';

class AcademyHelpFaqScreen extends StatefulWidget {
  const AcademyHelpFaqScreen({super.key});

  @override
  State<AcademyHelpFaqScreen> createState() => _AcademyHelpFaqScreenState();
}

class _AcademyHelpFaqScreenState extends State<AcademyHelpFaqScreen> {
  int? _expandedIndex;

  static const List<_FaqItemData> _items = <_FaqItemData>[
    _FaqItemData(
      question: 'How to mark Attendance?',
      answer:
          'Open the student or batch attendance screen, select the session date, '
          'mark each student as present or absent, and save the update.',
    ),
    _FaqItemData(
      question: 'How to add a new student?',
      answer:
          'Go to Manage Students, tap Add Student, fill in the student details, '
          'assign the batch, and submit to save the new record.',
    ),
    _FaqItemData(
      question: 'How to collect fees?',
      answer:
          'Open the student fee details or payment section, choose the payment '
          'method, enter the amount received, and confirm the payment.',
    ),
    _FaqItemData(
      question: 'How to edit batch timings?',
      answer:
          'Open the batch details screen, choose Edit Batch, update the time slot '
          'or schedule fields, and save the changes.',
    ),
    _FaqItemData(
      question: 'How to send fee reminders?',
      answer:
          'Use the reminders or communication settings flow to select students '
          'with dues and trigger WhatsApp or SMS reminder messages.',
    ),
    _FaqItemData(
      question: 'How to view payment history?',
      answer:
          'Open the student profile or fee details screen and review the payment '
          'history section for previous transactions and dues.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Help / FAQ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ..._items.asMap().entries.map(
                (MapEntry<int, _FaqItemData> entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FaqTile(
                    question: entry.value.question,
                    answer: entry.value.answer,
                    expanded: _expandedIndex == entry.key,
                    onTap: () {
                      setState(() {
                        _expandedIndex = _expandedIndex == entry.key
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
      ),
      bottomNavigationBar: null,
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.question,
    required this.answer,
    required this.expanded,
    required this.onTap,
  });

  final String question;
  final String answer;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0x08FFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: expanded
                  ? const Color(0xFF00C9A7)
                  : const Color(0x1FFFFFFF),
            ),
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
                  const SizedBox(width: 12),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: expanded ? const Color(0xFF00C9A7) : Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    answer,
                    style: const TextStyle(
                      color: Color(0xCCFFFFFF),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
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
