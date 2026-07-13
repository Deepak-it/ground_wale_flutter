import 'package:flutter/material.dart';

import '../../../../core/widgets/neon_button.dart';
import '../controllers/ground_flow_controller.dart';

class AcademyFacilitiesScreen extends StatefulWidget {
  const AcademyFacilitiesScreen({super.key, required this.controller});

  final GroundFlowController controller;

  @override
  State<AcademyFacilitiesScreen> createState() =>
      _AcademyFacilitiesScreenState();
}

class _AcademyFacilitiesScreenState extends State<AcademyFacilitiesScreen> {
  static const List<String> _allFacilities = <String>[
    'Parking',
    'Cafeteria / Food',
    'First Aid',
    'Rest Room',
    'Changing Room',
    'Dugout',
    'Lighting',
    'Wi-Fi',
    'Locker Room',
    'CCTV',
    'Water',
    'Shower',
    'Washroom',
    'Seating Area',
    'AC Hall',
    'Equipment Room',
  ];

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _visibleFacilities {
    if (_searchQuery.isEmpty) {
      return _allFacilities;
    }
    return _allFacilities
        .where(
          (String f) =>
              f.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  void _addCustomFacility(String name) {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    setState(() {
      widget.controller.data.facilities.add(trimmed);
    });
    widget.controller.update();
  }

  void _showAddFacilityDialog() {
    final TextEditingController ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1D1D1D),
          title: const Text(
            'Add Facility',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: ctrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'e.g. Swimming Pool',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFDDF730)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFDDF730)),
              ),
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                _addCustomFacility(ctrl.text);
                Navigator.of(ctx).pop();
                ctrl.dispose();
              },
              child: const Text(
                'Add',
                style: TextStyle(color: Color(0xFFDDF730)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Set<String> selected = widget.controller.data.facilities;
    final List<String> visible = _visibleFacilities;

    return Container(
      color: const Color(0xFF1D1D1D),
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              children: <Widget>[
                const Text(
                  'Academy Facilities',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Step 4 of 6',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                // Search bar
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x3DFFFFFF)),
                    color: const Color(0x0FFFFFFF),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.search,
                        color: Colors.white70,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search facilities or add more',
                            hintStyle: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (String value) {
                            setState(() => _searchQuery = value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Facility chips grid
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0x08FFFFFF),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: visible.map((String facility) {
                          final bool isSelected = selected.contains(facility);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selected.remove(facility);
                                } else {
                                  selected.add(facility);
                                }
                              });
                              widget.controller.update();
                            },
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0x3DDDF730),
                                ),
                                color: isSelected
                                    ? const Color(0x3DDDF730)
                                    : const Color(0x0F1C333B),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                facility,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Add More Facilities button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _showAddFacilityDialog,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDDF730)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Add More Facilities',
                      style: TextStyle(
                        color: Color(0xFFDDF730),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0x00050505), Color(0xFF050505)],
                stops: <double>[0, 0.4],
              ),
            ),
            child: Column(
              children: <Widget>[
                NeonButton(
                  label: 'Next',
                  onPressed: () => widget.controller.nextStep(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => widget.controller.nextStep(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDDF730)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Color(0xFFDDF730),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
