import 'package:flutter/material.dart';

import '../../../core/api/ground_wale_api.dart';
import 'sports_neo_team_manage_detail_screen.dart';
import 'sports_neo_team_manage_models.dart';

class SportsNeoManageTeamsScreen extends StatefulWidget {
  const SportsNeoManageTeamsScreen({super.key});

  @override
  State<SportsNeoManageTeamsScreen> createState() => _SportsNeoManageTeamsScreenState();
}

class _SportsNeoManageTeamsScreenState extends State<SportsNeoManageTeamsScreen> {
  final SportsNeoTeamManageRepository _repository =
  SportsNeoTeamManageRepository(GroundWaleApi.instance);
  final TextEditingController _teamNameController = TextEditingController();

  bool _isLoading = true;
  bool _isCreating = false;
  bool _showCreateSheet = false;
  List<SportsNeoManagedTeam> _teams = <SportsNeoManagedTeam>[];

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    try {
      final List<SportsNeoManagedTeam> teams = await _repository.listTeams();
      if (!mounted) {
        return;
      }
      setState(() {
        _teams = teams;
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

  Future<void> _createTeam() async {
    final String name = _teamNameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    setState(() => _isCreating = true);
    try {
      final SportsNeoManagedTeam team = await _repository.createTeam(name);
      if (!mounted) {
        return;
      }
      setState(() {
        _teams = <SportsNeoManagedTeam>[team, ..._teams];
        _showCreateSheet = false;
        _teamNameController.clear();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _deleteTeam(SportsNeoManagedTeam team) async {
    try {
      await _repository.deleteTeam(team.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _teams.removeWhere((item) => item.id == team.id);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _openTeam(SportsNeoManagedTeam team) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SportsNeoTeamManageDetailScreen(teamId: team.id),
      ),
    );
    _loadTeams();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                const _ManageHeader(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          child: Column(
                            children: _teams
                                .map(
                                  (SportsNeoManagedTeam team) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _ManageTeamCard(
                                      team: team,
                                      onTap: () => _openTeam(team),
                                      onEdit: () => _openTeam(team),
                                      onDelete: () => _deleteTeam(team),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                ),
              ],
            ),
            Positioned(
              right: 23,
              bottom: 44,
              child: InkWell(
                onTap: () => setState(() => _showCreateSheet = true),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
            if (_showCreateSheet)
              _CreateTeamOverlay(
                controller: _teamNameController,
                isLoading: _isCreating,
                onCancel: () => setState(() => _showCreateSheet = false),
                onCreate: _createTeam,
              ),
          ],
        ),
      ),
    );
  }
}

class _ManageHeader extends StatelessWidget {
  const _ManageHeader();

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
          const Text(
            'My Teams',
            style: TextStyle(
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

class _ManageTeamCard extends StatelessWidget {
  const _ManageTeamCard({
    required this.team,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final SportsNeoManagedTeam team;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
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
                        '${team.playerCount} Players',
                        style: const TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB)),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFE3220D)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              team.players.isEmpty ? 'No player in this team' : 'Tap to manage players',
              style: const TextStyle(
                color: Color(0x99FFFFFF),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateTeamOverlay extends StatelessWidget {
  const _CreateTeamOverlay({
    required this.controller,
    required this.isLoading,
    required this.onCancel,
    required this.onCreate,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        alignment: Alignment.center,
        child: Container(
          width: 358,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0F1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Create New Team',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter team name',
                    hintStyle: TextStyle(color: Color(0x99FFFFFF)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0x1FFFFFFF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: isLoading ? null : onCancel,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2563EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: isLoading ? null : onCreate,
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF2563EB),
                              ),
                            )
                          : const Text(
                              'Create',
                              style: TextStyle(
                                color: Color(0xFF2563EB),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
