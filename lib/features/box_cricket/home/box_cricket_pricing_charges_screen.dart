import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'box_cricket_bottom_nav.dart';
import 'box_cricket_dashboard_screen.dart';
import 'box_cricket_manage_slots_screen.dart';
import 'box_cricket_profile_screen.dart';
import 'box_cricket_upcoming_bookings_screen.dart';

class BoxCricketPricingChargesScreen extends StatefulWidget {
  const BoxCricketPricingChargesScreen({super.key});

  @override
  State<BoxCricketPricingChargesScreen> createState() =>
      _BoxCricketPricingChargesScreenState();
}

class _BoxCricketPricingChargesScreenState
    extends State<BoxCricketPricingChargesScreen> {
  final TextEditingController _weekdayPriceController = TextEditingController();
  final TextEditingController _weekendPriceController = TextEditingController();
  final TextEditingController _peakStartController = TextEditingController();
  final TextEditingController _peakEndController = TextEditingController();
  final TextEditingController _peakPriceController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _enablePeakPricing = false;
  bool _includeTax = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String?> _resolveGroundId() async {
    final ApiSession session = ApiSession.instance;
    if (session.hasGround) {
      return session.groundId;
    }

    final String? ownerId = session.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      return null;
    }

    final String? resolved = await GroundWaleApi.instance
        .ensureGroundIdForOwner(ownerId);
    if (resolved != null && resolved.isNotEmpty) {
      session.setGroundId(resolved);
    }
    return resolved;
  }

  Future<void> _load() async {
    final String? groundId = await _resolveGroundId();
    if (groundId == null || groundId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final Map<String, dynamic> ground = await GroundWaleApi.instance
          .getGround(groundId);
      final Map<String, dynamic> pricing = Map<String, dynamic>.from(
        ground['pricing'] as Map? ?? <String, dynamic>{},
      );
      final Map<String, dynamic> peak = Map<String, dynamic>.from(
        pricing['peakPricing'] as Map? ?? <String, dynamic>{},
      );

      _weekdayPriceController.text =
          pricing['weekdayPrice']?.toString() ??
          ground['weekdayPrice']?.toString() ??
          '';
      _weekendPriceController.text =
          pricing['weekendPrice']?.toString() ??
          ground['weekendPrice']?.toString() ??
          '';
      _enablePeakPricing =
          pricing['enablePeakPricing'] as bool? ??
          ground['enablePeakPricing'] as bool? ??
          false;
      _peakStartController.text =
          peak['startTime']?.toString() ??
          ground['peakStartTime']?.toString() ??
          '';
      _peakEndController.text =
          peak['endTime']?.toString() ??
          ground['peakEndTime']?.toString() ??
          '';
      _peakPriceController.text =
          peak['price']?.toString() ?? ground['peakPrice']?.toString() ?? '';
      _includeTax =
          pricing['includeTax'] as bool? ??
          ground['includeTax'] as bool? ??
          false;
    } catch (_) {
      // Keep empty form defaults when API data is missing.
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final String? groundId = await _resolveGroundId();
    if (groundId == null || groundId.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await GroundWaleApi.instance.updateGround(groundId, <String, dynamic>{
        'weekdayPrice': _weekdayPriceController.text.trim(),
        'weekendPrice': _weekendPriceController.text.trim(),
        'enablePeakPricing': _enablePeakPricing,
        'peakStartTime': _peakStartController.text.trim(),
        'peakEndTime': _peakEndController.text.trim(),
        'peakPrice': _peakPriceController.text.trim(),
        'includeTax': _includeTax,
        'pricing': <String, dynamic>{
          'weekdayPrice': _weekdayPriceController.text.trim(),
          'weekendPrice': _weekendPriceController.text.trim(),
          'enablePeakPricing': _enablePeakPricing,
          'includeTax': _includeTax,
          'peakPricing': <String, dynamic>{
            'startTime': _peakStartController.text.trim(),
            'endTime': _peakEndController.text.trim(),
            'price': _peakPriceController.text.trim(),
          },
        },
      });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pricing & charges updated.')),
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
  void dispose() {
    _weekdayPriceController.dispose();
    _weekendPriceController.dispose();
    _peakStartController.dispose();
    _peakEndController.dispose();
    _peakPriceController.dispose();
    super.dispose();
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
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Pricing & Charges',
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
                  _sectionCard(
                    title: 'Default Slot Pricing',
                    children: <Widget>[
                      _priceField(
                        label: 'Weekday Price (per slot)',
                        controller: _weekdayPriceController,
                      ),
                      const SizedBox(height: 12),
                      _priceField(
                        label: 'Weekend Price (per slot)',
                        controller: _weekendPriceController,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Peak Pricing',
                    children: <Widget>[
                      _toggleTile(
                        title: 'Enable Peak Pricing',
                        subtitle: 'Use custom pricing for busy hours',
                        value: _enablePeakPricing,
                        onChanged: (bool value) {
                          setState(() => _enablePeakPricing = value);
                        },
                      ),
                      if (_enablePeakPricing) ...<Widget>[
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _timeField(
                                label: 'Start Time',
                                controller: _peakStartController,
                                hint: '18:00',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _timeField(
                                label: 'End Time',
                                controller: _peakEndController,
                                hint: '22:00',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _priceField(
                          label: 'Peak Price (per slot)',
                          controller: _peakPriceController,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Additional Charges',
                    children: <Widget>[
                      _toggleTile(
                        title: 'Include Tax in Displayed Price',
                        subtitle: 'If off, tax can be added at checkout',
                        value: _includeTax,
                        onChanged: (bool value) {
                          setState(() => _includeTax = value);
                        },
                      ),
                    ],
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
                              'Save Pricing',
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
      bottomNavigationBar: BoxCricketBottomNav(
        currentIndex: 3,
        onHome: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(
              builder: (_) => const BoxCricketDashboardScreen(),
            ),
            (Route<dynamic> route) => false,
          );
        },
        onAnnouncement: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const BoxCricketUpcomingBookingsScreen(),
            ),
          );
        },
        onSlots: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const BoxCricketManageSlotsScreen(),
            ),
          );
        },
        onProfile: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const BoxCricketProfileScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x08FFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _toggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0x99FFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: const Color(0xFF08B36A),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0x80FFFFFF),
        ),
      ],
    );
  }

  Widget _priceField({
    required String label,
    required TextEditingController controller,
  }) {
    return _textField(
      label: label,
      controller: controller,
      hint: '0',
      prefix: 'Rs ',
    );
  }

  Widget _timeField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return _textField(label: label, controller: controller, hint: hint);
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required String hint,
    String? prefix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        AppTextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            prefixStyle: const TextStyle(color: Color(0xAAFFFFFF)),
            hintStyle: const TextStyle(color: Color(0x66FFFFFF)),
            filled: true,
            fillColor: const Color(0x0FFFFFFF),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF08B36A)),
            ),
          ),
        ),
      ],
    );
  }
}


