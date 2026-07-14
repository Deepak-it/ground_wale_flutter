import 'package:flutter/material.dart';

class AcademyLegalScreen extends StatefulWidget {
  const AcademyLegalScreen({super.key});

  @override
  State<AcademyLegalScreen> createState() => _AcademyLegalScreenState();
}

class _AcademyLegalScreenState extends State<AcademyLegalScreen> {
  bool _showTerms = true;

  static const List<_LegalSection> _termsSections = <_LegalSection>[
    _LegalSection(
      title: 'Acceptance of Terms',
      body:
          'By accessing and using this academy management application, you accept '
          'and agree to be bound by the terms and provision of this agreement.',
    ),
    _LegalSection(
      title: 'Use License',
      body:
          'Permission is granted to temporarily use this application for personal, '
          'non-commercial purposes only. This is the grant of a license, not a '
          'transfer of title.',
    ),
    _LegalSection(
      title: 'User Obligations',
      body:
          'You agree to use the application only for lawful purposes and in '
          'accordance with these Terms. You must not use the application in any '
          'way that violates any applicable laws or regulations.',
    ),
    _LegalSection(
      title: 'Data Security',
      body:
          'We implement appropriate security measures to protect your data. '
          'However, no method of transmission over the Internet is 100% secure.',
    ),
    _LegalSection(
      title: 'Limitation of Liability',
      body:
          'In no event shall the application or its suppliers be liable for any '
          'damages arising out of the use or inability to use the application.',
    ),
  ];

  static const List<_LegalSection> _privacySections = <_LegalSection>[
    _LegalSection(
      title: 'Information We Collect',
      body:
          'We collect the information needed to manage academy operations, '
          'including profile details, student records, attendance, and payment data.',
    ),
    _LegalSection(
      title: 'How We Use Data',
      body:
          'Your information is used to operate the app, send reminders, track '
          'payments, and improve the experience for academy staff and parents.',
    ),
    _LegalSection(
      title: 'Data Sharing',
      body:
          'We do not sell your personal data. Information may be shared only with '
          'service providers required to deliver core academy features.',
    ),
    _LegalSection(
      title: 'Retention and Security',
      body:
          'We retain data only as long as necessary for operations and compliance, '
          'and we apply reasonable safeguards to protect stored information.',
    ),
    _LegalSection(
      title: 'Your Choices',
      body:
          'You can request updates or corrections to your account information '
          'through academy support channels.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final List<_LegalSection> sections = _showTerms
        ? _termsSections
        : _privacySections;

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
                      'Legal',
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
              Row(
                children: <Widget>[
                  Expanded(
                    child: _LegalTabButton(
                      title: 'Terms of Service',
                      selected: _showTerms,
                      onTap: () => setState(() => _showTerms = true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LegalTabButton(
                      title: 'Privacy Policy',
                      selected: !_showTerms,
                      onTap: () => setState(() => _showTerms = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                _showTerms ? 'Terms of Service' : 'Privacy Policy',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ...sections.asMap().entries.map(
                (MapEntry<int, _LegalSection> entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _LegalContentSection(
                    index: entry.key + 1,
                    section: entry.value,
                  ),
                ),
              ),
              const Text(
                'Last updated: March 24, 2026',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
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

class _LegalTabButton extends StatelessWidget {
  const _LegalTabButton({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF00C9A7) : const Color(0x08FFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF1C333B)
                  : const Color(0x1FFFFFFF),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? const Color(0xFF242424) : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalContentSection extends StatelessWidget {
  const _LegalContentSection({required this.index, required this.section});

  final int index;
  final _LegalSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '$index. ${section.title}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          section.body,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _LegalSection {
  const _LegalSection({required this.title, required this.body});

  final String title;
  final String body;
}
