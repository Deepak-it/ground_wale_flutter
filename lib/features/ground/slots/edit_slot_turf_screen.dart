import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../../../core/api/ground_wale_api.dart';

class EditSlotTurfScreen extends StatefulWidget {
  const EditSlotTurfScreen({super.key, required this.slot});

  final Map<String, dynamic> slot;

  @override
  State<EditSlotTurfScreen> createState() => _EditSlotTurfScreenState();
}

class _EditSlotTurfScreenState extends State<EditSlotTurfScreen> {
  late final TextEditingController startController;
  late final TextEditingController endController;
  late final TextEditingController priceController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    startController = TextEditingController(text: widget.slot['startTime']?.toString() ?? '06:00');
    endController = TextEditingController(text: widget.slot['endTime']?.toString() ?? '07:00');
    priceController = TextEditingController(text: (widget.slot['price'] ?? 800).toString());
  }

  @override
  void dispose() {
    startController.dispose();
    endController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final double? price = double.tryParse(priceController.text.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid price')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await GroundWaleApi.instance.updateSlot(
        widget.slot['_id']?.toString() ?? '',
        <String, dynamic>{
          'startTime': startController.text.trim(),
          'endTime': endController.text.trim(),
          'price': price,
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

  Widget field(String label, TextEditingController controller) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x1F242424)),
          color: const Color(0x0A242424),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: const TextStyle(color: Color(0x99242424))),
            const SizedBox(height: 8),
            AppTextField(
              controller: controller,
              style: const TextStyle(color: Color(0xFF242424), fontSize: 20, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x991B1F1B),
      body: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Center(child: SizedBox(width: 90, child: Divider(thickness: 5))),
                const SizedBox(height: 12),
                const Text('Edit Slot', style: TextStyle(color: Color(0xFF242424), fontSize: 23, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Row(children: <Widget>[field('Start Time', startController), const SizedBox(width: 12), field('End Time', endController)]),
                const SizedBox(height: 12),
                Row(children: <Widget>[field('Price', priceController)]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C333B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isSaving ? null : _saveChanges,
                    child: _isSaving
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


