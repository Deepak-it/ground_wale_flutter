import 'package:flutter/material.dart';

import '../../../core/api/ground_wale_api.dart';

class DeleteSlotTurfScreen extends StatelessWidget {
  const DeleteSlotTurfScreen({super.key, required this.slotId});

  final String slotId;

  Future<void> _delete(BuildContext context) async {
    try {
      await GroundWaleApi.instance.deleteSlot(slotId);
      if (context.mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x991B1F1B),
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.delete_outline, color: Color(0xFFE3220D), size: 30),
                const SizedBox(height: 12),
                const Text('Delete Slot?', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600, color: Color(0xFF242424))),
                const SizedBox(height: 8),
                const Text('This action cannot be undone.', style: TextStyle(color: Color(0x99242424))),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF08B36A),
                          side: const BorderSide(color: Color(0x3308B36A)),
                          backgroundColor: const Color(0x2208B36A),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE3220D),
                          side: const BorderSide(color: Color(0x33E3220D)),
                          backgroundColor: const Color(0x22E3220D),
                        ),
                        onPressed: () => _delete(context),
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
