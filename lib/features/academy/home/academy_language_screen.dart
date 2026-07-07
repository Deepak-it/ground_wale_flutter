import 'package:flutter/material.dart';

class AcademyLanguageScreen extends StatefulWidget {
  const AcademyLanguageScreen({super.key});

  @override
  State<AcademyLanguageScreen> createState() => _AcademyLanguageScreenState();
}

class _AcademyLanguageScreenState extends State<AcademyLanguageScreen> {
  String _selectedLanguage = 'English';

  static const List<String> _languages = <String>[
    'English',
    'Hindi',
    'Marathi',
    'Tamil',
    'Telugu',
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
                      'Select Language',
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
              Container(
                decoration: BoxDecoration(
                  color: const Color(0x08FFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                ),
                child: Column(
                  children: _languages.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final String language = entry.value;
                    return _LanguageTile(
                      title: language,
                      selected: language == _selectedLanguage,
                      showDivider: index != _languages.length - 1,
                      roundedTop: index == 0,
                      roundedBottom: index == _languages.length - 1,
                      onTap: () {
                        setState(() => _selectedLanguage = language);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _ProfileBottomNav(
        onHomeTap: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.title,
    required this.selected,
    required this.onTap,
    this.showDivider = true,
    this.roundedTop = false,
    this.roundedBottom = false,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final bool showDivider;
  final bool roundedTop;
  final bool roundedBottom;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(roundedTop ? 12 : 0),
          topRight: Radius.circular(roundedTop ? 12 : 0),
          bottomLeft: Radius.circular(roundedBottom ? 12 : 0),
          bottomRight: Radius.circular(roundedBottom ? 12 : 0),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(roundedTop ? 12 : 0),
              topRight: Radius.circular(roundedTop ? 12 : 0),
              bottomLeft: Radius.circular(roundedBottom ? 12 : 0),
              bottomRight: Radius.circular(roundedBottom ? 12 : 0),
            ),
            border: showDivider
                ? const Border(bottom: BorderSide(color: Color(0x1FFFFFFF)))
                : null,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF00C9A7),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileBottomNav extends StatelessWidget {
  const _ProfileBottomNav({required this.onHomeTap});

  final VoidCallback onHomeTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
      decoration: const BoxDecoration(
        color: Color(0x0FFFFFFF),
        border: Border(top: BorderSide(color: Color(0x1FFFFFFF))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _BottomNavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            selected: false,
            onTap: onHomeTap,
          ),
          const _BottomNavItem(
            icon: Icons.campaign_outlined,
            label: 'Announcement',
            selected: false,
          ),
          const _BottomNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            selected: true,
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected
        ? const Color(0xFF00C9A7)
        : const Color(0xFF9FB9B3);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 90,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
