import 'package:flutter/material.dart';

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
  late final TextEditingController _nameController;
  late final TextEditingController _stateController;
  late final TextEditingController _cityController;
  late final TextEditingController _areaController;
  late final TextEditingController _addressController;
  late final TextEditingController _pinCodeController;
  late final TextEditingController _landmarkController;

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
                LabeledTextField(
                  label: 'State',
                  controller: _stateController,
                  hint: 'Punjab',
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
                  hint: 'Mohali',
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
                      if (data.academyName.isEmpty || data.city.isEmpty || data.address.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Academy Name, City and Address are required'),
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
