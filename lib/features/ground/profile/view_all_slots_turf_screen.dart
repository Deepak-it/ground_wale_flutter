import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'block_slot_turf_screen.dart';
import 'delete_slot_turf_screen.dart';
import 'edit_slot_turf_screen.dart';
import 'profile_turf_ui.dart';

class ViewAllSlotsTurfScreen extends StatelessWidget {
  const ViewAllSlotsTurfScreen({super.key});

  Future<List<Map<String, dynamic>>> _loadSlots() async {
    final ApiSession session = ApiSession.instance;
    if (!session.hasGround && session.isAuthenticated) {
      session.setGroundId(await GroundWaleApi.instance.ensureGroundIdForOwner(session.ownerId!));
    }
    if (!session.hasGround) {
      return <Map<String, dynamic>>[];
    }
    return GroundWaleApi.instance.listSlots(session.groundId!);
  }

  @override
  Widget build(BuildContext context) {
    Widget slot(Map<String, dynamic> item) {
      final String status = item['status']?.toString() ?? 'available';
      final Color color = status == 'booked' ? const Color(0xFFE3220D) : const Color(0xFF22C55E);
      return TurfCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text('${item['startTime']} - ${item['endTime']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
                Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EditSlotTurfScreen(slot: item))),
                    child: const Text('Tap on Edit Slot'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DeleteSlotTurfScreen(slotId: item['_id']?.toString() ?? ''))),
                    child: const Text('Tap on Delete'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => BlockSlotTurfScreen(slotId: item['_id']?.toString() ?? ''))),
                    child: const Text('Tap on Block Button'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return TurfPageScaffold(
      title: 'Tap on View All 3 slots',
      subtitle: 'Monday, 24 Feb - expanded list state',
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadSlots(),
        builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          final List<Map<String, dynamic>> items = snapshot.data ?? <Map<String, dynamic>>[];
          return ListView(children: items.map(slot).toList());
        },
      ),
    );
  }
}
