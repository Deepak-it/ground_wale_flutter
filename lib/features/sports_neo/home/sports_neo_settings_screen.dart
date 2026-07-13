import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'sports_neo_onboarding_flow.dart';

class SportsNeoSettingsScreen extends StatefulWidget {
  const SportsNeoSettingsScreen({super.key});

  @override
  State<SportsNeoSettingsScreen> createState() => _SportsNeoSettingsScreenState();
}

class _SportsNeoSettingsScreenState extends State<SportsNeoSettingsScreen> {
  final GroundWaleApi _api = GroundWaleApi.instance;

  bool _isLoading = true;
  bool _isSaving = false;

  bool _pushNotification = true;
  bool _matchNotification = true;
  bool _bookingUpdates = true;
  bool _paymentAlerts = true;
  bool _teamInvites = true;
  bool _defaultLocation = true;

  String _locationLabel = 'device_location';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
        _api.getNotificationPreferences(ownerId),
        _api.getOwnerProfile(ownerId),
      ]);
      final Map<String, dynamic> prefs = Map<String, dynamic>.from(results[0] as Map);
      final Map<String, dynamic> profile = Map<String, dynamic>.from(results[1] as Map);

      if (!mounted) {
        return;
      }

      setState(() {
        _matchNotification = prefs['bookingAlerts'] != false;
        _bookingUpdates = prefs['reminders'] == true;
        _paymentAlerts = prefs['paymentAlerts'] != false;
        _teamInvites = prefs['promotionalOffers'] != false;
        _pushNotification =
            _matchNotification || _bookingUpdates || _paymentAlerts || _teamInvites;
        final String location =
            profile['mapLocation']?.toString().trim().isNotEmpty == true
            ? profile['mapLocation'].toString().trim()
            : 'device_location';
        _locationLabel = location;
        _defaultLocation = location == 'device_location';
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNotificationPreferences() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _api.updateNotificationPreferences(ownerId, <String, dynamic>{
        'bookingAlerts': _matchNotification,
        'reminders': _bookingUpdates,
        'paymentAlerts': _paymentAlerts,
        'promotionalOffers': _teamInvites,
      });
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

  Future<void> _updateLocation(String value) async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _api.updateOwnerProfile(ownerId, <String, dynamic>{
        'mapLocation': value,
      });
      if (!mounted) {
        return;
      }
      setState(() {
        _locationLabel = value;
        _defaultLocation = value == 'device_location';
      });
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

  Future<void> _changeAddress() async {
    final TextEditingController controller = TextEditingController(
      text: _locationLabel == 'device_location' ? '' : _locationLabel,
    );

    final String? value = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF121C3E),
          title: const Text('Change Address', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter address',
              hintStyle: TextStyle(color: Color(0x99FFFFFF)),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (value == null || value.isEmpty) {
      return;
    }
    await _updateLocation(value);
  }

  Future<void> _logout() async {
    setState(() => _isSaving = true);
    try {
      await _api.logout();
    } catch (_) {
      // Clear session even if server logout fails.
    }

    ApiSession.instance.clear();
    if (!mounted) {
      return;
    }
    setState(() => _isSaving = false);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const SportsNeoWelcomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _togglePushNotification(bool value) {
    setState(() {
      _pushNotification = value;
      _matchNotification = value;
      _bookingUpdates = value;
      _paymentAlerts = value;
      _teamInvites = value;
    });
    _saveNotificationPreferences();
  }

  void _toggleNotificationItem(String key, bool value) {
    setState(() {
      if (key == 'match') {
        _matchNotification = value;
      } else if (key == 'booking') {
        _bookingUpdates = value;
      } else if (key == 'payment') {
        _paymentAlerts = value;
      } else if (key == 'team') {
        _teamInvites = value;
      }
      _pushNotification =
          _matchNotification || _bookingUpdates || _paymentAlerts || _teamInvites;
    });
    _saveNotificationPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
              )
            : Stack(
                children: <Widget>[
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 34),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _SettingsHeader(onBack: () => Navigator.of(context).pop()),
                        const SizedBox(height: 24),
                        _SectionCard(
                          children: <Widget>[
                            _SettingRow(
                              icon: Icons.notifications_none_rounded,
                              label: 'Push Notification',
                              value: _pushNotification,
                              onChanged: _togglePushNotification,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const _SectionTitle(title: 'Notification Settings'),
                        const SizedBox(height: 16),
                        _SectionCard(
                          children: <Widget>[
                            _SettingRow(
                              icon: Icons.notifications_none_rounded,
                              label: 'Match Notification',
                              value: _matchNotification,
                              onChanged: (bool value) => _toggleNotificationItem('match', value),
                            ),
                            _DividerLine(),
                            _SettingRow(
                              icon: Icons.notifications_none_rounded,
                              label: 'Booking Updates',
                              value: _bookingUpdates,
                              onChanged: (bool value) => _toggleNotificationItem('booking', value),
                            ),
                            _DividerLine(),
                            _SettingRow(
                              icon: Icons.notifications_none_rounded,
                              label: 'Payment Alerts',
                              value: _paymentAlerts,
                              onChanged: (bool value) => _toggleNotificationItem('payment', value),
                            ),
                            _DividerLine(),
                            _SettingRow(
                              icon: Icons.notifications_none_rounded,
                              label: 'Team Invites',
                              value: _teamInvites,
                              onChanged: (bool value) => _toggleNotificationItem('team', value),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const _SectionTitle(title: 'Location Settings'),
                        const SizedBox(height: 16),
                        _SectionCard(
                          children: <Widget>[
                            _SettingRow(
                              icon: Icons.location_on_outlined,
                              label: 'Default Location',
                              value: _defaultLocation,
                              onChanged: (bool value) {
                                if (value) {
                                  _updateLocation('device_location');
                                } else {
                                  _changeAddress();
                                }
                              },
                            ),
                            _DividerLine(),
                            InkWell(
                              onTap: _isSaving ? null : _changeAddress,
                              child: Container(
                                height: 52,
                                alignment: Alignment.center,
                                child: const Text(
                                  'Change Address',
                                  style: TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        InkWell(
                          onTap: _isSaving ? null : _logout,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            height: 51,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE3220D)),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Log Out',
                              style: TextStyle(
                                color: Color(0xFFE3220D),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isSaving)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        color: Color(0xFF2563EB),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF121C3E),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      child: Row(
        children: <Widget>[
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(22),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: Row(
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.95,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFF2563EB),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFF3A4568),
            ),
          ),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 1,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }
}