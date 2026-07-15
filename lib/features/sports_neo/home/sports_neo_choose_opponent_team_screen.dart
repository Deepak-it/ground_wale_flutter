import 'package:flutter/material.dart';

import 'sports_neo_choose_team_screen.dart';

class SportsNeoChooseOpponentTeamScreen extends StatelessWidget {
  const SportsNeoChooseOpponentTeamScreen({
    super.key,
    this.current,
  });

  final SportsNeoTeamInfo? current;

  @override
  Widget build(BuildContext context) {
    final List<SportsNeoTeamInfo> teams = <SportsNeoTeamInfo>[
      const SportsNeoTeamInfo(
        name: 'Manu XI',
        players: 11,
        color: Color(0xFF2563EB),
      ),
      const SportsNeoTeamInfo(
        name: 'Riders CC',
        players: 10,
        color: Color(0xFFEA580C),
      ),
      const SportsNeoTeamInfo(
        name: 'Titans 11',
        players: 11,
        color: Color(0xFF16A34A),
      ),
      const SportsNeoTeamInfo(
        name: 'Lions Squad',
        players: 9,
        color: Color(0xFF9333EA),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _TopHeader(
              title: 'Choose Opponent Team',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                child: Column(
                  children: <Widget>[
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0x0AFFFFFF),
                      ),
                      child: const Row(
                        children: <Widget>[
                          Icon(Icons.search, color: Colors.white, size: 20),
                          SizedBox(width: 12),
                          Text(
                            'Search team',
                            style: TextStyle(
                              color: Color(0x99FFFFFF),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        itemCount: teams.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, int index) {
                          final SportsNeoTeamInfo team = teams[index];
                          final bool selected = current?.name == team.name;
                          return InkWell(
                            onTap: () => Navigator.of(context).pop(team),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0x1FFFFFFF),
                                ),
                              ),
                              child: Row(
                                children: <Widget>[
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: team.color,
                                    child: Text(
                                      team.name.substring(0, 1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          team.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${team.players} Players',
                                          style: const TextStyle(
                                            color: Color(0x99FFFFFF),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF121C3E),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        children: <Widget>[
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(22),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
