import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/labeled_text_field.dart';
import '../../../../core/widgets/neon_button.dart';
import '../controllers/ground_flow_controller.dart';
import '../models/ground_registration_data.dart';

class SharedDetailsScreen extends StatefulWidget {
  const SharedDetailsScreen({super.key, required this.controller});

  final GroundFlowController controller;

  @override
  State<SharedDetailsScreen> createState() => _SharedDetailsScreenState();
}

class _SharedDetailsScreenState extends State<SharedDetailsScreen> {
  late final TextEditingController _stateController;
  late final TextEditingController _cityController;
  late final TextEditingController _areaController;
  late final TextEditingController _addressController;
  late final TextEditingController _pinCodeController;
  late final TextEditingController _landmarkController;

  @override
  void initState() {
    super.initState();
    _stateController = TextEditingController(
      text: widget.controller.data.state,
    );
    _cityController = TextEditingController(text: widget.controller.data.city);
    _areaController = TextEditingController(
      text: widget.controller.data.areaLocation,
    );
    _addressController = TextEditingController(
      text: widget.controller.data.address,
    );
    _pinCodeController = TextEditingController(
      text: widget.controller.data.pinCode,
    );
    _landmarkController = TextEditingController(
      text: widget.controller.data.landmark,
    );
  }

  @override
  void dispose() {
    _stateController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _addressController.dispose();
    _pinCodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  void _sync() {
    widget.controller.data.state = _stateController.text.trim();
    widget.controller.data.city = _cityController.text.trim();
    widget.controller.data.areaLocation = _areaController.text.trim();
    widget.controller.data.address = _addressController.text.trim();
    widget.controller.data.pinCode = _pinCodeController.text.trim();
    widget.controller.data.landmark = _landmarkController.text.trim();
    widget.controller.update();
  }

  @override
  Widget build(BuildContext context) {
    final OfferType? offerType = widget.controller.data.offerType;
    final bool academy = offerType == OfferType.academyCoaching;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            academy ? 'Academy Details' : 'Ground Details',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text('Step 2 of 5', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              children: <Widget>[
                LabeledTextField(
                  label: 'State',
                  controller: _stateController,
                  hint: 'Select State',
                  onChanged: (_) => _sync(),
                ),
                const SizedBox(height: 14),
                LabeledTextField(
                  label: 'City',
                  controller: _cityController,
                  hint: 'Select City',
                  onChanged: (_) => _sync(),
                ),
                const SizedBox(height: 14),
                LabeledTextField(
                  label: 'Area / Location',
                  controller: _areaController,
                  hint: 'Area / Location',
                  onChanged: (_) => _sync(),
                ),
                const SizedBox(height: 14),
                LabeledTextField(
                  label: 'Full Address',
                  controller: _addressController,
                  hint: 'Enter full address',
                  onChanged: (_) => _sync(),
                ),
                const SizedBox(height: 14),
                LabeledTextField(
                  label: 'Pin Code',
                  controller: _pinCodeController,
                  keyboardType: TextInputType.number,
                  hint: 'Enter pin code',
                  onChanged: (_) => _sync(),
                ),
                const SizedBox(height: 14),
                LabeledTextField(
                  label: 'Landmark',
                  controller: _landmarkController,
                  hint: 'Enter your landmark',
                  onChanged: (_) => _sync(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          NeonButton(
            label: 'Next',
            onPressed: () {
              _sync();
              if (widget.controller.data.state.isEmpty ||
                  widget.controller.data.city.isEmpty ||
                  widget.controller.data.address.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill state, city and address'),
                  ),
                );
                return;
              }
              widget.controller.nextStep();
            },
          ),
        ],
      ),
    );
  }
}
