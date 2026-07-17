import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';

class BoxCricketEditGroundScreen extends StatefulWidget {
  const BoxCricketEditGroundScreen({super.key});

  @override
  State<BoxCricketEditGroundScreen> createState() =>
      _BoxCricketEditGroundScreenState();
}

class _BoxCricketEditGroundScreenState
    extends State<BoxCricketEditGroundScreen> {
  final TextEditingController _groundNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _openingTimeController = TextEditingController();
  final TextEditingController _closingTimeController = TextEditingController();
  final TextEditingController _amenitiesController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  String _pitchType = 'Turf';
  String _groundSize = 'Medium';

  static const List<String> _pitchTypeOptions = <String>[
    'Turf',
    'Mat',
    'Concrete',
    'Synthetic',
  ];

  static const List<String> _groundSizeOptions = <String>[
    'Small',
    'Medium',
    'Large',
  ];

  @override
  void initState() {
    super.initState();
    _loadGround();
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

  Future<void> _loadGround() async {
    try {
      final String? groundId = await _resolveGroundId();
      if (groundId == null || groundId.isEmpty) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final Map<String, dynamic> ground = await GroundWaleApi.instance
          .getGround(groundId);
      final Map<String, dynamic> operationHours = Map<String, dynamic>.from(
        ground['operationHours'] as Map? ?? <String, dynamic>{},
      );

      _groundNameController.text = ground['groundName']?.toString() ?? '';
      _descriptionController.text = ground['description']?.toString() ?? '';
      _addressController.text = ground['address']?.toString() ?? '';
      _openingTimeController.text =
          operationHours['openingTime']?.toString() ??
          ground['openingTime']?.toString() ??
          '05:00 AM';
      _closingTimeController.text =
          operationHours['closingTime']?.toString() ??
          ground['closingTime']?.toString() ??
          '10:00 PM';
      _pitchType = ground['pitchType']?.toString().trim().isNotEmpty == true
          ? ground['pitchType'].toString().trim()
          : _pitchType;
      _groundSize = ground['groundSize']?.toString().trim().isNotEmpty == true
          ? ground['groundSize'].toString().trim()
          : _groundSize;
      _amenitiesController.text =
          ground['amenities']?.toString() ?? 'Lights, Parking, Washroom';
    } catch (_) {
      // Keep defaults when ground details fail to load.
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveGround() async {
    final String? groundId = await _resolveGroundId();
    if (groundId == null || groundId.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ground not found for this owner.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await GroundWaleApi.instance.updateGround(groundId, <String, dynamic>{
        'groundName': _groundNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'openingTime': _openingTimeController.text.trim(),
        'closingTime': _closingTimeController.text.trim(),
        'pitchType': _pitchType,
        'groundSize': _groundSize,
        'amenities': _amenitiesController.text.trim(),
        'operationHours': <String, dynamic>{
          'openingTime': _openingTimeController.text.trim(),
          'closingTime': _closingTimeController.text.trim(),
        },
      });
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
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

  Future<void> _pickTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(controller.text) ?? TimeOfDay.now(),
      helpText: 'Select time',
    );
    if (picked == null) {
      return;
    }
    final int hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
    final String minute = picked.minute.toString().padLeft(2, '0');
    final String period = picked.period == DayPeriod.am ? 'AM' : 'PM';
    setState(() {
      controller.text = '$hour:$minute $period';
    });
  }

  TimeOfDay? _parseTime(String text) {
    final RegExp match = RegExp(r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])$');
    final RegExpMatch? parsed = match.firstMatch(text.trim());
    if (parsed == null) {
      return null;
    }
    int hour = int.tryParse(parsed.group(1) ?? '') ?? 0;
    final int minute = int.tryParse(parsed.group(2) ?? '') ?? 0;
    final String period = (parsed.group(3) ?? '').toUpperCase();
    if (period == 'PM' && hour < 12) {
      hour += 12;
    }
    if (period == 'AM' && hour == 12) {
      hour = 0;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _selectOption({
    required String title,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) async {
    final String? value = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1F241F),
      builder: (BuildContext context) {
        return SafeArea(
          top: false,
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              ...options.map((String option) {
                final bool isSelected = option == selected;
                return ListTile(
                  title: Text(
                    option,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFFDDF730)
                          : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFFDDF730))
                      : null,
                  onTap: () => Navigator.of(context).pop(option),
                );
              }),
            ],
          ),
        );
      },
    );

    if (value != null && mounted) {
      setState(() => onSelected(value));
    }
  }

  @override
  void dispose() {
    _groundNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _openingTimeController.dispose();
    _closingTimeController.dispose();
    _amenitiesController.dispose();
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
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
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
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Edit Ground',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionCard(
                    title: 'Ground Info',
                    children: <Widget>[
                      _textField(
                        label: 'Ground Name',
                        controller: _groundNameController,
                        hint: 'Cricket Arena',
                      ),
                      const SizedBox(height: 20),
                      _textField(
                        label: 'Description',
                        controller: _descriptionController,
                        hint: 'Best premium turf in the city',
                        maxLines: 4,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Location',
                    children: <Widget>[
                      _textField(
                        label: 'Address',
                        controller: _addressController,
                        hint: 'Sector 21, Gurgaon',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(title: 'Images', children: const <Widget>[_ImagesRow()]),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Operation Hours',
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _timeField(
                              label: 'Opening Time',
                              controller: _openingTimeController,
                              onTap: () => _pickTime(_openingTimeController),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _timeField(
                              label: 'Closing Time',
                              controller: _closingTimeController,
                              onTap: () => _pickTime(_closingTimeController),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Ground Details',
                    children: <Widget>[
                      _selectField(
                        label: 'Pitch Type',
                        value: _pitchType,
                        onTap: () {
                          _selectOption(
                            title: 'Pitch Type',
                            options: _pitchTypeOptions,
                            selected: _pitchType,
                            onSelected: (String value) => _pitchType = value,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _selectField(
                        label: 'Ground Size',
                        value: _groundSize,
                        onTap: () {
                          _selectOption(
                            title: 'Ground Size',
                            options: _groundSizeOptions,
                            selected: _groundSize,
                            onSelected: (String value) => _groundSize = value,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        label: 'Amenities',
                        controller: _amenitiesController,
                        hint: 'Lights, Parking, Washroom',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _isSaving
                                ? null
                                : () => Navigator.of(context).maybePop(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0x1FFFFFFF)),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveGround,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDDF730),
                              foregroundColor: const Color(0xFF242424),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF242424),
                                    ),
                                  )
                                : const Text('Save'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
      bottomNavigationBar: null,
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1F242424)),
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
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
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
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        AppTextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            fontFamily: 'Poppins',
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0x99FFFFFF)),
            filled: true,
            fillColor: const Color(0x08FFFFFF),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x1F1C333B)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDDF730)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _timeField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
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
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x1F1C333B)),
              color: const Color(0x08FFFFFF),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    controller.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const Icon(
                  Icons.access_time_rounded,
                  color: Color(0x99FFFFFF),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _selectField({
    required String label,
    required String value,
    required VoidCallback onTap,
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
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x1F1C333B)),
              color: const Color(0x08FFFFFF),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ImagesRow extends StatelessWidget {
  const _ImagesRow();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: const <Widget>[
          _AddPhotoCard(),
          SizedBox(width: 16),
          _AddPhotoCard(),
          SizedBox(width: 16),
          _AddPhotoCard(),
        ],
      ),
    );
  }
}

class _AddPhotoCard extends StatelessWidget {
  const _AddPhotoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x1F1C333B)),
        color: const Color(0x08FFFFFF),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.add, size: 24, color: Colors.white),
          SizedBox(height: 10),
          Text(
            'Add photo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
