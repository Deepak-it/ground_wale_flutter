import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../../../core/api/ground_wale_api.dart';
import 'box_cricket_booking_flow_models.dart';
import 'box_cricket_payment_screen.dart';

class BoxCricketBookingDetailsScreen extends StatefulWidget {
  const BoxCricketBookingDetailsScreen({
    super.key,
    this.bookingId,
    this.draft,
  });

  final String? bookingId;
  final BoxCricketBookingDraft? draft;

  @override
  State<BoxCricketBookingDetailsScreen> createState() =>
      _BoxCricketBookingDetailsScreenState();
}

class _BoxCricketBookingDetailsScreenState
    extends State<BoxCricketBookingDetailsScreen> {
  Future<Map<String, dynamic>>? _future;
  bool _submitting = false;

  late final TextEditingController _teamController;
  late final TextEditingController _captainController;
  late final TextEditingController _phoneController;
  late final TextEditingController _playersController;
  late final TextEditingController _noteController;

  String _paymentMethod = 'upi';

  bool get _isCreateMode => widget.bookingId == null;

  @override
  void initState() {
    super.initState();

    final BoxCricketBookingDraft draft =
        widget.draft ??
        const BoxCricketBookingDraft(
          slotId: '',
          date: '',
          startTime: '',
          endTime: '',
          amount: 0,
        );

    _teamController = TextEditingController(text: draft.teamName);
    _captainController = TextEditingController(text: draft.captainName);
    _phoneController = TextEditingController(text: draft.captainPhone);
    _playersController = TextEditingController(
      text: draft.playerCount == 0 ? '' : '${draft.playerCount}',
    );
    _noteController = TextEditingController(text: draft.notes);
    _paymentMethod = draft.paymentMethod;

    if (!_isCreateMode) {
      _future = GroundWaleApi.instance.getBookingDetails(widget.bookingId!);
    }
  }

  @override
  void dispose() {
    _teamController.dispose();
    _captainController.dispose();
    _phoneController.dispose();
    _playersController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'cancelled':
        return const Color(0x22E3220D);
      case 'completed':
      case 'confirmed':
        return const Color(0x2222C55E);
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
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'cancelled':
        return 'Rejected';
      case 'completed':
        return 'Completed';
      case 'confirmed':
        return 'Confirmed';
      default:
        return 'Pending';
    }
  }

  Future<void> _accept(Map<String, dynamic> booking) async {
    final String paymentMethod = booking['paymentMethod']?.toString() ?? 'upi';
    final String paymentStatus = booking['paymentStatus']?.toString() ?? 'pending';

    setState(() => _submitting = true);
    try {
      final Map<String, dynamic> updated =
          paymentMethod == 'cod' && paymentStatus == 'pending'
          ? await GroundWaleApi.instance.collectCodPayment(widget.bookingId!)
          : await GroundWaleApi.instance.acceptBooking(widget.bookingId!);
      setState(() {
        _future = Future<Map<String, dynamic>>.value(updated);
      });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking updated successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _reject(String reason) async {
    setState(() => _submitting = true);
    try {
      final Map<String, dynamic> updated = await GroundWaleApi.instance
          .rejectBooking(widget.bookingId!, reason: reason);
      setState(() {
        _future = Future<Map<String, dynamic>>.value(updated);
      });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  BoxCricketBookingDraft? _buildDraft() {
    if (widget.draft == null) {
      return null;
    }

    if (_teamController.text.trim().isEmpty ||
        _captainController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Team, captain and phone are required.')),
      );
      return null;
    }

    final int players = int.tryParse(_playersController.text.trim()) ?? 0;

    return widget.draft!.copyWith(
      teamName: _teamController.text.trim(),
      captainName: _captainController.text.trim(),
      captainPhone: _phoneController.text.trim(),
      playerCount: players,
      paymentMethod: _paymentMethod,
      notes: _noteController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1F1B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1F1B),
        elevation: 0,
        title: Text(_isCreateMode ? 'Booking Details' : 'Booking Details'),
      ),
      body: _isCreateMode ? _createModeBody() : _detailsModeBody(),
    );
  }

  Widget _detailsModeBody() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF08B36A)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              snapshot.error.toString().replaceFirst('Exception: ', ''),
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        final Map<String, dynamic> booking = snapshot.data ?? <String, dynamic>{};
        final String bookingStatus = booking['bookingStatus']?.toString() ?? 'pending';
        final String paymentMethod =
            booking['paymentMethod']?.toString().toUpperCase() ?? 'UPI';
        final String paymentStatus = booking['paymentStatus']?.toString() ?? 'pending';
        final bool isCodPending =
            paymentMethod == 'COD' && paymentStatus == 'pending';

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDeco(),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _statusBg(bookingStatus),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusText(bookingStatus),
                            style: TextStyle(
                              color: _statusTextColor(bookingStatus),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${booking['startTime'] ?? '--'} - ${booking['endTime'] ?? '--'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking['bookingCode']?.toString() ?? '',
                          style: const TextStyle(color: Color(0x99FFFFFF)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF08B36A),
                    size: 28,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _teamInfoCard(booking),
            const SizedBox(height: 12),
            _paymentInfoCard(
              paymentMethod,
              paymentStatus,
              (booking['amount'] as num?)?.round() ?? 0,
            ),
            const SizedBox(height: 12),
            _extraNoteCard(booking['notes']?.toString() ?? ''),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting ? null : () => _accept(booking),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF08B36A),
                      foregroundColor: const Color(0xFF1C333B),
                    ),
                    child: Text(isCodPending ? 'Accept' : 'Confirm Booking'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => _reject(
                            isCodPending
                                ? 'COD booking cancelled by owner'
                                : 'Refund requested by owner',
                          ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD43827)),
                      foregroundColor: const Color(0xFFD43827),
                    ),
                    child: Text(isCodPending ? 'Cancel' : 'Refund'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _createModeBody() {
    final BoxCricketBookingDraft draft = widget.draft!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDeco(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Slot Info',
                style: TextStyle(
                  color: Color(0x99FFFFFF),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${draft.startTime} - ${draft.endTime}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Total: Rs ${draft.amount}',
                style: const TextStyle(
                  color: Color(0xFF08B36A),
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _formCard(
          title: 'Team Info',
          children: <Widget>[
            _input(_teamController, 'Team Name'),
            const SizedBox(height: 10),
            _input(_captainController, 'Captain Name'),
            const SizedBox(height: 10),
            _input(
              _phoneController,
              'Captain Phone',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            _input(
              _playersController,
              'Players Count',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _formCard(
          title: 'Payment Info',
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <String>['upi', 'cod', 'cash', 'netbanking'].map((String method) {
                final bool selected = _paymentMethod == method;
                return GestureDetector(
                  onTap: () => setState(() => _paymentMethod = method),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: selected
                          ? const Color(0xFF08B36A)
                          : const Color(0x0DFFFFFF),
                      border: Border.all(color: const Color(0x1FFFFFFF)),
                    ),
                    child: Text(
                      method.toUpperCase(),
                      style: TextStyle(
                        color: selected ? const Color(0xFF1C333B) : Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _formCard(
          title: 'Extra Note',
          children: <Widget>[
            _input(
              _noteController,
              'Any message for player',
              maxLines: 4,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0x1FFFFFFF)),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final BoxCricketBookingDraft? ready = _buildDraft();
                  if (ready == null) {
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BoxCricketPaymentScreen(draft: ready),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF08B36A),
                  foregroundColor: const Color(0xFF1C333B),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _teamInfoCard(Map<String, dynamic> booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Team Info',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            booking['teamName']?.toString() ?? '-',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Players: ${booking['playerCount'] ?? '-'}',
            style: const TextStyle(color: Color(0xCCFFFFFF)),
          ),
          const SizedBox(height: 4),
          Text(
            'Captain: ${booking['captainName'] ?? booking['teamName'] ?? '-'}',
            style: const TextStyle(color: Color(0xCCFFFFFF)),
          ),
          const SizedBox(height: 4),
          Text(
            'Phone: ${booking['captainPhone'] ?? '-'}',
            style: const TextStyle(color: Color(0xCCFFFFFF)),
          ),
        ],
      ),
    );
  }

  Widget _paymentInfoCard(String method, String status, int amount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Payment Info',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text('Payment Method', style: TextStyle(color: Color(0xCCFFFFFF))),
              Text(method, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text('Payment Status', style: TextStyle(color: Color(0xCCFFFFFF))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  color: status == 'paid'
                      ? const Color(0x2234D399)
                      : const Color(0x22F59E0B),
                ),
                child: Text(
                  status == 'paid' ? 'Done' : 'Pending',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const Divider(color: Color(0x33FFFFFF), height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                'Total',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Text(
                'Rs $amount',
                style: const TextStyle(
                  color: Color(0xFF08B36A),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _extraNoteCard(String notes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Extra Note',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0x10FFFFFF),
              border: Border.all(color: const Color(0x25FFFFFF)),
            ),
            child: Text(
              notes.isEmpty ? 'No extra note added.' : notes,
              style: const TextStyle(color: Color(0xCCFFFFFF)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return AppTextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0x66FFFFFF)),
        filled: true,
        fillColor: const Color(0x10FFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF08B36A)),
        ),
      ),
    );
  }

  BoxDecoration _cardDeco() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: const Color(0x0AFFFFFF),
      border: Border.all(color: const Color(0x1FFFFFFF)),
    );
  }
}


