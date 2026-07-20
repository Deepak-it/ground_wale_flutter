import 'package:flutter/material.dart';

import 'sports_neo_change_my_team_screen.dart';
import 'sports_neo_choose_opponent_team_screen.dart';
import 'sports_neo_split_payment_flow_screens.dart';

class SportsNeoTeamInfo {
  const SportsNeoTeamInfo({
    required this.name,
    required this.players,
    required this.color,
  });

  final String name;
  final int players;
  final Color color;
}

class SportsNeoChooseTeamScreen extends StatefulWidget {
  const SportsNeoChooseTeamScreen({super.key, required this.amount});

  final int amount;

  @override
  State<SportsNeoChooseTeamScreen> createState() => _SportsNeoChooseTeamScreenState();
}

class _SportsNeoChooseTeamScreenState extends State<SportsNeoChooseTeamScreen> {
  SportsNeoTeamInfo _myTeam = const SportsNeoTeamInfo(
    name: 'Thunderbolts XI',
    players: 11,
    color: Color(0xFF0EA5E9),
  );
  SportsNeoTeamInfo? _opponentTeam;

  Future<void> _changeMyTeam() async {
    final SportsNeoTeamInfo? selected = await Navigator.of(context).push<SportsNeoTeamInfo>(
      MaterialPageRoute<SportsNeoTeamInfo>(
        builder: (_) => SportsNeoChangeMyTeamScreen(current: _myTeam),
      ),
    );
    if (selected != null) {
      setState(() => _myTeam = selected);
    }
  }

  Future<void> _pickOpponent() async {
    final SportsNeoTeamInfo? selected = await Navigator.of(context).push<SportsNeoTeamInfo>(
      MaterialPageRoute<SportsNeoTeamInfo>(
        builder: (_) => SportsNeoChooseOpponentTeamScreen(current: _opponentTeam),
      ),
    );
    if (selected != null) {
      setState(() => _opponentTeam = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _TopHeader(
              title: 'Choose Team',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _TeamCard(
                      title: 'My Team',
                      team: _myTeam,
                      chipLabel: 'Change your team',
                      onChipTap: _changeMyTeam,
                    ),
                    const SizedBox(height: 20),
                    const Icon(
                      Icons.sports_score_outlined,
                      color: Color(0xFFF59E0B),
                      size: 36,
                    ),
                    const SizedBox(height: 20),
                    _opponentTeam == null
                        ? _EmptyOpponent(onTap: _pickOpponent)
                        : _TeamCard(
                            title: 'Opponent Team',
                            team: _opponentTeam!,
                            chipLabel: 'Change opponent team',
                            onChipTap: _pickOpponent,
                          ),
                    const Spacer(),
                    if (_opponentTeam != null)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => SportsNeoSplitWithOpponentTeamScreen(
                                  myTeam: _myTeam,
                                  opponentTeam: _opponentTeam!,
                                  amount: widget.amount,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Add Squad and split payment',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.title,
    required this.team,
    required this.chipLabel,
    required this.onChipTap,
  });

  final String title;
  final SportsNeoTeamInfo team;
  final String chipLabel;
  final VoidCallback onChipTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        CircleAvatar(
          radius: 33,
          backgroundColor: team.color,
          child: Text(
            team.name.substring(0, 1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 8),
        InkWell(
          onTap: onChipTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0x1F08B36A),
            ),
            child: Text(
              chipLabel,
              style: const TextStyle(
                color: Color(0xFF2EDB54),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyOpponent extends StatelessWidget {
  const _EmptyOpponent({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Text(
          'Opponent Team',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.white, style: BorderStyle.solid),
              color: const Color(0x0AFFFFFF),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 34),
          ),
        ),
      ],
    );
  }
}
