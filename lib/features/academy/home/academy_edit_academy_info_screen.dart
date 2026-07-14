import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';

class AcademyEditAcademyInfoScreen extends StatefulWidget {
  const AcademyEditAcademyInfoScreen({super.key});

  @override
  State<AcademyEditAcademyInfoScreen> createState() =>
      _AcademyEditAcademyInfoScreenState();
}

class _AcademyEditAcademyInfoScreenState
    extends State<AcademyEditAcademyInfoScreen> {
  late final TextEditingController _academyNameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _mapLocationController;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _academyNameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _mapLocationController = TextEditingController();
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
      final Map<String, dynamic> profile = await GroundWaleApi.instance
          .getOwnerProfile(ownerId);
      if (!mounted) {
        return;
      }
      _academyNameController.text =
          profile['academyName']?.toString().trim().isNotEmpty == true
          ? profile['academyName'].toString().trim()
          : profile['ownerName']?.toString() ?? '';
      _addressController.text = profile['address']?.toString() ?? '';
      _phoneController.text = profile['contactNumber']?.toString() ?? '';
      _mapLocationController.text = profile['mapLocation']?.toString() ?? '';
      setState(() => _isLoading = false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _save() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final Map<String, dynamic> profile = await GroundWaleApi.instance
          .updateOwnerProfile(ownerId, <String, dynamic>{
            'ownerName': _academyNameController.text.trim(),
            'address': _addressController.text.trim(),
            'contactNumber': _phoneController.text.trim(),
            'mapLocation': _mapLocationController.text.trim(),
          });

      ApiSession.instance.updateFromAuth(profile);
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

  @override
  void dispose() {
    _academyNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _mapLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
              )
            : Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                              const Text(
                                'Edit Academy info',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const _FieldLabel(label: 'Academy Name'),
                          const SizedBox(height: 8),
                          _InputBox(controller: _academyNameController),
                          const SizedBox(height: 20),
                          const _FieldLabel(label: 'Address'),
                          const SizedBox(height: 8),
                          _InputBox(
                            controller: _addressController,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 20),
                          const _FieldLabel(label: 'Phone Number'),
                          const SizedBox(height: 8),
                          _InputBox(controller: _phoneController),
                          const SizedBox(height: 20),
                          const _FieldLabel(label: 'Google Map Location'),
                          const SizedBox(height: 8),
                          _InputBox(controller: _mapLocationController),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C9A7),
                                foregroundColor: const Color(0xFF242424),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Color(0xFF242424),
                                      ),
                                    )
                                  : const Text(
                                      'Save Changes',
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
                  ),
                ],
              ),
      ),
      bottomNavigationBar: null,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  const _InputBox({required this.controller, this.maxLines = 1});

  final TextEditingController controller;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x08FFFFFF),
      ),
      child: AppTextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: const InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
        ),
      ),
    );
  }
}

