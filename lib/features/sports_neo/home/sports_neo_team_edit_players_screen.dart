import 'package:flutter/material.dart';

import '../../../core/api/ground_wale_api.dart';
import 'sports_neo_team_manage_models.dart';

class SportsNeoTeamEditPlayersScreen extends StatefulWidget {
  const SportsNeoTeamEditPlayersScreen({super.key, required this.teamId});

  final String teamId;

  @override
  State<SportsNeoTeamEditPlayersScreen> createState() =>
      _SportsNeoTeamEditPlayersScreenState();
}

class _SportsNeoTeamEditPlayersScreenState
    extends State<SportsNeoTeamEditPlayersScreen> {
  final SportsNeoTeamManageRepository _repository =
      SportsNeoTeamManageRepository(GroundWaleApi.instance);
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  int _selectedTab = 0;
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

  Future<void> _removePlayer(SportsNeoManagedPlayer player) async {
    final SportsNeoManagedTeam? team = _team;
    if (team == null || player.id.isEmpty) {
      return;
    }
    try {
      final SportsNeoManagedTeam updated = await _repository.removePlayer(
        teamId: team.id,
        playerId: player.id,
      );
      if (!mounted) {
        return;
      }
      setState(() => _team = updated);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  List<SportsNeoManagedPlayer> get _visible {
    final SportsNeoManagedTeam? team = _team;
    if (team == null) {
      return <SportsNeoManagedPlayer>[];
    }
    final String q = _searchController.text.trim().toLowerCase();
    final List<SportsNeoManagedPlayer> source = _selectedTab == 0
        ? team.players.where((player) => !player.isGuest).toList()
        : team.players.where((player) => player.isGuest).toList();
    if (q.isEmpty) {
      return source;
    }
    return source.where((player) {
      return player.name.toLowerCase().contains(q) ||
          player.contactNumber.toLowerCase().contains(q);
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
                  _EditHeader(title: team == null ? 'Team' : '${team.name} Team'),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _SearchBar(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          if (team != null)
                            _HeaderCard(team: team),
                          const SizedBox(height: 16),
                          Row(
                            children: <Widget>[
                              _TabText(
                                text: 'App Users (${team?.appUsersCount ?? 0})',
                                active: _selectedTab == 0,
                                onTap: () => setState(() => _selectedTab = 0),
                              ),
                              const SizedBox(width: 44),
                              _TabText(
                                text: 'Guest Player (${team?.guestPlayersCount ?? 0})',
                                active: _selectedTab == 1,
                                onTap: () => setState(() => _selectedTab = 1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x1FFFFFFF)),
                            ),
                            child: Column(
                              children: _visible
                                  .map(
                                    (SportsNeoManagedPlayer player) => Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: _EditPlayerRow(
                                        player: player,
                                        onRemove: () => _removePlayer(player),
                                      ),
                                    ),
                                  )
                                  .toList(),
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

class _EditHeader extends StatelessWidget {
  const _EditHeader({required this.title});

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
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x0AFFFFFF),
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.team});

  final SportsNeoManagedTeam team;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
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
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(team.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 4),
              Text('${team.playerCount} Players', style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabText extends StatelessWidget {
  const _TabText({required this.text, required this.active, required this.onTap});

  final String text;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          color: active ? const Color(0xFF2563EB) : const Color(0x99FFFFFF),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _EditPlayerRow extends StatelessWidget {
  const _EditPlayerRow({required this.player, required this.onRemove});

  final SportsNeoManagedPlayer player;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
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
              Row(
                children: <Widget>[
                  if (player.playerType.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      child: Text(
                        player.playerType,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  if (player.playerType.isNotEmpty) const SizedBox(width: 6),
                  Text(
                    player.contactNumber,
                    style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onRemove,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE3220D)),
            ),
            child: const Icon(Icons.close, color: Color(0xFFE3220D), size: 18),
          ),
        ),
      ],
    );
  }
}