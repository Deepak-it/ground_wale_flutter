import 'package:flutter/material.dart';

import '../../../core/api/ground_wale_api.dart';
import 'sports_neo_edit_team_screen.dart';
import 'sports_neo_matches_models.dart';
import 'sports_neo_team_details_screen.dart';

class SportsNeoMyMatchesScreen extends StatefulWidget {
  const SportsNeoMyMatchesScreen({super.key});

  @override
  State<SportsNeoMyMatchesScreen> createState() => _SportsNeoMyMatchesScreenState();
}

class _SportsNeoMyMatchesScreenState extends State<SportsNeoMyMatchesScreen> {
  final SportsNeoMatchesRepository _repository =
      SportsNeoMatchesRepository(GroundWaleApi.instance);
  bool _isLoading = true;
  int _selectedTab = 0;
  List<SportsNeoTeamSummary> _teams = <SportsNeoTeamSummary>[];

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      final List<SportsNeoTeamSummary> teams = await _repository.loadTeams();
      if (!mounted) {
        return;
      }
      setState(() {
        _teams = teams;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
    }
  }

  List<SportsNeoTeamSummary> get _createdTeams =>
      _teams.where((team) => team.createdByMe).toList();

  List<SportsNeoTeamSummary> get _playedTeams =>
      _teams.where((team) => !team.createdByMe).toList();

  @override
  Widget build(BuildContext context) {
    final List<SportsNeoTeamSummary> visible =
        _selectedTab == 0 ? _createdTeams : _playedTeams;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _MyMatchesHeader(
              onCreateTeam: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Create Team flow is not available yet'),
                  ),
                );
              },
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _TeamSegmentedControl(
                            selectedIndex: _selectedTab,
                            onChanged: (int index) {
                              setState(() => _selectedTab = index);
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedTab == 0
                                ? 'CREATED BY ME - ${_createdTeams.length} TEAMS'
                                : 'PLAYED TEAMS - ${_playedTeams.length} TEAMS',
                            style: const TextStyle(
                              color: Color(0x99FFFFFF),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (visible.isEmpty)
                            const _MyMatchesEmptyState()
                          else
                            ...visible.map(
                              (SportsNeoTeamSummary team) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _TeamCard(
                                  team: team,
                                  onView: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => SportsNeoTeamDetailsScreen(team: team),
                                      ),
                                    );
                                  },
                                  onEdit: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => SportsNeoEditTeamScreen(team: team),
                                      ),
                                    );
                                  },
                                  onAddPlayers: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => SportsNeoEditTeamScreen(team: team),
                                      ),
                                    );
                                  },
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

class _MyMatchesHeader extends StatelessWidget {
  const _MyMatchesHeader({required this.onCreateTeam});

  final VoidCallback onCreateTeam;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF121C3E),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      child: Row(
        children: <Widget>[
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(22),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'My Teams',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          InkWell(
            onTap: onCreateTeam,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Create Team',
                style: TextStyle(
                  color: Color(0xFF242424),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamSegmentedControl extends StatelessWidget {
  const _TeamSegmentedControl({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const List<String> labels = <String>['My Teams', 'Played Teams'];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        children: List<Widget>.generate(labels.length, (int index) {
          final bool active = index == selectedIndex;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF2563EB) : const Color(0x0AFFFFFF),
                  borderRadius: index == 0
                      ? const BorderRadius.horizontal(left: Radius.circular(12))
                      : const BorderRadius.horizontal(right: Radius.circular(12)),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.team,
    required this.onView,
    required this.onEdit,
    required this.onAddPlayers,
  });

  final SportsNeoTeamSummary team;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onAddPlayers;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x0AFFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            team.teamName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _TeamStatTile(
                  value: '${team.playerCount}',
                  label: 'Players',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TeamStatTile(
                  value: '${team.matchesCount}',
                  label: team.createdByMe ? 'Matches' : 'Matches Played',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: <Widget>[
              _InlineActionText(label: 'View team', onTap: onView),
              _InlineActionText(label: 'Edit Team', onTap: onEdit),
              _InlineActionText(label: 'Add Players', onTap: onAddPlayers),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamStatTile extends StatelessWidget {
  const _TeamStatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0x0AFFFFFF),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineActionText extends StatelessWidget {
  const _InlineActionText({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF2563EB),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _MyMatchesEmptyState extends StatelessWidget {
  const _MyMatchesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x0AFFFFFF),
      ),
      child: const Column(
        children: <Widget>[
          Icon(Icons.groups_2_outlined, color: Colors.white, size: 32),
          SizedBox(height: 10),
          Text(
            'No teams found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Teams will appear here once bookings are available in the API.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0x99FFFFFF),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}