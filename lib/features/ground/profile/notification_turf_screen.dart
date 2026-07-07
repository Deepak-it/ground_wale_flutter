import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'profile_turf_ui.dart';

class NotificationTurfScreen extends StatefulWidget {
  const NotificationTurfScreen({super.key});

  @override
  State<NotificationTurfScreen> createState() => _NotificationTurfScreenState();
}

class _NotificationTurfScreenState extends State<NotificationTurfScreen> {
  bool bookingAlert = true;
  bool paymentAlerts = true;
  bool reminders = false;
  bool promotionalOffers = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final ApiSession session = ApiSession.instance;
    if (!session.isAuthenticated) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final Map<String, dynamic> prefs = await GroundWaleApi.instance.getNotificationPreferences(session.ownerId!);
      setState(() {
        bookingAlert = prefs['bookingAlerts'] as bool? ?? true;
        paymentAlerts = prefs['paymentAlerts'] as bool? ?? true;
        reminders = prefs['reminders'] as bool? ?? false;
        promotionalOffers = prefs['promotionalOffers'] as bool? ?? true;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePrefs() async {
    final ApiSession session = ApiSession.instance;
    if (!session.isAuthenticated) {
      return;
    }

    await GroundWaleApi.instance.updateNotificationPreferences(
      session.ownerId!,
      <String, dynamic>{
        'bookingAlerts': bookingAlert,
        'paymentAlerts': paymentAlerts,
        'reminders': reminders,
        'promotionalOffers': promotionalOffers,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget settingRow({
      required String title,
      required String subtitle,
      required bool value,
      required ValueChanged<bool> onChanged,
      bool isTop = false,
      bool isBottom = false,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            left: const BorderSide(color: Color(0x30FFFFFF)),
            right: const BorderSide(color: Color(0x30FFFFFF)),
            top: isTop ? const BorderSide(color: Color(0x30FFFFFF)) : BorderSide.none,
            bottom: const BorderSide(color: Color(0x30FFFFFF)),
          ),
          borderRadius: BorderRadius.only(
            topLeft: isTop ? const Radius.circular(14) : Radius.zero,
            topRight: isTop ? const Radius.circular(14) : Radius.zero,
            bottomLeft: isBottom ? const Radius.circular(14) : Radius.zero,
            bottomRight: isBottom ? const Radius.circular(14) : Radius.zero,
          ),
          color: const Color(0x101C333B),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(fontSize: 15, color: Colors.white60)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: const Color(0xFFFFFFFF),
              activeTrackColor: const Color(0xFF08B36A),
              inactiveThumbColor: const Color(0xFFFFFFFF),
              inactiveTrackColor: const Color(0x80FFFFFF),
            ),
          ],
        ),
      );
    }

    return TurfPageScaffold(
      title: 'Notification Settings',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFDDF730)))
          : ListView(
        children: <Widget>[
          settingRow(
            title: 'Booking Alert',
            subtitle: 'Get Notified when someone books your ground',
            value: bookingAlert,
            onChanged: (bool value) {
              setState(() => bookingAlert = value);
              _savePrefs();
            },
            isTop: true,
          ),
          settingRow(
            title: 'Payment Alerts',
            subtitle: 'Get Notified about Payments and withdrawel',
            value: paymentAlerts,
            onChanged: (bool value) {
              setState(() => paymentAlerts = value);
              _savePrefs();
            },
          ),
          settingRow(
            title: 'Reminders',
            subtitle: 'Daily summary and upcoming bookings',
            value: reminders,
            onChanged: (bool value) {
              setState(() => reminders = value);
              _savePrefs();
            },
          ),
          settingRow(
            title: 'Promotional Offers',
            subtitle: 'Updates about new features and offers',
            value: promotionalOffers,
            onChanged: (bool value) {
              setState(() => promotionalOffers = value);
              _savePrefs();
            },
            isBottom: true,
          ),
        ],
      ),
    );
  }
}
