import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'profile_turf_ui.dart';

class BookingHistoryTurfScreen extends StatelessWidget {
  const BookingHistoryTurfScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  Future<List<Map<String, dynamic>>> _loadBookings() async {
    final ApiSession session = ApiSession.instance;
    if (!session.hasGround && session.isAuthenticated) {
      session.setGroundId(await GroundWaleApi.instance.ensureGroundIdForOwner(session.ownerId!));
    }
    if (!session.hasGround) {
      return <Map<String, dynamic>>[];
    }
    return GroundWaleApi.instance.listBookings(session.groundId!);
  }

  @override
  Widget build(BuildContext context) {
    Widget booking(Map<String, dynamic> item) {
      final String bookingStatus = item['bookingStatus']?.toString() ?? 'confirmed';
      final Color dot = bookingStatus == 'cancelled' ? const Color(0xFFE3220D) : const Color(0xFF22C55E);
      return TurfCard(
        child: Row(
          children: <Widget>[
            Container(width: 10, height: 10, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(item['teamName']?.toString() ?? 'Team', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '${item['date']?.toString().split('T').first ?? ''} • ${item['startTime'] ?? '--'} - ${item['endTime'] ?? '--'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            Text('₹${item['amount'] ?? 0}', style: const TextStyle(color: Color(0xFF08B36A), fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return TurfPageScaffold(
      title: 'Tap on Booking History',
      showBackButton: showBackButton,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadBookings(),
        builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFDDF730)));
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString().replaceFirst('Exception: ', '')));
          }

          final List<Map<String, dynamic>> bookings = snapshot.data ?? <Map<String, dynamic>>[];
          if (bookings.isEmpty) {
            return const Center(child: Text('No bookings yet.', style: TextStyle(color: Colors.white70)));
          }

          return ListView(children: bookings.map(booking).toList());
        },
      ),
    );
  }
}
