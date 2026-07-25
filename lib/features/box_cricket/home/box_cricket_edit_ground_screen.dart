import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import '../../../core/utils/location_service.dart';
import '../../../core/utils/base64_image.dart';
import '../../../core/widgets/google_city_picker_sheet.dart';

class BoxCricketEditGroundScreen extends StatefulWidget {
  const BoxCricketEditGroundScreen({super.key});

  @override
  State<BoxCricketEditGroundScreen> createState() =>
      _BoxCricketEditGroundScreenState();
}

class _BoxCricketEditGroundScreenState
    extends State<BoxCricketEditGroundScreen> {
  static const int _maxImageBytes = 3 * 1024 * 1024;

  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _groundNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _pinCodeController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _openingTimeController = TextEditingController();
  final TextEditingController _closingTimeController = TextEditingController();
  List<String> _facilities = <String>[];

  bool _isLoading = true;
  bool _isPickingImages = false;
  bool _isFetchingLocation = false;
  bool _locationFetched = false;
  bool _isSaving = false;

  String _pitchType = 'Turf';
  String _groundSize = 'Medium';
  List<String> _groundImages = <String>[];
  String _mapLocation = '';

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
      _stateController.text = ground['state']?.toString() ?? '';
      _cityController.text = ground['city']?.toString() ?? '';
      _areaController.text =
          ground['areaLocation']?.toString() ??
          ground['location']?.toString() ??
          '';
      _pinCodeController.text = ground['pinCode']?.toString() ?? '';
      _landmarkController.text = ground['landmark']?.toString() ?? '';
      _mapLocation = ground['mapLocation']?.toString() ?? '';
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
      _facilities = List<String>.from(ground['facilities'] ?? <dynamic>[]);
      _groundImages = _groundImageValues(ground);
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
        'state': _stateController.text.trim(),
        'city': _cityController.text.trim(),
        'areaLocation': _areaController.text.trim(),
        'pinCode': _pinCodeController.text.trim(),
        'landmark': _landmarkController.text.trim(),
        if (_mapLocation.trim().isNotEmpty) 'mapLocation': _mapLocation.trim(),
        'openingTime': _openingTimeController.text.trim(),
        'closingTime': _closingTimeController.text.trim(),
        'pitchType': _pitchType,
        'groundSize': _groundSize,
        'facilities': _facilities,
        'groundImages': _groundImages,
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

  String _mimeFromName(String name) {
    final String lower = name.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }
    return 'image/jpeg';
  }

  List<String> _groundImageValues(Map<String, dynamic> ground) {
    final List<String> values = <String>[];

    void addIfValid(dynamic raw) {
      final String value = raw?.toString().trim() ?? '';
      if (value.isNotEmpty && !values.contains(value)) {
        values.add(value);
      }
    }

    addIfValid(ground['image']);
    addIfValid(ground['imageUrl']);

    final dynamic imageUrls = ground['imageUrls'];
    if (imageUrls is List) {
      for (final dynamic item in imageUrls) {
        addIfValid(item);
      }
    }

    final dynamic groundImages = ground['groundImages'];
    if (groundImages is List) {
      for (final dynamic item in groundImages) {
        addIfValid(item);
      }
    }

    return values;
  }

  Future<void> _pickGroundImages() async {
    if (_isPickingImages) {
      return;
    }

    setState(() => _isPickingImages = true);
    try {
      final bool isDesktop =
          !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.linux ||
              defaultTargetPlatform == TargetPlatform.macOS);
      final List<String> pickedImages = <String>[];

      if (isDesktop) {
        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
          withData: true,
        );
        if (result == null || result.files.isEmpty) {
          return;
        }

        for (final PlatformFile file in result.files) {
          List<int> bytes = file.bytes ?? <int>[];
          if (bytes.isEmpty && file.path != null) {
            bytes = await XFile(file.path!).readAsBytes();
          }
          if (bytes.isEmpty) {
            continue;
          }
          if (bytes.length > _maxImageBytes) {
            throw Exception(
              '${file.name} is too large. Please select images smaller than 3 MB.',
            );
          }
          pickedImages.add(
            'data:${_mimeFromName(file.name)};base64,${base64Encode(bytes)}',
          );
        }
      } else {
        final List<XFile> files = await _imagePicker.pickMultiImage(
          imageQuality: 75,
          maxWidth: 1024,
        );
        for (final XFile file in files) {
          final List<int> bytes = await file.readAsBytes();
          if (bytes.isEmpty) {
            continue;
          }
          if (bytes.length > _maxImageBytes) {
            throw Exception(
              '${file.name} is too large. Please select images smaller than 3 MB.',
            );
          }
          final String mime = file.mimeType ?? _mimeFromName(file.name);
          pickedImages.add('data:$mime;base64,${base64Encode(bytes)}');
        }
      }

      if (pickedImages.isEmpty || !mounted) {
        return;
      }

      setState(() {
        for (final String value in pickedImages) {
          if (!_groundImages.contains(value)) {
            _groundImages.add(value);
          }
        }
      });
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message?.isNotEmpty == true
                ? error.message!
                : 'Image picker is not available right now.',
          ),
        ),
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
        setState(() => _isPickingImages = false);
      }
    }
  }

  void _removeGroundImage(int index) {
    setState(() => _groundImages.removeAt(index));
  }

  Future<void> _fetchLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      final LocationResult result =
          await LocationService.fetchCurrentLocation();
      setState(() {
        _cityController.text = result.city;
        _stateController.text = result.state;
        if (result.pinCode.isNotEmpty) {
          _pinCodeController.text = result.pinCode;
        }
        _mapLocation = '${result.latitude},${result.longitude}';
        _locationFetched = result.geocodingSucceeded;
      });

      if (!mounted) {
        return;
      }
      if (!result.geocodingSucceeded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'GPS location found. Please enter city/state manually.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } on LocationServiceException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Could not fetch location'),
          action: error.error == LocationError.permissionDeniedForever
              ? SnackBarAction(
                  label: 'Settings',
                  onPressed: Geolocator.openAppSettings,
                )
              : null,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Location error: $error')));
    } finally {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  Future<void> _pickCityState() async {
    final GoogleCitySelection? selection = await showGoogleCityPickerSheet(
      context: context,
      title: 'Select City & State',
      initialQuery: _cityController.text,
    );
    if (!mounted || selection == null || selection.isEmpty) {
      return;
    }
    setState(() {
      _cityController.text = selection.city;
      _stateController.text = selection.state;
      _locationFetched = false;
    });
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
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
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
    _stateController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _pinCodeController.dispose();
    _landmarkController.dispose();
    _openingTimeController.dispose();
    _closingTimeController.dispose();
    super.dispose();
  }

  Future<void> _addFacility() async {
    final TextEditingController controller = TextEditingController();

    final String? value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F241F),
          title: const Text(
            'Add Facility',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Facility name',
              hintStyle: TextStyle(color: Colors.white54),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (value == null || value.isEmpty) {
      return;
    }

    if (_facilities.contains(value)) {
      return;
    }

    setState(() {
      _facilities.add(value);
    });
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
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              _locationFetched
                                  ? 'Location detected'
                                  : 'Detect your location',
                              style: TextStyle(
                                color: _locationFetched
                                    ? const Color(0xFF4ADE80)
                                    : Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _isFetchingLocation ? null : _fetchLocation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: const Color(0xFF1C333B),
                                border: Border.all(
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                              child: _isFetchingLocation
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Icon(
                                          Icons.my_location,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        SizedBox(width: 5),
                                        Text(
                                          'Use Location',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _textField(
                        label: 'State',
                        controller: _stateController,
                        hint: 'Select State',
                        onTap: _pickCityState,
                      ),
                      const SizedBox(height: 14),
                      _textField(
                        label: 'City',
                        controller: _cityController,
                        hint: 'Select City',
                        onTap: _pickCityState,
                      ),
                      const SizedBox(height: 14),
                      _textField(
                        label: 'Area / Location',
                        controller: _areaController,
                        hint: 'Area / Location',
                      ),
                      const SizedBox(height: 14),
                      _textField(
                        label: 'Full Address',
                        controller: _addressController,
                        hint: 'Enter full address',
                      ),
                      const SizedBox(height: 14),
                      _textField(
                        label: 'Pin Code',
                        controller: _pinCodeController,
                        hint: 'Enter pin code',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      _textField(
                        label: 'Landmark',
                        controller: _landmarkController,
                        hint: 'Enter your landmark',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Images',
                    children: <Widget>[
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            'Slide right',
                            style: TextStyle(
                              color: Color(0x99FFFFFF),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_double_arrow_right_rounded,
                            color: Color(0x99FFFFFF),
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 144,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _groundImages.length + 1,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (_, int index) {
                            if (index == _groundImages.length) {
                              return _addPhotoCard();
                            }
                            return _groundImageCard(
                              _groundImages[index],
                              index,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
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
    TextInputType? keyboardType,
    GestureTapCallback? onTap,
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
          keyboardType: keyboardType,
          onTap: onTap,
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

  Widget _groundImageCard(String imageValue, int index) {
    return Container(
      width: 168,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x1F1C333B)),
        color: const Color(0x08FFFFFF),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          buildBase64OrNetworkImage(
            value: imageValue,
            fit: BoxFit.cover,
            fallback: const ColoredBox(
              color: Color(0x14000000),
              child: Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.white70,
                  size: 28,
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: InkWell(
              onTap: () => _removeGroundImage(index),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xCC0B0E0C),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addPhotoCard() {
    return InkWell(
      onTap: _isPickingImages ? null : _pickGroundImages,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 168,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x1F1C333B)),
          color: const Color(0x08FFFFFF),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _isPickingImages
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFDDF730),
                    ),
                  )
                : const Icon(Icons.add, size: 24, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              _groundImages.isEmpty ? 'Add photo' : 'Add more photos',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
