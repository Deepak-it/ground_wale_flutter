import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'profile_turf_ui.dart';

class ProfileCompactTurfScreen extends StatefulWidget {
  const ProfileCompactTurfScreen({super.key});

  @override
  State<ProfileCompactTurfScreen> createState() => _ProfileCompactTurfScreenState();
}

class _ProfileCompactTurfScreenState extends State<ProfileCompactTurfScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  bool _isSaving = false;

  Future<void> _loadProfile() async {
    final ApiSession session = ApiSession.instance;
    if (!session.isAuthenticated) {
      return;
    }

    final Map<String, dynamic> profile = await GroundWaleApi.instance.getOwnerProfile(session.ownerId!);
    nameController.text = profile['ownerName']?.toString() ?? '';
    phoneController.text = profile['contactNumber']?.toString() ?? '';
  }

  Future<void> _saveProfile() async {
    final ApiSession session = ApiSession.instance;
    if (!session.isAuthenticated) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final Map<String, dynamic> profile = await GroundWaleApi.instance.updateOwnerProfile(
        session.ownerId!,
        <String, dynamic>{
          'ownerName': nameController.text.trim(),
          'contactNumber': phoneController.text.trim(),
        },
      );
      ApiSession.instance.updateFromAuth(profile);
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
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget field(String label, TextEditingController controller) {
      return TurfCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x30FFFFFF)),
                color: const Color(0x08FFFFFF),
              ),
              child: AppTextField(
                controller: controller,
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
          ],
        ),
      );
    }

    return TurfPageScaffold(
      title: 'Edit Profile',
      child: FutureBuilder<void>(
        future: _loadProfile(),
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFDDF730)));
          }

          return ListView(
            children: <Widget>[
              TurfCard(
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: const Color(0x2208B36A),
                      ),
                      child: const Icon(Icons.person_outline_rounded, size: 46, color: Color(0xFF08B36A)),
                    ),
                    const SizedBox(height: 10),
                    const Text('Tap to change photo', style: TextStyle(color: Colors.white60, fontSize: 16)),
                  ],
                ),
              ),
              field('Name', nameController),
              field('Phone Number', phoneController),
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
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF242424)))
                      : const Text('Save Changes'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


