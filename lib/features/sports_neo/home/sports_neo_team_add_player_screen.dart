import 'package:flutter/material.dart';

import '../../../core/api/ground_wale_api.dart';
import 'sports_neo_team_manage_models.dart';

class SportsNeoTeamAddPlayerScreen extends StatefulWidget {
  const SportsNeoTeamAddPlayerScreen({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  final String teamId;
  final String teamName;

  @override
  State<SportsNeoTeamAddPlayerScreen> createState() =>
      _SportsNeoTeamAddPlayerScreenState();
}

class _SportsNeoTeamAddPlayerScreenState extends State<SportsNeoTeamAddPlayerScreen> {
  final SportsNeoTeamManageRepository _repository =
      SportsNeoTeamManageRepository(GroundWaleApi.instance);

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _playerTypeController = TextEditingController();

  bool _guestMode = false;
  bool _isLoading = false;
  List<SportsNeoPlayerDirectoryItem> _directory = <SportsNeoPlayerDirectoryItem>[];
  SportsNeoPlayerDirectoryItem? _selectedPlayer;

  @override
  void initState() {
    super.initState();
    _searchDirectory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _playerTypeController.dispose();
    super.dispose();
  }

  Future<void> _searchDirectory([String query = '']) async {
    try {
      final List<SportsNeoPlayerDirectoryItem> items =
          await _repository.searchPlayers(query);
      if (!mounted) {
        return;
      }
      setState(() => _directory = items);
    } catch (_) {}
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      if (_guestMode) {
        await _repository.addGuestPlayer(
          teamId: widget.teamId,
          name: _nameController.text.trim(),
          contactNumber: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          playerType: _playerTypeController.text.trim(),
        );
      } else {
        final SportsNeoPlayerDirectoryItem? selected = _selectedPlayer;
        if (selected == null) {
          throw Exception('Please select a player');
        }
        await _repository.addAppUserPlayer(
          teamId: widget.teamId,
          userId: selected.id,
          playerType: _playerTypeController.text.trim(),
        );
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _AddPlayerHeader(teamName: '${widget.teamName} Team'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _TeamSummaryCard(teamName: widget.teamName),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0F1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Expanded(
                                child: Text(
                                  'Add Player',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => setState(() => _guestMode = !_guestMode),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF2563EB)),
                                    color: _guestMode ? const Color(0xFF2563EB) : Colors.transparent,
                                  ),
                                  child: Text(
                                    'Add Guest Player',
                                    style: TextStyle(
                                      color: _guestMode ? Colors.white : const Color(0xFF2563EB),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (!_guestMode) ...<Widget>[
                            _SearchInput(
                              controller: _searchController,
                              hintText: 'Search player by name or number',
                              onChanged: _searchDirectory,
                            ),
                            const SizedBox(height: 16),
                            ..._directory.map(
                              (SportsNeoPlayerDirectoryItem item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _DirectoryPlayerCard(
                                  item: item,
                                  selected: _selectedPlayer?.id == item.id,
                                  onTap: () => setState(() => _selectedPlayer = item),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _FormFieldCard(
                              controller: _playerTypeController,
                              hintText: 'Player Type (Optional)',
                            ),
                          ] else ...<Widget>[
                            _FormFieldCard(
                              controller: _nameController,
                              hintText: 'Player name',
                            ),
                            const SizedBox(height: 12),
                            _FormFieldCard(
                              controller: _phoneController,
                              hintText: 'Phone number',
                            ),
                            const SizedBox(height: 12),
                            _FormFieldCard(
                              controller: _emailController,
                              hintText: 'Email (Optional)',
                            ),
                            const SizedBox(height: 12),
                            _FormFieldCard(
                              controller: _playerTypeController,
                              hintText: 'Player Type',
                              trailing: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                            ),
                          ],
                          const SizedBox(height: 24),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0x1FFFFFFF)),
                                    minimumSize: const Size.fromHeight(48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: Color(0x99FFFFFF), fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF2563EB)),
                                    minimumSize: const Size.fromHeight(48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _isLoading ? null : _submit,
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                                        )
                                      : Text(
                                          _guestMode ? 'Add player' : 'Send Invite',
                                          style: const TextStyle(color: Color(0xFF2563EB), fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
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

class _AddPlayerHeader extends StatelessWidget {
  const _AddPlayerHeader({required this.teamName});

  final String teamName;

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
              teamName,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamSummaryCard extends StatelessWidget {
  const _TeamSummaryCard({required this.teamName});

  final String teamName;

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
              teamName.isEmpty ? '?' : teamName[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(teamName, style: const TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 4),
              const Text('0 Players', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchInput extends StatelessWidget {
  const _SearchInput({required this.controller, required this.hintText, required this.onChanged});

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1F242424)),
        color: Colors.white.withValues(alpha: 0.12),
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
              decoration: InputDecoration(border: InputBorder.none, hintText: hintText, hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormFieldCard extends StatelessWidget {
  const _FormFieldCard({required this.controller, required this.hintText, this.trailing});

  final TextEditingController controller;
  final String hintText;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(border: InputBorder.none, hintText: hintText, hintStyle: const TextStyle(color: Color(0x99FFFFFF), fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _DirectoryPlayerCard extends StatelessWidget {
  const _DirectoryPlayerCard({required this.item, required this.selected, required this.onTap});

  final SportsNeoPlayerDirectoryItem item;
  final bool selected;
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
          border: Border.all(color: selected ? const Color(0xFF2563EB) : const Color(0x1FFFFFFF)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF2563EB) : Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                item.name.isEmpty ? '?' : item.name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      if (item.playerType.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          child: Text(item.playerType, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        ),
                      if (item.playerType.isNotEmpty) const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.contactNumber,
                          style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}