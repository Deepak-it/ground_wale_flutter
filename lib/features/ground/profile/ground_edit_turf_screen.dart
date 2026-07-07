import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'profile_turf_ui.dart';

class GroundEditTurfScreen extends StatefulWidget {
  const GroundEditTurfScreen({super.key});

  @override
  State<GroundEditTurfScreen> createState() => _GroundEditTurfScreenState();
}

class _GroundEditTurfScreenState extends State<GroundEditTurfScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  bool _isSaving = false;

  Future<void> _loadGround() async {
    final ApiSession session = ApiSession.instance;
    if (!session.hasGround && session.isAuthenticated) {
      session.setGroundId(await GroundWaleApi.instance.ensureGroundIdForOwner(session.ownerId!));
    }
    if (!session.hasGround) {
      return;
    }
    final Map<String, dynamic> ground = await GroundWaleApi.instance.getGround(session.groundId!);
    nameController.text = ground['groundName']?.toString() ?? '';
    locationController.text = ground['location']?.toString() ?? '';
    addressController.text = ground['address']?.toString() ?? '';
    descriptionController.text = ground['description']?.toString() ?? '';
  }

  Future<void> _saveGround() async {
    final ApiSession session = ApiSession.instance;
    if (!session.hasGround) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await GroundWaleApi.instance.updateGround(
        session.groundId!,
        <String, dynamic>{
          'groundName': nameController.text.trim(),
          'location': locationController.text.trim(),
          'address': addressController.text.trim(),
          'description': descriptionController.text.trim(),
        },
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    addressController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget field(String label, TextEditingController controller) {
      return TurfCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: const TextStyle(color: Colors.white70)),
            AppTextField(controller: controller, decoration: const InputDecoration(border: InputBorder.none)),
          ],
        ),
      );
    }

    return TurfPageScaffold(
      title: 'Edit Ground Details',
      child: FutureBuilder<void>(
        future: _loadGround(),
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFDDF730)));
          }
          return ListView(
            children: <Widget>[
              field('Ground Name', nameController),
              field('Location', locationController),
              field('Address', addressController),
              field('Description', descriptionController),
              const TurfCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Ground Image', style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w500)),
                    SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        _ImageTile(filled: true),
                        SizedBox(width: 8),
                        _ImageTile(filled: true),
                        SizedBox(width: 8),
                        _ImageTile(filled: false),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDDF730),
                    foregroundColor: const Color(0xFF242424),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  onPressed: _isSaving ? null : _saveGround,
                  child: const Text('Update Ground'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    final BoxDecoration decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0x22FFFFFF), width: 2),
      gradient: filled
          ? const LinearGradient(colors: <Color>[Color(0x9908B36A), Color(0x99034D2E)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
          : null,
      color: filled ? null : const Color(0x10FFFFFF),
    );

    return Expanded(
      child: Container(
        height: 110,
        decoration: decoration,
        child: filled
            ? const SizedBox.shrink()
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF94A3B8)),
                  SizedBox(height: 8),
                  Text('Upload Image', style: TextStyle(color: Color(0xFF94A3B8))),
                ],
              ),
      ),
    );
  }
}


