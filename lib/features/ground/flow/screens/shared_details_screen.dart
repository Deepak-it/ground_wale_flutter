import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/utils/location_service.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/labeled_text_field.dart';
import '../../../../core/widgets/neon_button.dart';
import '../controllers/ground_flow_controller.dart';
import '../models/ground_registration_data.dart';

// Sports list reused from academy batch setup
const List<Map<String, String>> _kGroundSports = <Map<String, String>>[
  <String, String>{'emoji': '🎯', 'name': 'Archery'},
  <String, String>{'emoji': '💪', 'name': 'Arm Wrestling'},
  <String, String>{'emoji': '🏸', 'name': 'Badminton'},
  <String, String>{'emoji': '⚾', 'name': 'Baseball'},
  <String, String>{'emoji': '🏀', 'name': 'Basketball'},
  <String, String>{'emoji': '🎱', 'name': 'Billiards'},
  <String, String>{'emoji': '🏋️', 'name': 'Bodybuilding'},
  <String, String>{'emoji': '🏏', 'name': 'Box Cricket'},
  <String, String>{'emoji': '🥊', 'name': 'Boxing'},
  <String, String>{'emoji': '♟️', 'name': 'Chess'},
  <String, String>{'emoji': '🏏', 'name': 'Cricket'},
  <String, String>{'emoji': '🚴', 'name': 'Cycling'},
  <String, String>{'emoji': '🤺', 'name': 'Fencing'},
  <String, String>{'emoji': '⚽', 'name': 'Football'},
  <String, String>{'emoji': '⚽', 'name': 'Futsal'},
  <String, String>{'emoji': '⛳', 'name': 'Golf'},
  <String, String>{'emoji': '🤸', 'name': 'Gymnastics'},
  <String, String>{'emoji': '🤾', 'name': 'Handball'},
  <String, String>{'emoji': '🏑', 'name': 'Hockey'},
  <String, String>{'emoji': '🏒', 'name': 'Ice Hockey'},
  <String, String>{'emoji': '🥋', 'name': 'Judo'},
  <String, String>{'emoji': '🤼', 'name': 'Kabaddi'},
  <String, String>{'emoji': '🥋', 'name': 'Karate'},
  <String, String>{'emoji': '🏃', 'name': 'Kho-Kho'},
  <String, String>{'emoji': '🎾', 'name': 'Lawn Tennis'},
  <String, String>{'emoji': '🤸', 'name': 'Mallakhamb'},
  <String, String>{'emoji': '🏎️', 'name': 'Motor Sports'},
  <String, String>{'emoji': '🏀', 'name': 'Netball'},
  <String, String>{'emoji': '🚣', 'name': 'Rowing'},
  <String, String>{'emoji': '🏉', 'name': 'Rugby'},
  <String, String>{'emoji': '🎯', 'name': 'Shooting'},
  <String, String>{'emoji': '🎾', 'name': 'Squash'},
  <String, String>{'emoji': '🏊', 'name': 'Swimming'},
  <String, String>{'emoji': '🏓', 'name': 'Table Tennis'},
  <String, String>{'emoji': '🥋', 'name': 'Taekwondo'},
  <String, String>{'emoji': '🎾', 'name': 'Tennis'},
  <String, String>{'emoji': '🏐', 'name': 'Volleyball'},
  <String, String>{'emoji': '🤼', 'name': 'Wrestling'},
  <String, String>{'emoji': '⛵', 'name': 'Yachting'},
];

class SharedDetailsScreen extends StatefulWidget {
  const SharedDetailsScreen({super.key, required this.controller});

  final GroundFlowController controller;

  @override
  State<SharedDetailsScreen> createState() => _SharedDetailsScreenState();
}

class _SharedDetailsScreenState extends State<SharedDetailsScreen> {
  late final TextEditingController _groundNameController;
  late final TextEditingController _stateController;
  late final TextEditingController _cityController;
  late final TextEditingController _areaController;
  late final TextEditingController _addressController;
  late final TextEditingController _pinCodeController;
  late final TextEditingController _landmarkController;

  bool _locationFetched = false;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    _groundNameController = TextEditingController(
      text: widget.controller.data.groundName == 'Alexa Ground'
          ? ''
          : widget.controller.data.groundName,
    );
    _stateController = TextEditingController(
      text: widget.controller.data.state,
    );
    _cityController = TextEditingController(text: widget.controller.data.city);
    _areaController = TextEditingController(
      text: widget.controller.data.areaLocation,
    );
    _addressController = TextEditingController(
      text: widget.controller.data.address,
    );
    _pinCodeController = TextEditingController(
      text: widget.controller.data.pinCode,
    );
    _landmarkController = TextEditingController(
      text: widget.controller.data.landmark,
    );
  }

  // ── Location fetch ─────────────────────────────────────────
  Future<void> _fetchLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      final LocationResult result = await LocationService.fetchCurrentLocation();
      setState(() {
        _cityController.text = result.city;
        _stateController.text = result.state;
        // Lock fields only when geocoding actually found city/state.
        // If geocodingSucceeded is false, GPS coordinates were saved but
        // city/state are empty → leave fields editable for manual entry.
        _locationFetched = result.geocodingSucceeded;
      });
      _sync();
      if (!mounted) return;
      if (!result.geocodingSucceeded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'GPS location found. Please enter city/state manually.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } on LocationServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Could not fetch location'),
          action: e.error == LocationError.permissionDeniedForever
              ? SnackBarAction(
                  label: 'Settings',
                  onPressed: Geolocator.openAppSettings,
                )
              : null,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  // ── Sports sheet ─────────────────────────────────────────
  Future<void> _openSportsSheet() async {
    final Set<String> tempSelected =
        Set<String>.from(widget.controller.data.selectedSports);
    final TextEditingController searchCtrl = TextEditingController();
    String query = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter sheetSet) {
            final List<Map<String, String>> visible = query.isEmpty
                ? _kGroundSports
                : _kGroundSports
                      .where(
                        (Map<String, String> s) =>
                            s['name']!.toLowerCase().contains(
                              query.toLowerCase(),
                            ),
                      )
                      .toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.88,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (BuildContext _, ScrollController sc) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text(
                            'All Sports Events',
                            style: TextStyle(
                              color: Color(0xFF242424),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final TextEditingController ctrl =
                                  TextEditingController();
                              final String? custom =
                                  await showDialog<String>(
                                    context: ctx,
                                    builder: (BuildContext dlg) => AlertDialog(
                                      title: const Text('Add Sport'),
                                      content: TextField(
                                        controller: ctrl,
                                        autofocus: true,
                                        decoration: const InputDecoration(
                                          hintText: 'e.g. Martial Arts',
                                        ),
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(dlg).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(
                                            dlg,
                                          ).pop(ctrl.text.trim()),
                                          child: const Text('Add'),
                                        ),
                                      ],
                                    ),
                                  );
                              ctrl.dispose();
                              if (custom != null && custom.isNotEmpty) {
                                sheetSet(() => tempSelected.add(custom));
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: const Color(0xFF242424),
                              ),
                              child: const Text(
                                'Add Sport',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 48,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0x1F242424),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.search,
                              color: Color(0xFF9CA3AF),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: searchCtrl,
                                style: const TextStyle(
                                  color: Color(0xFF242424),
                                  fontSize: 14,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Search sports',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onChanged: (String v) =>
                                    sheetSet(() => query = v),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GridView.builder(
                          controller: sc,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 20,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.78,
                              ),
                          itemCount: visible.length,
                          itemBuilder: (BuildContext _, int i) {
                            final String name = visible[i]['name']!;
                            final String emoji = visible[i]['emoji']!;
                            final bool sel = tempSelected.contains(name);
                            return GestureDetector(
                              onTap: () => sheetSet(() {
                                if (sel) {
                                  tempSelected.remove(name);
                                } else {
                                  tempSelected.add(name);
                                }
                              }),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Container(
                                    width: 56,
                                    height: 56,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: sel
                                          ? const Color(0xFF1C333B)
                                          : const Color(0x1F0D1B2A),
                                      boxShadow: sel
                                          ? const <BoxShadow>[
                                              BoxShadow(
                                                color: Color(0x663B82F6),
                                                blurRadius: 12,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: const Color(0xFF242424),
                                      fontSize: 12,
                                      fontWeight: sel
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1C333B),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    searchCtrl.dispose();
    setState(() {
      widget.controller.data.selectedSports
        ..clear()
        ..addAll(tempSelected);
    });
    _sync();
  }

  @override
  void dispose() {
    _groundNameController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _addressController.dispose();
    _pinCodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  void _sync() {
    if (!widget.controller.isAcademyFlow) {
      final String name = _groundNameController.text.trim();
      if (name.isNotEmpty) widget.controller.data.groundName = name;
    }
    widget.controller.data.state = _stateController.text.trim();
    widget.controller.data.city = _cityController.text.trim();
    widget.controller.data.areaLocation = _areaController.text.trim();
    widget.controller.data.address = _addressController.text.trim();
    widget.controller.data.pinCode = _pinCodeController.text.trim();
    widget.controller.data.landmark = _landmarkController.text.trim();
    widget.controller.update();
  }

  @override
  Widget build(BuildContext context) {
    final OfferType? offerType = widget.controller.data.offerType;
    final bool academy = offerType == OfferType.academyCoaching;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            academy ? 'Academy Details' : 'Ground Details',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text('Step 2 of 5', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          // ── Ground-only fields ─────────────────────────────────
          if (!academy) ...<Widget>[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  LabeledTextField(
                    label: 'Ground / Stadium Name',
                    controller: _groundNameController,
                    hint: 'e.g. Highland Arena',
                    onChanged: (_) => _sync(),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Choose Sports',
                    style: TextStyle(
                      color: Color(0xCCFFFFFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _openSportsSheet,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0x1FFFFFFF)),
                        color: const Color(0x0FFFFFFF),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              widget.controller.data.selectedSports.isEmpty
                                  ? 'Select sports'
                                  : widget.controller.data.selectedSports
                                        .join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: widget.controller.data.selectedSports
                                        .isEmpty
                                    ? Colors.white54
                                    : Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          // ── Shared location fields ──────────────────────────────
          GlassCard(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _locationFetched
                            ? 'Location detected'
                            : 'Detect your location',
                        style: TextStyle(
                          color: _locationFetched
                              ? const Color(0xFF4ADE80)
                              : Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _isFetchingLocation ? null : _fetchLocation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFF1C333B),
                          border: Border.all(
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                        child: _isFetchingLocation
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    Icons.my_location,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Use Location',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LabeledTextField(
                  label: 'State',
                  controller: _stateController,
                  hint: 'Select State',
                  readOnly: _locationFetched,
                  onChanged: _locationFetched ? null : (_) => _sync(),
                ),
                const SizedBox(height: 14),
                LabeledTextField(
                  label: 'City',
                  controller: _cityController,
                  hint: 'Select City',
                  readOnly: _locationFetched,
                  onChanged: _locationFetched ? null : (_) => _sync(),
                ),
                const SizedBox(height: 14),
                LabeledTextField(
                  label: 'Area / Location',
                  controller: _areaController,
                  hint: 'Area / Location',
                  onChanged: (_) => _sync(),
                ),
                const SizedBox(height: 14),
                LabeledTextField(
                  label: 'Full Address',
                  controller: _addressController,
                  hint: 'Enter full address',
                  onChanged: (_) => _sync(),
                ),
                const SizedBox(height: 14),
                LabeledTextField(
                  label: 'Pin Code',
                  controller: _pinCodeController,
                  keyboardType: TextInputType.number,
                  hint: 'Enter pin code',
                  onChanged: (_) => _sync(),
                ),
                const SizedBox(height: 14),
                LabeledTextField(
                  label: 'Landmark',
                  controller: _landmarkController,
                  hint: 'Enter your landmark',
                  onChanged: (_) => _sync(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          NeonButton(
            label: 'Next',
            onPressed: () {
              _sync();
              if (widget.controller.data.state.isEmpty ||
                  widget.controller.data.city.isEmpty ||
                  widget.controller.data.address.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill state, city and address'),
                  ),
                );
                return;
              }
              widget.controller.nextStep();
            },
          ),
        ],
      ),
    );
  }
}
