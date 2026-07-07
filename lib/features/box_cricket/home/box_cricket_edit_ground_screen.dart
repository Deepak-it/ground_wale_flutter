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
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

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
      _groundNameController.text = ground['groundName']?.toString() ?? '';
      _locationController.text = ground['location']?.toString() ?? '';
      _addressController.text = ground['address']?.toString() ?? '';
      _descriptionController.text = ground['description']?.toString() ?? '';
    } catch (_) {
      // Keep empty defaults if ground details fail to load.
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
        'location': _locationController.text.trim(),
        'address': _addressController.text.trim(),
        'description': _descriptionController.text.trim(),
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

  @override
  void dispose() {
    _groundNameController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
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
            : Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 16, 0),
                    child: Row(
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
                        const Text(
                          'Edit Ground Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: <Widget>[
                        _field(
                          label: 'Ground Name',
                          controller: _groundNameController,
                        ),
                        const SizedBox(height: 16),
                        _field(
                          label: 'Location',
                          controller: _locationController,
                        ),
                        const SizedBox(height: 16),
                        _field(
                          label: 'Address',
                          controller: _addressController,
                        ),
                        const SizedBox(height: 16),
                        _field(
                          label: 'Description',
                          controller: _descriptionController,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        const _GroundImagesSection(),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveGround,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF08B36A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
                                : const Text('Update Ground'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
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
          ),
        ),
        const SizedBox(height: 8),
        AppTextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0x08FFFFFF),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
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

class _GroundImagesSection extends StatelessWidget {
  const _GroundImagesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Ground Image',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: const <Widget>[
            Expanded(child: _ImagePlaceholder(filled: true)),
            SizedBox(width: 8),
            Expanded(child: _ImagePlaceholder(filled: true)),
            SizedBox(width: 8),
            Expanded(child: _ImagePlaceholder(filled: false)),
          ],
        ),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0x14FFFFFF),
          width: 2,
          style: BorderStyle.solid,
        ),
        gradient: filled
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0x9908B36A), Color(0x99034D2E)],
              )
            : null,
        color: filled ? null : const Color(0x08FFFFFF),
      ),
      child: filled
          ? null
          : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.add_photo_alternate_outlined,
                  color: Color(0xFF94A3B8),
                  size: 24,
                ),
                SizedBox(height: 8),
                Text(
                  'Upload Image',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }
}


