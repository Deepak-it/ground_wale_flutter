import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/api/api_session.dart';
import '../../../../core/api/ground_wale_api.dart';
import '../../../../core/utils/location_service.dart';
import '../../../../core/widgets/google_city_picker_sheet.dart';
import '../../../../core/widgets/labeled_text_field.dart';
import '../../../../core/widgets/neon_button.dart';
import '../controllers/ground_flow_controller.dart';

class AcademyDetailsScreen extends StatefulWidget {
  const AcademyDetailsScreen({super.key, required this.controller});

  final GroundFlowController controller;

  @override
  State<AcademyDetailsScreen> createState() => _AcademyDetailsScreenState();
}

class _AcademyDetailsScreenState extends State<AcademyDetailsScreen> {
  final GroundWaleApi _api = GroundWaleApi.instance;
  late final TextEditingController _nameController;
  late final TextEditingController _stateController;
  late final TextEditingController _cityController;
  late final TextEditingController _areaController;
  late final TextEditingController _addressController;
  late final TextEditingController _pinCodeController;
  late final TextEditingController _landmarkController;

  bool _locationFetched = false;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    final data = widget.controller.data;
    _nameController = TextEditingController(text: data.academyName);
    _stateController = TextEditingController(text: data.state);
    _cityController = TextEditingController(text: data.city);
    _areaController = TextEditingController(text: data.areaLocation);
    _addressController = TextEditingController(text: data.address);
    _pinCodeController = TextEditingController(text: data.pinCode);
    _landmarkController = TextEditingController(text: data.landmark);

    _seedInitialLocation();
  }

  void _seedInitialLocation() {
    final bool hasAcademyContext =
        (ApiSession.instance.selectedAcademyId?.trim().isNotEmpty ?? false);

    if (hasAcademyContext) {
      final String sessionState = ApiSession.instance.state?.trim() ?? '';
      final String sessionCity = ApiSession.instance.city?.trim() ?? '';
      final bool isDefaultState = _stateController.text.trim() == '';
      final bool isDefaultCity = _cityController.text.trim() == '';

      if (sessionState.isNotEmpty &&
          (_stateController.text.trim().isEmpty || isDefaultState)) {
        _stateController.text = sessionState;
      }
      if (sessionCity.isNotEmpty &&
          (_cityController.text.trim().isEmpty || isDefaultCity)) {
        _cityController.text = sessionCity;
      }
      _sync();
      _prefillPinFromOwnerProfile();
      return;
    }

    final bool seededDefaults =
        _stateController.text.trim() == '' &&
        _cityController.text.trim() == '' &&
        _pinCodeController.text.trim().isEmpty;
    if (seededDefaults) {
      _stateController.clear();
      _cityController.clear();
      _pinCodeController.clear();
      _sync();
    }
  }

  Future<void> _prefillPinFromOwnerProfile() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      return;
    }
    try {
      final Map<String, dynamic> profile = await _api.getOwnerProfile(ownerId);
      if (!mounted) {
        return;
      }

      final String profileState = profile['state']?.toString().trim() ?? '';
      final String profileCity = profile['city']?.toString().trim() ?? '';
      final String profilePin =
          (profile['pinCode'] ?? profile['pincode'])?.toString().trim() ?? '';

      if (profileState.isNotEmpty && _stateController.text.trim().isEmpty) {
        _stateController.text = profileState;
      }
      if (profileCity.isNotEmpty && _cityController.text.trim().isEmpty) {
        _cityController.text = profileCity;
      }
      if (profilePin.isNotEmpty && _pinCodeController.text.trim().isEmpty) {
        _pinCodeController.text = profilePin;
      }
      _sync();
    } catch (_) {
      // Best-effort prefill only.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _addressController.dispose();
    _pinCodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      final LocationResult result =
          await LocationService.fetchCurrentLocation();
      if (!mounted) return;
      if (result.geocodingSucceeded) {
        setState(() {
          _stateController.text = result.state;
          _cityController.text = result.city;
          if (result.pinCode.isNotEmpty) {
            _pinCodeController.text = result.pinCode;
          }
          _locationFetched = true;
        });
        _sync();
      } else {
        setState(() => _locationFetched = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'GPS location found. Please enter city/state manually.',
              ),
            ),
          );
        }
      }
    } on LocationServiceException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Could not fetch location'),
            action: e.error == LocationError.permissionDeniedForever
                ? SnackBarAction(
                    label: 'Settings',
                    onPressed: Geolocator.openAppSettings,
                  )
                : null,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location error. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  void _sync() {
    final data = widget.controller.data;
    data.academyName = _nameController.text.trim();
    data.state = _stateController.text.trim();
    data.city = _cityController.text.trim();
    data.areaLocation = _areaController.text.trim();
    data.address = _addressController.text.trim();
    data.pinCode = _pinCodeController.text.trim();
    data.landmark = _landmarkController.text.trim();
    widget.controller.update();
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
      _stateController.text = selection.state;
      _cityController.text = selection.city;
    });
    _sync();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1D1D1D),
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              children: <Widget>[
                const Text(
                  'Academy Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Step 2 of 6',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                LabeledTextField(
                  label: 'Academy Name',
                  controller: _nameController,
                  hint: 'Elite Cricket Academy',
                  onChanged: (_) => _sync(),
                ),
                const SizedBox(height: 16),
                // ── Use Location button ──────────────────────────────
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
                          border: Border.all(color: const Color(0xFF2563EB)),
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
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LabeledTextField(
                  label: 'State',
                  controller: _stateController,
                  hint: '',
                  readOnly: true,
                  onTap: _pickCityState,
                  suffixIcon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 16),
                LabeledTextField(
                  label: 'City',
                  controller: _cityController,
                  hint: '',
                  readOnly: true,
                  onTap: _pickCityState,
                  suffixIcon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 16),
                LabeledTextField(
                  label: 'Area / Locality',
                  controller: _areaController,
                  hint: 'Sector 118',
                  onChanged: (_) => _sync(),
                ),
                const SizedBox(height: 16),
                LabeledTextField(
                  label: 'Full Address',
                  controller: _addressController,
                  hint: 'Plot No. 5, Phase 7, Industrial Area',
                  onChanged: (_) => _sync(),
                ),
                const SizedBox(height: 16),
                LabeledTextField(
                  label: 'Pin Code',
                  controller: _pinCodeController,
                  hint: '160059',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _sync(),
                ),
                const SizedBox(height: 16),
                LabeledTextField(
                  label: 'Landmark',
                  controller: _landmarkController,
                  hint: 'Near City Sports Complex',
                  onChanged: (_) => _sync(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0x00050505), Color(0xFF050505)],
                stops: <double>[0, 0.4],
              ),
            ),
            child: Row(
              children: <Widget>[
                SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () {
                      _sync();
                      widget.controller.previousStep();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0x80D7FF00)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        color: Color(0xFFD7FF00),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: NeonButton(
                    label: 'Continue',
                    onPressed: () {
                      _sync();
                      final data = widget.controller.data;
                      if (data.academyName.isEmpty ||
                          data.city.isEmpty ||
                          data.address.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Academy Name, City and Address are required',
                            ),
                          ),
                        );
                        return;
                      }
                      widget.controller.nextStep();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
