import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'profile_turf_ui.dart';

class FacilitySettingsTurfScreen extends StatefulWidget {
  const FacilitySettingsTurfScreen({super.key});

  @override
  State<FacilitySettingsTurfScreen> createState() => _FacilitySettingsTurfScreenState();
}

class _FacilitySettingsTurfScreenState extends State<FacilitySettingsTurfScreen> {
  bool lights = true;
  bool parking = true;
  bool water = true;
  bool washroom = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFacilities();
  }

  Future<void> _loadFacilities() async {
    final ApiSession session = ApiSession.instance;
    if (!session.hasGround && session.isAuthenticated) {
      session.setGroundId(await GroundWaleApi.instance.ensureGroundIdForOwner(session.ownerId!));
    }
    if (!session.hasGround) {
      setState(() => _isLoading = false);
      return;
    }
    final Map<String, dynamic> ground = await GroundWaleApi.instance.getGround(session.groundId!);
    final List<String> facilities = (ground['facilities'] as List<dynamic>? ?? <dynamic>[]).map((dynamic item) => item.toString()).toList();
    setState(() {
      lights = facilities.contains('Flood Lights');
      parking = facilities.contains('Parking');
      water = facilities.contains('Drinking Water');
      washroom = facilities.contains('Washroom') || facilities.contains('Rest Room');
      _isLoading = false;
    });
  }

  Future<void> _syncFacilities() async {
    final ApiSession session = ApiSession.instance;
    if (!session.hasGround) {
      return;
    }
    final List<String> facilities = <String>[
      if (lights) 'Flood Lights',
      if (parking) 'Parking',
      if (water) 'Drinking Water',
      if (washroom) 'Washroom',
    ];
    await GroundWaleApi.instance.updateFacilities(session.groundId!, facilities);
  }

  @override
  Widget build(BuildContext context) {
    Widget item(String label, bool value, ValueChanged<bool> onChanged) {
      return TurfCard(
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
            Switch(value: value, activeThumbColor: const Color(0xFFDDF730), onChanged: onChanged),
          ],
        ),
      );
    }

    return TurfPageScaffold(
      title: 'Tap on Facilitity Settings',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFDDF730)))
          : ListView(
        children: <Widget>[
          item('Flood Lights', lights, (bool v) {
            setState(() => lights = v);
            _syncFacilities();
          }),
          item('Parking', parking, (bool v) {
            setState(() => parking = v);
            _syncFacilities();
          }),
          item('Drinking Water', water, (bool v) {
            setState(() => water = v);
            _syncFacilities();
          }),
          item('Washroom', washroom, (bool v) {
            setState(() => washroom = v);
            _syncFacilities();
          }),
        ],
      ),
    );
  }
}
