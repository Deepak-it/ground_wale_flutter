import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'edit_slot_turf_screen.dart';
import 'profile_turf_ui.dart';

class PricingSlotTurfScreen extends StatefulWidget {
  const PricingSlotTurfScreen({super.key});

  @override
  State<PricingSlotTurfScreen> createState() => _PricingSlotTurfScreenState();
}

class _PricingSlotTurfScreenState extends State<PricingSlotTurfScreen> {
  late Future<List<Map<String, dynamic>>> _future = _loadSlots();

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

  void _refresh() {
    setState(() => _future = _loadSlots());
  }

  @override
  Widget build(BuildContext context) {
    Widget item(Map<String, dynamic> slot) {
      return TurfCard(
        child: Row(
          children: <Widget>[
            Expanded(child: Text('${slot['startTime']} - ${slot['endTime']}', style: const TextStyle(fontWeight: FontWeight.w600))),
            Text('₹${slot['price']}', style: const TextStyle(color: Color(0xFF08B36A), fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            IconButton(
              onPressed: () async {
                final bool? didUpdate = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(builder: (_) => EditSlotTurfScreen(slot: slot)),
                );
                if (didUpdate == true) {
                  _refresh();
                }
              },
              icon: const Icon(Icons.edit_outlined, color: Color(0xFFDDF730)),
            ),
          ],
        ),
      );
    }

    return TurfPageScaffold(
      title: 'Tap on Pricing & Slot',
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFDDF730)));
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString().replaceFirst('Exception: ', '')));
          }

          final List<Map<String, dynamic>> slots = snapshot.data ?? <Map<String, dynamic>>[];
          if (slots.isEmpty) {
            return const Center(child: Text('No slots available to price yet.'));
          }

          return ListView(children: slots.map(item).toList());
        },
      ),
    );
  }
}
