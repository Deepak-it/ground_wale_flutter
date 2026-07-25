// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/neon_button.dart';
import '../controllers/ground_flow_controller.dart';

/// [controller.data.ownershipProof] stores a base64 data-URI:
///   "data:image/jpeg;base64,..."  or  "data:application/pdf;base64,..."
/// Sent to the backend via [controller.submitGroundForVerification()].

class OwnershipVerificationScreen extends StatefulWidget {
  const OwnershipVerificationScreen({super.key, required this.controller});

  final GroundFlowController controller;

  @override
  State<OwnershipVerificationScreen> createState() =>
      _OwnershipVerificationScreenState();
}

class _OwnershipVerificationScreenState
    extends State<OwnershipVerificationScreen> {
  static const int _maxBytes = 5 * 1024 * 1024; // 5 MB

  bool _isPicking = false;
  String? _pickedFileName;
  bool _pickedIsImage = false;

  bool get _hasProof => widget.controller.data.ownershipProof.isNotEmpty;

  String _mimeFromName(String name) {
    final String lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'image/jpeg';
  }

  Future<void> _pickSource() async {
    final String? choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1D1D1D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: const Color(0x33FFFFFF),
                ),
              ),
              const SizedBox(height: 16),
              _SheetTile(
                icon: Icons.camera_alt_outlined,
                label: 'Take Photo (Camera)',
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              _SheetTile(
                icon: Icons.image_outlined,
                label: 'Choose Image from Gallery',
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              _SheetTile(
                icon: Icons.picture_as_pdf_outlined,
                label: 'Upload PDF Document',
                onTap: () => Navigator.pop(ctx, 'pdf'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
    if (choice == null || !mounted) return;
    setState(() => _isPicking = true);
    try {
      await _handle(choice);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _handle(String choice) async {
    final bool isDesktop =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS);

    if (choice == 'pdf') {
      await _pickPdf();
      return;
    }

    if (choice == 'camera' && !isDesktop) {
      await _pickCamera();
      return;
    }

    // gallery (or camera fallback on desktop)
    if (isDesktop) {
      await _pickDesktopImage();
    } else {
      await _pickMobileImage();
    }
  }

  Future<void> _pickCamera() async {
    try {
      final XFile? file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (file == null || !mounted) return;
      final Uint8List bytes = await file.readAsBytes();
      _validate(bytes);
      _store(
        bytes,
        file.mimeType ?? _mimeFromName(file.name),
        file.name,
        isImage: true,
      );
    } on MissingPluginException {
      throw Exception('Camera not available. Use Gallery instead.');
    }
  }

  Future<void> _pickMobileImage() async {
    final XFile? file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (file == null || !mounted) return;
    final Uint8List bytes = await file.readAsBytes();
    _validate(bytes);
    _store(
      bytes,
      file.mimeType ?? _mimeFromName(file.name),
      file.name,
      isImage: true,
    );
  }

  Future<void> _pickDesktopImage() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty || !mounted) return;
      final PlatformFile f = result.files.first;
      List<int> bytes = f.bytes ?? <int>[];
      if (bytes.isEmpty && f.path != null) {
        bytes = await XFile(f.path!).readAsBytes();
      }
      _validate(Uint8List.fromList(bytes));
      _store(
        Uint8List.fromList(bytes),
        _mimeFromName(f.name),
        f.name,
        isImage: true,
      );
    } on MissingPluginException {
      await _pickMobileImage();
    }
  }

  Future<void> _pickPdf() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty || !mounted) return;
      final PlatformFile f = result.files.first;
      List<int> bytes = f.bytes ?? <int>[];
      if (bytes.isEmpty && f.path != null) {
        bytes = await XFile(f.path!).readAsBytes();
      }
      _validate(Uint8List.fromList(bytes));
      _store(
        Uint8List.fromList(bytes),
        'application/pdf',
        f.name,
        isImage: false,
      );
    } on MissingPluginException {
      throw Exception('PDF picker not available on this platform.');
    }
  }

  void _validate(Uint8List bytes) {
    if (bytes.isEmpty) throw Exception('File has no readable bytes.');
    if (bytes.length > _maxBytes) {
      throw Exception('File too large (max 5 MB).');
    }
  }

  void _store(
    Uint8List bytes,
    String mime,
    String name, {
    required bool isImage,
  }) {
    final String dataUri = 'data:$mime;base64,${base64Encode(bytes)}';
    setState(() {
      widget.controller.data.ownershipProof = dataUri;
      _pickedFileName = name;
      _pickedIsImage = isImage;
    });
    widget.controller.update();
  }

  void _clearProof() {
    setState(() {
      widget.controller.data.ownershipProof = '';
      _pickedFileName = null;
      _pickedIsImage = false;
    });
    widget.controller.update();
  }

  Widget _buildPreview() {
    if (_pickedIsImage) {
      try {
        final String raw = widget.controller.data.ownershipProof;
        final String b64 = raw.contains(',') ? raw.split(',').last : raw;
        String norm = b64.trim().replaceAll(RegExp(r'\s+'), '');
        norm = norm.replaceAll('-', '+').replaceAll('_', '/');
        final int rem = norm.length % 4;
        if (rem != 0) norm = norm.padRight(norm.length + (4 - rem), '=');
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            base64Decode(norm),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stack) => _pdfPlaceholder(),
          ),
        );
      } catch (_) {
        return _pdfPlaceholder();
      }
    }
    return _pdfPlaceholder();
  }

  Widget _pdfPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0x14FFFFFF),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            _pickedIsImage
                ? Icons.broken_image_outlined
                : Icons.picture_as_pdf_outlined,
            size: 52,
            color: const Color(0xFFDDF730),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _pickedFileName ?? 'document.pdf',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool academyFlow = widget.controller.isAcademyFlow;
    final String entity = academyFlow ? 'Academy' : 'Ground';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Ownership Verification',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload a photo or PDF of your rent agreement or ownership deed.',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _hasProof
                ? Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      _buildPreview(),
                      // Action buttons overlay
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Row(
                          children: <Widget>[
                            _OverlayAction(
                              icon: Icons.edit_outlined,
                              onTap: _isPicking ? null : _pickSource,
                            ),
                            const SizedBox(width: 8),
                            _OverlayAction(
                              icon: Icons.delete_outline,
                              color: Colors.redAccent,
                              onTap: _clearProof,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: const Color(0xFFDDF730),
                          ),
                          child: Text(
                            _pickedIsImage ? 'Image Proof' : 'PDF Proof',
                            style: const TextStyle(
                              color: Color(0xFF1D1D1D),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: _isPicking ? null : _pickSource,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0x14FFFFFF),
                        border: Border.all(
                          color: const Color(0x66DDF730),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          _isPicking
                              ? const SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFDDF730),
                                  ),
                                )
                              : const Icon(
                                  Icons.upload_file_outlined,
                                  size: 52,
                                  color: Color(0xFFDDF730),
                                ),
                          const SizedBox(height: 12),
                          const Text(
                            'Upload Ownership Proof',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Camera  ·  Gallery image  ·  PDF',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Rent agreement, property deed, etc.',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          NeonButton(
            label: 'Submit $entity for Verification',
            onPressed: _hasProof && !widget.controller.isBusy
                ? () async {
                    try {
                      await widget.controller.submitGroundForVerification();
                      widget.controller.nextStep();
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              error.toString().replaceFirst('Exception: ', ''),
                            ),
                          ),
                        );
                      }
                    }
                  }
                : null,
          ),
          if (widget.controller.isBusy)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(
                color: Color(0xFFDDF730),
                backgroundColor: Color(0x33242424),
              ),
            ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '$entity verification takes up to 2 hours',
              style: const TextStyle(color: Color(0xFFDDF730)),
            ),
          ),
          if (widget.controller.errorMessage != null) ...<Widget>[
            const SizedBox(height: 8),
            Center(
              child: Text(
                widget.controller.errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFDDF730)),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}

class _OverlayAction extends StatelessWidget {
  const _OverlayAction({required this.icon, this.onTap, this.color});

  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xCC1D1D1D),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: color ?? Colors.white, size: 18),
      ),
    );
  }
}
