import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../controllers/ground_flow_controller.dart';

class ChooseSportsScreen extends StatefulWidget {
  const ChooseSportsScreen({super.key, required this.controller});

  final GroundFlowController controller;

  @override
  State<ChooseSportsScreen> createState() => _ChooseSportsScreenState();
}

class _ChooseSportsScreenState extends State<ChooseSportsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<_SportItem> _sports = <_SportItem>[
    _SportItem('Archery', '🎯'),
    _SportItem('Arm Wrestling', '💪'),
    _SportItem('Badminton', '🏸'),
    _SportItem('Baseball', '⚾'),
    _SportItem('Basketball', '🏀'),
    _SportItem('Billiards & Snooker', '🎱'),
    _SportItem('Bodybuilding', '🏋️'),
    _SportItem('Box Cricket', '🏏'),
    _SportItem('Boxing', '🥊'),
    _SportItem('Chess', '♟️'),
    _SportItem('Cricket', '🏏'),
    _SportItem('Cycling', '🚴'),
    _SportItem('Football', '⚽'),
    _SportItem('Futsal', '⚽'),
    _SportItem('Golf', '⛳'),
    _SportItem('Gymnastics', '🤸'),
    _SportItem('Hockey', '🏑'),
    _SportItem('Ice Hockey', '🏒'),
    _SportItem('Kabaddi', '🤼'),
    _SportItem('Karate', '🥋'),
    _SportItem('Kho-Kho', '🏃'),
    _SportItem('Lawn Tennis', '🎾'),
    _SportItem('Swimming', '🏊'),
    _SportItem('Table Tennis', '🏓'),
    _SportItem('Taekwondo', '🥋'),
    _SportItem('Tennis', '🎾'),
    _SportItem('Volleyball', '🏐'),
    _SportItem('Wrestling', '🤼'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String query = _searchController.text.trim().toLowerCase();
    final List<_SportItem> filtered = _sports.where((_SportItem item) {
      return query.isEmpty || item.name.toLowerCase().contains(query);
    }).toList();

    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'All Sports Events',
                    style: TextStyle(
                      color: Color(0xFF242424),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF242424),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onPressed: _showAddSportDialog,
                  child: const Text('Add Sport'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search sports',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0x19FFFFFF),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0x1F242424)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF1C333B)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: filtered.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.86,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final _SportItem sport = filtered[index];
                  final bool selected = widget.controller.data.selectedSports
                      .contains(sport.name);

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        if (selected) {
                          widget.controller.data.selectedSports.remove(
                            sport.name,
                          );
                        } else {
                          widget.controller.data.selectedSports.add(sport.name);
                        }
                      });
                      widget.controller.update();
                    },
                    child: Column(
                      children: <Widget>[
                        Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF1C333B)
                                : const Color(0x1F0D1B2A),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: selected
                                ? const <BoxShadow>[
                                    BoxShadow(
                                      color: Color(0x663B82F6),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            sport.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            sport.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF242424),
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C333B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (widget.controller.data.selectedSports.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select at least one sport'),
                      ),
                    );
                    return;
                  }
                  widget.controller.nextStep();
                },
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddSportDialog() async {
    final TextEditingController sportController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add Sport'),
          content: AppTextField(
            controller: sportController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter sport name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final String sportName = sportController.text.trim();
                if (sportName.isEmpty) {
                  return;
                }

                final bool alreadyExists = _sports.any(
                  (_SportItem sport) =>
                      sport.name.toLowerCase() == sportName.toLowerCase(),
                );
                if (!alreadyExists) {
                  setState(() {
                    _sports.insert(0, _SportItem(sportName, '🏅'));
                  });
                }
                widget.controller.data.selectedSports.add(sportName);
                widget.controller.update();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    sportController.dispose();
  }
}

class _SportItem {
  const _SportItem(this.name, this.emoji);

  final String name;
  final String emoji;
}


