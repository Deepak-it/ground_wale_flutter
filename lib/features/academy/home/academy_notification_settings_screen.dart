import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';

class AcademyNotificationSettingsScreen extends StatefulWidget {
  const AcademyNotificationSettingsScreen({super.key});

  @override
  State<AcademyNotificationSettingsScreen> createState() =>
      _AcademyNotificationSettingsScreenState();
}

class _AcademyNotificationSettingsScreenState
    extends State<AcademyNotificationSettingsScreen> {
  bool _attendanceNotifications = true;
  bool _feeReminders = true;
  bool _newStudentAlerts = false;
  bool _paymentReceived = true;
  bool _isLoading = true;

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
      setState(() {
        _attendanceNotifications = prefs['bookingAlerts'] == true;
        _feeReminders = prefs['reminders'] == true;
        _newStudentAlerts = prefs['promotionalOffers'] == true;
        _paymentReceived = prefs['paymentAlerts'] == true;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _save() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      return;
    }
    try {
      await GroundWaleApi.instance
          .updateNotificationPreferences(ownerId, <String, dynamic>{
            'bookingAlerts': _attendanceNotifications,
            'reminders': _feeReminders,
            'promotionalOffers': _newStudentAlerts,
            'paymentAlerts': _paymentReceived,
          });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00C9A7),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              SizedBox(
                                width: 44,
                                height: 44,
                                child: IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Notification Settings',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0x0F1C333B),
                              border: Border.all(
                                color: const Color(0x1FFFFFFF),
                              ),
                            ),
                            child: Column(
                              children: <Widget>[
                                _NotificationTile(
                                  title: 'Attendance Notification',
                                  subtitle:
                                      'Parents get notified when attendance marked.',
                                  value: _attendanceNotifications,
                                  roundedTop: true,
                                  onChanged: (bool value) {
                                    setState(
                                      () => _attendanceNotifications = value,
                                    );
                                    _save();
                                  },
                                ),
                                _NotificationTile(
                                  title: 'Fee Reminders',
                                  subtitle:
                                      'Alerts for upcoming and overdue fee payments',
                                  value: _feeReminders,
                                  onChanged: (bool value) {
                                    setState(() => _feeReminders = value);
                                    _save();
                                  },
                                ),
                                _NotificationTile(
                                  title: 'New Student Alerts',
                                  subtitle:
                                      'Notification when a new student enrolis',
                                  value: _newStudentAlerts,
                                  onChanged: (bool value) {
                                    setState(() => _newStudentAlerts = value);
                                    _save();
                                  },
                                ),
                                _NotificationTile(
                                  title: 'Payment Received',
                                  subtitle:
                                      'Get notified when payments are received',
                                  value: _paymentReceived,
                                  roundedBottom: true,
                                  showDivider: false,
                                  onChanged: (bool value) {
                                    setState(() => _paymentReceived = value);
                                    _save();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: null,
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.roundedTop = false,
    this.roundedBottom = false,
    this.showDivider = true,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool roundedTop;
  final bool roundedBottom;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(roundedTop ? 12 : 0),
          topRight: Radius.circular(roundedTop ? 12 : 0),
          bottomLeft: Radius.circular(roundedBottom ? 12 : 0),
          bottomRight: Radius.circular(roundedBottom ? 12 : 0),
        ),
        border: showDivider
            ? const Border(bottom: BorderSide(color: Color(0x1FFFFFFF)))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF08B36A),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0x80FFFFFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
