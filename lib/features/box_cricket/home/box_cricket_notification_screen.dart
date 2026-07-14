import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';

class BoxCricketNotificationScreen extends StatefulWidget {
  const BoxCricketNotificationScreen({super.key});

  @override
  State<BoxCricketNotificationScreen> createState() =>
      _BoxCricketNotificationScreenState();
}

class _BoxCricketNotificationScreenState
    extends State<BoxCricketNotificationScreen> {
  bool _newBookingAlerts = true;
  bool _bookingCancellationAlerts = true;
  bool _paymentReceivedAlerts = true;
  bool _withdrawalUpdates = true;
  bool _slotReminders = false;
  bool _dailySummary = false;
  bool _promotionalOffers = true;
  bool _productUpdates = true;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final Map<String, dynamic> prefs = await GroundWaleApi.instance
          .getNotificationPreferences(ownerId);
      if (!mounted) {
        return;
      }

      final bool bookingRoot = prefs['bookingAlerts'] as bool? ?? true;
      final bool paymentRoot = prefs['paymentAlerts'] as bool? ?? true;
      final bool reminderRoot = prefs['reminders'] as bool? ?? false;
      final bool promoRoot = prefs['promotionalOffers'] as bool? ?? true;

      setState(() {
        _newBookingAlerts =
            prefs['newBookingAlerts'] as bool? ??
            prefs['bookingRequestAlerts'] as bool? ??
            bookingRoot;
        _bookingCancellationAlerts =
            prefs['bookingCancellationAlerts'] as bool? ??
            prefs['cancellationAlerts'] as bool? ??
            bookingRoot;

        _paymentReceivedAlerts =
            prefs['paymentReceivedAlerts'] as bool? ??
            prefs['paymentCredits'] as bool? ??
            paymentRoot;
        _withdrawalUpdates =
            prefs['withdrawalUpdates'] as bool? ??
            prefs['payoutUpdates'] as bool? ??
            paymentRoot;

        _slotReminders =
            prefs['slotReminders'] as bool? ??
            prefs['bookingReminders'] as bool? ??
            reminderRoot;
        _dailySummary =
            prefs['dailySummary'] as bool? ??
            prefs['summaryAlerts'] as bool? ??
            reminderRoot;

        _promotionalOffers = promoRoot;
        _productUpdates = prefs['productUpdates'] as bool? ?? promoRoot;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);

    final bool bookingAlerts = _newBookingAlerts || _bookingCancellationAlerts;
    final bool paymentAlerts = _paymentReceivedAlerts || _withdrawalUpdates;
    final bool reminders = _slotReminders || _dailySummary;
    final bool promotionalOffers = _promotionalOffers || _productUpdates;

    try {
      await GroundWaleApi.instance
          .updateNotificationPreferences(ownerId, <String, dynamic>{
            'bookingAlerts': bookingAlerts,
            'paymentAlerts': paymentAlerts,
            'reminders': reminders,
            'promotionalOffers': promotionalOffers,

            'newBookingAlerts': _newBookingAlerts,
            'bookingCancellationAlerts': _bookingCancellationAlerts,
            'paymentReceivedAlerts': _paymentReceivedAlerts,
            'withdrawalUpdates': _withdrawalUpdates,
            'slotReminders': _slotReminders,
            'dailySummary': _dailySummary,
            'productUpdates': _productUpdates,
          });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification settings updated.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1F1B),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF08B36A)),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFFDDF730),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Tap on Notification',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Bookings'),
                  _row(
                    roundedTop: true,
                    title: 'New Booking Requests',
                    subtitle: 'When a player requests a slot booking',
                    value: _newBookingAlerts,
                    onChanged: (bool value) {
                      setState(() => _newBookingAlerts = value);
                    },
                  ),
                  _row(
                    roundedBottom: true,
                    showDivider: false,
                    title: 'Booking Cancellations',
                    subtitle: 'When a confirmed booking gets cancelled',
                    value: _bookingCancellationAlerts,
                    onChanged: (bool value) {
                      setState(() => _bookingCancellationAlerts = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  _sectionTitle('Payments & Payouts'),
                  _row(
                    roundedTop: true,
                    title: 'Payment Received',
                    subtitle: 'When a slot payment is credited',
                    value: _paymentReceivedAlerts,
                    onChanged: (bool value) {
                      setState(() => _paymentReceivedAlerts = value);
                    },
                  ),
                  _row(
                    roundedBottom: true,
                    showDivider: false,
                    title: 'Withdrawal Updates',
                    subtitle: 'Status updates on your payout requests',
                    value: _withdrawalUpdates,
                    onChanged: (bool value) {
                      setState(() => _withdrawalUpdates = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  _sectionTitle('Reminders'),
                  _row(
                    roundedTop: true,
                    title: 'Upcoming Slot Reminders',
                    subtitle: 'Get reminded before booked slot times',
                    value: _slotReminders,
                    onChanged: (bool value) {
                      setState(() => _slotReminders = value);
                    },
                  ),
                  _row(
                    roundedBottom: true,
                    showDivider: false,
                    title: 'Daily Summary',
                    subtitle: 'Receive end-of-day activity summary',
                    value: _dailySummary,
                    onChanged: (bool value) {
                      setState(() => _dailySummary = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  _sectionTitle('Marketing'),
                  _row(
                    roundedTop: true,
                    title: 'Promotional Offers',
                    subtitle: 'Special campaigns and limited deals',
                    value: _promotionalOffers,
                    onChanged: (bool value) {
                      setState(() => _promotionalOffers = value);
                    },
                  ),
                  _row(
                    roundedBottom: true,
                    showDivider: false,
                    title: 'Product Updates',
                    subtitle: 'Announcements about new features',
                    value: _productUpdates,
                    onChanged: (bool value) {
                      setState(() => _productUpdates = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF08B36A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Notification Settings',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: null,
    );
  }

  Widget _row({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool roundedTop = false,
    bool roundedBottom = false,
    bool showDivider = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x0F1C333B),
        border: Border(
          left: const BorderSide(color: Color(0x1FFFFFFF)),
          right: const BorderSide(color: Color(0x1FFFFFFF)),
          top: roundedTop
              ? const BorderSide(color: Color(0x1FFFFFFF))
              : BorderSide.none,
          bottom: showDivider
              ? const BorderSide(color: Color(0x1FFFFFFF))
              : const BorderSide(color: Color(0x1FFFFFFF)),
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(roundedTop ? 12 : 0),
          topRight: Radius.circular(roundedTop ? 12 : 0),
          bottomLeft: Radius.circular(roundedBottom ? 12 : 0),
          bottomRight: Radius.circular(roundedBottom ? 12 : 0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF08B36A),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0x80FFFFFF),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
