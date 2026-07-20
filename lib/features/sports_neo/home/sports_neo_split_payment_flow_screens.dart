import 'package:flutter/material.dart';

import 'sports_neo_choose_team_screen.dart';

class SportsNeoAddedPlayer {
  const SportsNeoAddedPlayer({
    required this.name,
    required this.addedVia,
    required this.selected,
  });

  final String name;
  final String addedVia;
  final bool selected;
}

class SportsNeoAddMatchScreen extends StatelessWidget {
  const SportsNeoAddMatchScreen({
    super.key,
    required this.myTeam,
    required this.opponentTeam,
    required this.amount,
  });

  final SportsNeoTeamInfo myTeam;
  final SportsNeoTeamInfo opponentTeam;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return _SportsNeoSplitScaffold(
      title: 'Add Squad & Split Payment',
      summary: _buildTeamsSummary(myTeam, opponentTeam),
      bookingChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _primaryAction('Choose slot from your bookings'),
        ],
      ),
      showDressCode: true,
      splitLabel: 'Split Expenses Between Teams',
      amount: amount,
      myTeam: myTeam,
      opponentTeam: opponentTeam,
      sendNotificationLabel: 'Send Payment Notification',
      onSendNotification: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SportsNeoSendNotificationScreen(
              myTeam: myTeam,
              opponentTeam: opponentTeam,
              amount: amount,
            ),
          ),
        );
      },
      askPlayersFilled: false,
      initialPlayers: _manualPlayers(),
    );
  }
}

class SportsNeoSplitWithOpponentTeamScreen extends StatelessWidget {
  const SportsNeoSplitWithOpponentTeamScreen({
    super.key,
    required this.myTeam,
    required this.opponentTeam,
    required this.amount,
  });

  final SportsNeoTeamInfo myTeam;
  final SportsNeoTeamInfo opponentTeam;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return _SportsNeoSplitScaffold(
      title: 'Split Payment',
      summary: _buildTeamsSummary(myTeam, opponentTeam),
      bookingChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _bookingInfoRow(Icons.location_on_outlined, 'Green Valley Cricket Ground', 'sector 18, Mohali'),
          const SizedBox(height: 12),
          _bookingInfoRow(Icons.calendar_today_outlined, 'Wednesday, Apr 8, 2026', '6:00 AM - 8:00 AM'),
          const SizedBox(height: 12),
          _bookingInfoRow(Icons.sports_cricket_outlined, 'Cricket Match', 'Amount: ₹5000'),
          const SizedBox(height: 12),
          _primaryAction('want to change ground/slot)'),
        ],
      ),
      showDressCode: false,
      splitLabel: 'Team Split',
      amount: 1000,
      myTeam: myTeam,
      opponentTeam: opponentTeam,
      sendNotificationLabel: 'Send Payment Notification',
      onSendNotification: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SportsNeoSendNotificationScreen(
              myTeam: myTeam,
              opponentTeam: opponentTeam,
              amount: amount,
            ),
          ),
        );
      },
      askPlayersFilled: true,
      initialPlayers: _mixedPlayers(),
    );
  }
}

class SportsNeoSendNotificationScreen extends StatelessWidget {
  const SportsNeoSendNotificationScreen({
    super.key,
    required this.myTeam,
    required this.opponentTeam,
    required this.amount,
  });

  final SportsNeoTeamInfo myTeam;
  final SportsNeoTeamInfo opponentTeam;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return _SportsNeoSplitScaffold(
      title: 'Add Squad & Split Payment',
      summary: _buildTeamsSummary(myTeam, opponentTeam),
      bookingChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _bookingInfoRow(Icons.location_on_outlined, 'Green Valley Cricket Ground', 'sector 18, Mohali'),
          const SizedBox(height: 12),
          _bookingInfoRow(Icons.calendar_today_outlined, 'Wednesday, Apr 8, 2026', '6:00 AM - 8:00 AM'),
          const SizedBox(height: 12),
          _bookingInfoRow(Icons.sports_cricket_outlined, 'Cricket Match', 'Amount: ₹5000'),
          const SizedBox(height: 12),
          _teamSplitCard(myTeam, opponentTeam, 1000),
        ],
      ),
      showDressCode: false,
      splitLabel: 'Add Squad (3)',
      amount: amount,
      myTeam: myTeam,
      opponentTeam: opponentTeam,
      sendNotificationLabel: 'Send Notification',
      onSendNotification: () => _showInviteSheet(context),
      askPlayersFilled: true,
      initialPlayers: _selectedPlayers(),
      useSelectedCards: true,
    );
  }

  void _showInviteSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0A0F1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    'Send Invite Link',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(child: _inviteTile('Whatsapp', const Color(0x142563EB), Icons.chat_bubble_outline)),
                  const SizedBox(width: 12),
                  Expanded(child: _inviteTile('SMS', const Color(0x14FFFFFF), Icons.sms_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _inviteTile('Crick manage', const Color(0x142563EB), Icons.sports_cricket_outlined)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Send Notification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SportsNeoAskPlayersScreen extends StatelessWidget {
  const SportsNeoAskPlayersScreen({super.key, required this.myTeam, required this.opponentTeam, required this.amount});

  final SportsNeoTeamInfo myTeam;
  final SportsNeoTeamInfo opponentTeam;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return _SimplePlayersScreen(
      title: 'Add Squad & Split Payment',
      summary: _buildTeamsSummary(myTeam, opponentTeam),
      headerTitle: 'Add Squad (3)',
      trailingText: 'Add Player',
      filledPrimary: false,
      filledSecondary: true,
      players: _selectedPlayers(),
      primaryLabel: 'Add Manually',
      secondaryLabel: 'Ask Players',
      bottomLabel: 'Send Notification',
      onPrimaryTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SportsNeoAddManuallyScreen(
              myTeam: myTeam,
              opponentTeam: opponentTeam,
              amount: amount,
            ),
          ),
        );
      },
      onBottomTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SportsNeoSendNotificationScreen(
              myTeam: myTeam,
              opponentTeam: opponentTeam,
              amount: amount,
            ),
          ),
        );
      },
      useSelectedCards: true,
    );
  }
}

class SportsNeoAddManuallyScreen extends StatelessWidget {
  const SportsNeoAddManuallyScreen({super.key, required this.myTeam, required this.opponentTeam, required this.amount});

  final SportsNeoTeamInfo myTeam;
  final SportsNeoTeamInfo opponentTeam;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return _SimplePlayersScreen(
      title: 'Add Squad & Split Payment',
      summary: _buildTeamsSummary(myTeam, opponentTeam),
      headerTitle: 'Add Squad (3)',
      trailingText: 'Add New Player',
      filledPrimary: true,
      filledSecondary: false,
      players: _manualPlayers(),
      primaryLabel: 'Add Manually',
      secondaryLabel: 'Ask Players',
      bottomLabel: 'Add players',
      onPrimaryTap: () {},
      onBottomTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SportsNeoSendNotificationScreen(
              myTeam: myTeam,
              opponentTeam: opponentTeam,
              amount: amount,
            ),
          ),
        );
      },
      useSelectedCards: true,
    );
  }
}

class _SportsNeoSplitScaffold extends StatelessWidget {
  const _SportsNeoSplitScaffold({
    required this.title,
    required this.summary,
    required this.bookingChild,
    required this.showDressCode,
    required this.splitLabel,
    required this.amount,
    required this.myTeam,
    required this.opponentTeam,
    required this.sendNotificationLabel,
    required this.onSendNotification,
    required this.askPlayersFilled,
    required this.initialPlayers,
    this.useSelectedCards = false,
  });

  final String title;
  final Widget summary;
  final Widget bookingChild;
  final bool showDressCode;
  final String splitLabel;
  final int amount;
  final SportsNeoTeamInfo myTeam;
  final SportsNeoTeamInfo opponentTeam;
  final String sendNotificationLabel;
  final VoidCallback onSendNotification;
  final bool askPlayersFilled;
  final List<SportsNeoAddedPlayer> initialPlayers;
  final bool useSelectedCards;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _FlowHeader(title: title),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    summary,
                    const SizedBox(height: 24),
                    _outlinedCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text('Booking Details', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 16),
                          _infoBlueCard(child: bookingChild),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (showDressCode) ...<Widget>[
                      const Text('Add dress code', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      _inputLikeRow(Icons.checkroom_outlined, 'e.g. White / Color'),
                      const SizedBox(height: 12),
                    ],
                    _outlinedCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(splitLabel, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 12),
                          _teamSplitCard(myTeam, opponentTeam, amount),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: onSendNotification,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(sendNotificationLabel, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _gradientSquadSection(
                      context,
                      askPlayersFilled: askPlayersFilled,
                      players: initialPlayers,
                      useSelectedCards: useSelectedCards,
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

  Widget _gradientSquadSection(
    BuildContext context, {
    required bool askPlayersFilled,
    required List<SportsNeoAddedPlayer> players,
    required bool useSelectedCards,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: <Color>[Color(0x702563EB), Color(0x70153885)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                askPlayersFilled ? 'Add Squad (3)' : 'Add Squad',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
              ),
              if (!askPlayersFilled)
                const Text('Recent XI', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _squadActionButton(
                  'Add Manually',
                  filled: !askPlayersFilled,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SportsNeoAddManuallyScreen(
                          myTeam: myTeam,
                          opponentTeam: opponentTeam,
                          amount: amount,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _squadActionButton(
                  'Ask Players',
                  filled: askPlayersFilled,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SportsNeoAskPlayersScreen(
                          myTeam: myTeam,
                          opponentTeam: opponentTeam,
                          amount: amount,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (askPlayersFilled)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const <Widget>[
                Text('Added players (6)', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                Text('Add New Player', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 14, decoration: TextDecoration.underline)),
              ],
            ),
          if (askPlayersFilled) const SizedBox(height: 12),
          ...players.map((SportsNeoAddedPlayer player) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: useSelectedCards
                    ? _selectedPlayerTile(player)
                    : _addedPlayerTile(player),
              )),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2563EB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                askPlayersFilled ? 'Save as Draft' : 'Add players',
                style: TextStyle(color: askPlayersFilled ? const Color(0xFF2563EB) : Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (askPlayersFilled) ...<Widget>[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Submit Final Squad', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SimplePlayersScreen extends StatelessWidget {
  const _SimplePlayersScreen({
    required this.title,
    required this.summary,
    required this.headerTitle,
    required this.trailingText,
    required this.filledPrimary,
    required this.filledSecondary,
    required this.players,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.bottomLabel,
    required this.onPrimaryTap,
    required this.onBottomTap,
    required this.useSelectedCards,
  });

  final String title;
  final Widget summary;
  final String headerTitle;
  final String trailingText;
  final bool filledPrimary;
  final bool filledSecondary;
  final List<SportsNeoAddedPlayer> players;
  final String primaryLabel;
  final String secondaryLabel;
  final String bottomLabel;
  final VoidCallback onPrimaryTap;
  final VoidCallback onBottomTap;
  final bool useSelectedCards;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _FlowHeader(title: title),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    summary,
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: <Color>[Color(0x702563EB), Color(0x70153885)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(headerTitle, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                              Text(trailingText, style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 14, decoration: TextDecoration.underline)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(child: _squadActionButton(primaryLabel, filled: filledPrimary, onTap: onPrimaryTap)),
                              const SizedBox(width: 12),
                              Expanded(child: _squadActionButton(secondaryLabel, filled: filledSecondary, onTap: () {})),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...players.map((SportsNeoAddedPlayer player) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: useSelectedCards ? _selectedPlayerTile(player) : _addedPlayerTile(player),
                              )),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: onBottomTap,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(bottomLabel, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
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

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({required this.title});

  final String title;

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
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(22),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

Widget _buildTeamsSummary(SportsNeoTeamInfo myTeam, SportsNeoTeamInfo opponentTeam) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      _teamSummaryItem(myTeam),
      const Icon(Icons.sports_score_outlined, color: Color(0xFFF59E0B), size: 36),
      _teamSummaryItem(opponentTeam),
    ],
  );
}

Widget _teamSummaryItem(SportsNeoTeamInfo team) {
  return SizedBox(
    width: 111,
    child: Column(
      children: <Widget>[
        CircleAvatar(
          radius: 22,
          backgroundColor: team.color,
          child: Text(
            team.name.substring(0, 1),
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),
        Text(team.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 4),
        Text('${team.players} Players', style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 14)),
      ],
    ),
  );
}

Widget _outlinedCard({required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0x1FFFFFFF)),
    ),
    child: child,
  );
}

Widget _infoBlueCard({required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0x3D2563EB)),
      color: const Color(0x142563EB),
    ),
    child: child,
  );
}

Widget _primaryAction(String text) {
  return Container(
    width: double.infinity,
    height: 44,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: const Color(0xFF2563EB),
    ),
    alignment: Alignment.center,
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
  );
}

Widget _bookingInfoRow(IconData icon, String title, String subtitle) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Icon(icon, color: Colors.white, size: 24),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 14)),
        ],
      ),
    ],
  );
}

Widget _inputLikeRow(IconData icon, String hint) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0x1FFFFFFF)),
      color: const Color(0x142563EB),
    ),
    child: Row(
      children: <Widget>[
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 12),
        Text(hint, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 14)),
      ],
    ),
  );
}

Widget _teamSplitCard(SportsNeoTeamInfo myTeam, SportsNeoTeamInfo opponentTeam, int amount) {
  return Column(
    children: <Widget>[
      _teamAmountRow(myTeam, amount),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Icon(Icons.sports_score_outlined, color: Color(0xFFF59E0B), size: 24),
      ),
      _teamAmountRow(opponentTeam, amount),
    ],
  );
}

Widget _teamAmountRow(SportsNeoTeamInfo team, int amount) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0x1FFFFFFF)),
      color: const Color(0x142563EB),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          children: <Widget>[
            CircleAvatar(radius: 16, backgroundColor: team.color, child: Text(team.name.substring(0, 1), style: const TextStyle(color: Colors.white, fontSize: 12))),
            const SizedBox(width: 12),
            Text(team.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0x14FFFFFF),
            border: Border.all(color: const Color(0x1FFFFFFF)),
          ),
          child: Text('₹$amount', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        ),
      ],
    ),
  );
}

Widget _squadActionButton(String text, {required bool filled, required VoidCallback onTap}) {
  return SizedBox(
    height: 52,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: filled ? const Color(0xFF2563EB) : Colors.transparent,
        elevation: 0,
        side: const BorderSide(color: Color(0xFF2563EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
    ),
  );
}

Widget _addedPlayerTile(SportsNeoAddedPlayer player) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0x1FFFFFFF)),
      color: player.selected ? const Color(0x3D08B36A) : Colors.transparent,
    ),
    child: Row(
      children: <Widget>[
        const CircleAvatar(radius: 22, backgroundColor: Color(0xFF2563EB), child: Text('M', style: TextStyle(color: Colors.white))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(player.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 4),
              Text(player.addedVia, style: const TextStyle(color: Color(0xFF08B36A), fontSize: 12)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE3220D)),
          ),
          child: const Icon(Icons.close, color: Color(0xFFE3220D), size: 18),
        ),
      ],
    ),
  );
}

Widget _selectedPlayerTile(SportsNeoAddedPlayer player) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF9EFFD5)),
      color: const Color(0x3D08B36A),
    ),
    child: Row(
      children: <Widget>[
        const CircleAvatar(radius: 22, backgroundColor: Color(0xFF2563EB), child: Text('M', style: TextStyle(color: Colors.white))),
        const SizedBox(width: 12),
        Expanded(child: Text(player.name, style: const TextStyle(color: Colors.white, fontSize: 16))),
        const Icon(Icons.check_circle_outline, color: Color(0xFF08B36A), size: 24),
      ],
    ),
  );
}

Widget _inviteTile(String label, Color background, IconData icon) {
  return Container(
    height: 110,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0x3D2563EB)),
      color: background,
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, color: Colors.white, size: 36),
        const SizedBox(height: 10),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    ),
  );
}

List<SportsNeoAddedPlayer> _manualPlayers() {
  return const <SportsNeoAddedPlayer>[
    SportsNeoAddedPlayer(name: 'Manu bazidpuriya', addedVia: 'Added manually', selected: false),
    SportsNeoAddedPlayer(name: 'Rahul Singh', addedVia: 'Added manually', selected: false),
    SportsNeoAddedPlayer(name: 'Pritam Sarpanch', addedVia: 'Added manually', selected: false),
  ];
}

List<SportsNeoAddedPlayer> _selectedPlayers() {
  return const <SportsNeoAddedPlayer>[
    SportsNeoAddedPlayer(name: 'Manu bazidpuriya', addedVia: 'Added via invitation', selected: true),
    SportsNeoAddedPlayer(name: 'Rahul Singh', addedVia: 'Added via invitation', selected: true),
    SportsNeoAddedPlayer(name: 'Pritam Sarpanch', addedVia: 'Added via invitation', selected: true),
  ];
}

List<SportsNeoAddedPlayer> _mixedPlayers() {
  return const <SportsNeoAddedPlayer>[
    SportsNeoAddedPlayer(name: 'Manu bazidpuriya', addedVia: 'Added manually', selected: false),
    SportsNeoAddedPlayer(name: 'Rahul Singh', addedVia: 'Added manually', selected: false),
    SportsNeoAddedPlayer(name: 'Gagi Jassal', addedVia: 'Added via invitation', selected: false),
    SportsNeoAddedPlayer(name: 'Rajkamal', addedVia: 'Added via invitation', selected: false),
    SportsNeoAddedPlayer(name: 'Lekhi Raja', addedVia: 'Added manually', selected: false),
    SportsNeoAddedPlayer(name: 'Mandeep', addedVia: 'Added via invitation', selected: false),
  ];
}