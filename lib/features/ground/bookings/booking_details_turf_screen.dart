import 'package:flutter/material.dart';

import '../../../core/api/ground_wale_api.dart';
import '../profile/profile_turf_ui.dart';

class BookingDetailsTurfScreen extends StatefulWidget {
  const BookingDetailsTurfScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<BookingDetailsTurfScreen> createState() => _BookingDetailsTurfScreenState();
}

class _BookingDetailsTurfScreenState extends State<BookingDetailsTurfScreen> {
  late Future<Map<String, dynamic>> _future = _load();
  bool _submitting = false;

  Future<Map<String, dynamic>> _load() {
    return GroundWaleApi.instance.getBookingDetails(widget.bookingId);
  }

  Future<void> _accept(Map<String, dynamic> booking) async {
    final String paymentMethod = booking['paymentMethod']?.toString() ?? 'upi';
    final String paymentStatus = booking['paymentStatus']?.toString() ?? 'pending';

    setState(() => _submitting = true);
    try {
      final Map<String, dynamic> updated = paymentMethod == 'cod' && paymentStatus == 'pending'
          ? await GroundWaleApi.instance.collectCodPayment(widget.bookingId)
          : await GroundWaleApi.instance.acceptBooking(widget.bookingId);
      setState(() {
        _future = Future<Map<String, dynamic>>.value(updated);
      });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking updated.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _reject(String reason) async {
    setState(() => _submitting = true);
    try {
      final Map<String, dynamic> updated = await GroundWaleApi.instance.rejectBooking(widget.bookingId, reason: reason);
      setState(() {
        _future = Future<Map<String, dynamic>>.value(updated);
      });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking cancelled.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'cancelled':
        return const Color(0x22E3220D);
      case 'completed':
      case 'confirmed':
        return const Color(0x22DDF730);
      default:
        return const Color(0x22F59E0B);
    }
  }

  Color _statusTextColor(String status) {
    switch (status) {
      case 'cancelled':
        return const Color(0xFFE3220D);
      case 'completed':
      case 'confirmed':
        return const Color(0xFF242424);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      case 'confirmed':
        return 'Confirmed';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return TurfPageScaffold(
      title: 'Booking Details',
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFDDF730)));
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString().replaceFirst('Exception: ', '')));
          }

          final Map<String, dynamic> booking = snapshot.data ?? <String, dynamic>{};
          final String bookingStatus = booking['bookingStatus']?.toString() ?? 'pending';
          final String paymentMethod = booking['paymentMethod']?.toString().toUpperCase() ?? 'UPI';
          final String paymentStatus = booking['paymentStatus']?.toString() ?? 'pending';
          final bool isCodPending = paymentMethod == 'COD' && paymentStatus == 'pending';

          return ListView(
            children: <Widget>[
              TurfCard(
                backgroundColor: const Color(0x14FFFFFF),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: _statusBg(bookingStatus), borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              _statusText(bookingStatus),
                              style: TextStyle(color: _statusTextColor(bookingStatus), fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${booking['startTime'] ?? '--'} - ${booking['endTime'] ?? '--'}',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle_outline_rounded, color: Color(0xFFDDF730), size: 28),
                  ],
                ),
              ),
              TurfCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Team Info', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Text(booking['teamName']?.toString() ?? '-', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text('Players: ${booking['playerCount'] ?? '-'}', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 6),
                    Text('Captain: ${booking['captainName'] ?? booking['teamName'] ?? '-'}', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 6),
                    Text('Phone: ${booking['captainPhone'] ?? '-'}', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          final String phone = booking['captainPhone']?.toString() ?? '';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(phone.isEmpty ? 'Customer phone not available.' : 'Customer: $phone')),
                          );
                        },
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0x55DDF730))),
                        child: const Text('Call Customer'),
                      ),
                    ),
                  ],
                ),
              ),
              TurfCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Payment Info', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text('Payment Method', style: TextStyle(fontSize: 17)),
                        Text(paymentMethod, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text('Payment Status', style: TextStyle(fontSize: 17)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: paymentStatus == 'paid' ? const Color(0x2234D399) : const Color(0x22F59E0B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(paymentStatus == 'paid' ? 'Done' : 'Pending'),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 26),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text('Total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                        Text('₹${booking['amount'] ?? 0}', style: const TextStyle(color: Color(0xFF08B36A), fontSize: 20, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              TurfCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Extra Note', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0x10FFFFFF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0x30FFFFFF)),
                      ),
                      child: Text(
                        booking['notes']?.toString().isNotEmpty == true ? booking['notes'].toString() : 'No extra note added.',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting ? null : () => _accept(booking),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF08B36A),
                        foregroundColor: const Color(0xFF242424),
                      ),
                      child: Text(isCodPending ? 'Accept' : 'Confirm'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting ? null : () => _reject(isCodPending ? 'COD booking cancelled by owner' : 'Refund requested by owner'),
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFD43827), side: const BorderSide(color: Color(0xFFD43827))),
                      child: Text(isCodPending ? 'Cancel' : 'Refund'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
