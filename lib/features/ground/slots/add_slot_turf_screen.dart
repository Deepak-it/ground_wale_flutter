import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';

class AddSlotTurfScreen extends StatefulWidget {
  const AddSlotTurfScreen({super.key});

  @override
  State<AddSlotTurfScreen> createState() => _AddSlotTurfScreenState();
}

class _AddSlotTurfScreenState extends State<AddSlotTurfScreen> {
  String selectedDay = 'Tue';
  final TextEditingController startController = TextEditingController(text: '09:00 AM');
  final TextEditingController endController = TextEditingController(text: '12:00 PM');
  final TextEditingController priceController = TextEditingController(text: '2000');
  bool _isSaving = false;

  @override
  void dispose() {
    startController.dispose();
    endController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Future<void> _saveSlot() async {
    final ApiSession session = ApiSession.instance;
    if (!session.hasGround) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No ground found for this account')));
      return;
    }

    final double? price = double.tryParse(priceController.text.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid price')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final DateTime date = DateTime.now().add(Duration(days: <String, int>{'Mon': 0, 'Tue': 1, 'Wed': 2, 'Thu': 3, 'Cal': 0}[selectedDay] ?? 0));
      await GroundWaleApi.instance.createSlot(
        session.groundId!,
        <String, dynamic>{
          'day': selectedDay,
          'date': DateTime(date.year, date.month, date.day).toIso8601String(),
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

  Widget dayTile(String day, String date, {bool calendar = false}) {
    final bool selected = selectedDay == day;
    return InkWell(
      onTap: () => setState(() => selectedDay = day),
      child: Container(
        width: 74,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFDDF730) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? const Color(0x33242424) : const Color(0x40FFFFFF)),
        ),
        child: calendar
            ? const Icon(Icons.calendar_month_outlined, color: Colors.white)
            : Column(
                children: <Widget>[
                  Text(day, style: TextStyle(color: selected ? const Color(0xFF242424) : Colors.white)),
                  const SizedBox(height: 6),
                  Text(date, style: TextStyle(color: selected ? const Color(0xFF242424) : Colors.white, fontWeight: FontWeight.w600, fontSize: 20)),
                ],
              ),
      ),
    );
  }

  Widget field(String label, TextEditingController controller, {IconData? icon}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x40FFFFFF)),
              color: const Color(0x14FFFFFF),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: AppTextField(
                    controller: controller,
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
                if (icon != null) Icon(icon, color: Colors.white70, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1F1B),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  ),
                  const Expanded(child: Text('Add Slot', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500))),
                  Container(
                    decoration: BoxDecoration(color: const Color(0x22DDF730), borderRadius: BorderRadius.circular(14)),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.add, color: Color(0xFFDDF730)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Create New Availability', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Define a new booking window for your clients.', style: TextStyle(color: Colors.white70, fontSize: 18)),
              const SizedBox(height: 18),
              const Text('Select Date', style: TextStyle(fontSize: 19)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    dayTile('Cal', '', calendar: true),
                    const SizedBox(width: 10),
                    dayTile('Mon', '12'),
                    const SizedBox(width: 10),
                    dayTile('Tue', '13'),
                    const SizedBox(width: 10),
                    dayTile('Wed', '14'),
                    const SizedBox(width: 10),
                    dayTile('Thu', '15'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0x10FFFFFF),
                  border: Border.all(color: const Color(0x30FFFFFF)),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Row(children: <Widget>[field('Start Time', startController, icon: Icons.access_time), const SizedBox(width: 12), field('End Time', endController, icon: Icons.access_time)]),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0x10FFFFFF),
                  border: Border.all(color: const Color(0x30FFFFFF)),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Row(children: <Widget>[field('Price', priceController)]),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDDF730),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isSaving ? null : _saveSlot,
                  child: _isSaving
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF242424)))
                      : const Text('Add New Slot', style: TextStyle(color: Color(0xFF242424), fontSize: 19, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


