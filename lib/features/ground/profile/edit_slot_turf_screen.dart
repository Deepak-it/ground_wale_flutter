import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../../../core/api/ground_wale_api.dart';
import 'profile_turf_ui.dart';

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

  @override
  Widget build(BuildContext context) {
    Widget input(String label, TextEditingController controller) {
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
      title: 'Tap on Edit Slot',
      child: ListView(
        children: <Widget>[
          input('Start Time', startController),
          input('End Time', endController),
          input('Price', priceController),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              child: _isSaving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}


