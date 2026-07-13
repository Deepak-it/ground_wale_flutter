import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/neon_button.dart';
import '../controllers/ground_flow_controller.dart';

class GroundPhotosScreen extends StatefulWidget {
  const GroundPhotosScreen({super.key, required this.controller});

  final GroundFlowController controller;

  @override
  State<GroundPhotosScreen> createState() => _GroundPhotosScreenState();
}

class _GroundPhotosScreenState extends State<GroundPhotosScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isPicking = false;
  bool _isSubmitting = false;

  bool get _isAcademy => widget.controller.isAcademyFlow;

  Future<void> _onNext() async {
    // When in academy flow with ownership skipped, submit here before
    // jumping to the Under Review screen, since OwnershipVerificationScreen
    // (which normally calls submitGroundForVerification) is bypassed.
    if (widget.controller.isAcademyFlow &&
        widget.controller.skipOwnershipVerification) {
      setState(() => _isSubmitting = true);
      try {
        await widget.controller.submitGroundForVerification();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              error.toString().replaceFirst('Exception: ', ''),
            ),
          ));
        }
        return;
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
    widget.controller.nextStep();
  }

  String _mimeFromName(String name) {
    final String lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<void> _pickImages() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      final bool isDesktop = !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.linux ||
              defaultTargetPlatform == TargetPlatform.macOS);

      if (isDesktop) {
        // Desktop: pick multiple via file_picker
        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
          withData: true,
        );
        if (result == null || result.files.isEmpty) return;
        for (final PlatformFile file in result.files) {
          List<int> bytes = file.bytes ?? <int>[];
          if (bytes.isEmpty && file.path != null) {
            bytes = await XFile(file.path!).readAsBytes();
          }
          if (bytes.isEmpty) continue;
          if (bytes.length > 3 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${file.name} is too large (max 3 MB). Skipped.'),
              ));
            }
            continue;
          }
          final String mime = _mimeFromName(file.name);
          final String dataUri = 'data:$mime;base64,${base64Encode(bytes)}';
          widget.controller.data.groundImages.add(dataUri);
        }
      } else {
        // Mobile / web: pick multiple via image_picker
        final List<XFile> files = await _picker.pickMultiImage(
          imageQuality: 75,
          maxWidth: 1024,
        );
        for (final XFile file in files) {
          final List<int> bytes = await file.readAsBytes();
          if (bytes.isEmpty) continue;
          if (bytes.length > 3 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${file.name} is too large (max 3 MB). Skipped.'),
              ));
            }
            continue;
          }
          final String mime = file.mimeType ?? _mimeFromName(file.name);
          final String dataUri = 'data:$mime;base64,${base64Encode(bytes)}';
          widget.controller.data.groundImages.add(dataUri);
        }
      }

      widget.controller.update();
    } on PlatformException catch (e) {
      // MissingPluginException extends PlatformException; catches unregistered
      // plugin channels (e.g. before flutter clean + restart).
      final bool isMissingPlugin =
          e.runtimeType.toString().contains('MissingPlugin') ||
          (e.code == 'channel-error') ||
          e.message?.contains('No implementation found') == true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isMissingPlugin
            ? 'Image picker not ready. Stop the app, run flutter clean && flutter pub get, then restart.'
            : e.message ?? e.toString()),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ));
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _removeImage(int index) {
    widget.controller.data.groundImages.removeAt(index);
    widget.controller.update();
    setState(() {});
  }

  Widget _buildPreview(String dataUri) {
    try {
      final String raw = dataUri.contains(',')
          ? dataUri.split(',').last
          : dataUri;
      String normalized = raw.trim().replaceAll(RegExp(r'\s+'), '');
      normalized = normalized.replaceAll('-', '+').replaceAll('_', '/');
      final int rem = normalized.length % 4;
      if (rem != 0) normalized = normalized.padRight(normalized.length + (4 - rem), '=');
      return Image.memory(
        base64Decode(normalized),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.white54),
        ),
      );
    } catch (_) {
      return const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.white54),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> images = widget.controller.data.groundImages;
    final String title = _isAcademy ? 'Academy Photos' : 'Ground Photos';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            _isAcademy ? 'Step 5 of 6' : 'Step 3 of 5',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          const Text(
            'First photo will be shown as the cover image.',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          ),
          const SizedBox(height: 16),
          // Upload tile
          GestureDetector(
            onTap: _isPicking ? null : _pickImages,
            child: Container(
              width: double.infinity,
              height: images.isEmpty ? null : 100,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0x14FFFFFF),
                border: Border.all(
                  color: const Color(0x66DDF730),
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _isPicking
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFDDF730),
                          ),
                        )
                      : const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 36,
                          color: Color(0xFFDDF730),
                        ),
                  const SizedBox(height: 8),
                  Text(
                    images.isEmpty
                        ? 'Tap to add photos'
                        : 'Add more photos (${images.length} added)',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Grid preview
          if (images.isNotEmpty)
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: images.length,
                itemBuilder: (BuildContext context, int index) {
                  final bool isCover = index == 0;
                  return Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _buildPreview(images[index]),
                      ),
                      if (isCover)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: const Color(0xFFDDF730),
                            ),
                            child: const Text(
                              'Cover',
                              style: TextStyle(
                                color: Color(0xFF1D1D1D),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Color(0xCCE3220D),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            )
          else
            const Spacer(),
          const SizedBox(height: 12),
          NeonButton(
            label: 'Next',
            onPressed: _isSubmitting ? () {} : _onNext,
          ),
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(
                color: Color(0xFFDDF730),
                backgroundColor: Color(0x33242424),
              ),
            ),
          const SizedBox(height: 10),
          NeonButton(
            label: 'Skip for Now',
            outline: true,
            onPressed: _isSubmitting ? () {} : _onNext,
          ),
        ],
      ),
    );
  }
}
