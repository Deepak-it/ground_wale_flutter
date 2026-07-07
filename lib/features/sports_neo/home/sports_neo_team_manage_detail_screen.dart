import 'package:flutter/material.dart';

import '../../../core/api/ground_wale_api.dart';
import 'sports_neo_team_add_player_screen.dart';
import 'sports_neo_team_edit_players_screen.dart';
import 'sports_neo_team_manage_models.dart';

class SportsNeoTeamManageDetailScreen extends StatefulWidget {
  const SportsNeoTeamManageDetailScreen({super.key, required this.teamId});

  final String teamId;

  @override
  State<SportsNeoTeamManageDetailScreen> createState() =>
      _SportsNeoTeamManageDetailScreenState();
}

class _SportsNeoTeamManageDetailScreenState
    extends State<SportsNeoTeamManageDetailScreen> {
  final SportsNeoTeamManageRepository _repository =
      SportsNeoTeamManageRepository(GroundWaleApi.instance);
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  SportsNeoManagedTeam? _team;

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTeam() async {
    try {
      final SportsNeoManagedTeam team = await _repository.getTeam(widget.teamId);
      if (!mounted) {
        return;
      }
      setState(() {
        _team = team;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  List<SportsNeoManagedPlayer> get _visiblePlayers {
    final SportsNeoManagedTeam? team = _team;
    if (team == null) {
      return <SportsNeoManagedPlayer>[];
    }
    final String query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return team.players;
    }
    return team.players.where((player) {
      return player.name.toLowerCase().contains(query) ||
          player.contactNumber.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final SportsNeoManagedTeam? team = _team;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
              )
            : Column(
                children: <Widget>[
                  _TeamDetailHeader(title: '${team?.name ?? 'Team'} Team'),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _SearchBox(controller: _searchController, onChanged: (_) => setState(() {})),
                          const SizedBox(height: 16),
                          if (team != null)
                            _SimpleTeamCard(
                              team: team,
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => SportsNeoTeamEditPlayersScreen(teamId: team.id),
                                  ),
                                );
                                _loadTeam();
                              },
                            ),
                          if (_visiblePlayers.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 16),
                            ..._visiblePlayers.map(
                              (SportsNeoManagedPlayer player) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _PlayerPreviewCard(player: player),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2563EB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: team == null
                            ? null
                            : () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => SportsNeoTeamAddPlayerScreen(teamId: team.id, teamName: team.name),
                                  ),
                                );
                                _loadTeam();
                              },
                        child: const Text(
                          'Add Player',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TeamDetailHeader extends StatelessWidget {
  const _TeamDetailHeader({required this.title});

  final String title;

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
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.12),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.search, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Search player by name or number',
                hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleTeamCard extends StatelessWidget {
  const _SimpleTeamCard({required this.team, required this.onTap});

  final SportsNeoManagedTeam team;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x1FFFFFFF)),
          color: const Color(0x14FFFFFF),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                team.name.isEmpty ? '?' : team.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  team.name,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '${team.playerCount} Players',
                  style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerPreviewCard extends StatelessWidget {
  const _PlayerPreviewCard({required this.player});

  final SportsNeoManagedPlayer player;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x14FFFFFF),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              player.name.isEmpty ? '?' : player.name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(player.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  player.contactNumber.isEmpty ? 'No number' : player.contactNumber,
                  style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}