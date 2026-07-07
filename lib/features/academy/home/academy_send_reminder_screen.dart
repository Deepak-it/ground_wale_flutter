import 'package:flutter/material.dart';

class AcademySendReminderScreen extends StatefulWidget {
  const AcademySendReminderScreen({super.key, this.feeId});

  final String? feeId;

  @override
  State<AcademySendReminderScreen> createState() =>
      _AcademySendReminderScreenState();
}

class _AcademySendReminderScreenState extends State<AcademySendReminderScreen> {
  String _channel = 'WhatsApp';
  bool _isSending = false;

  Future<void> _sendReminder() async {
    final String? feeId = widget.feeId;
    if (feeId == null || feeId.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSending = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reminder sent via $_channel')));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x99242424),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Send Reminder',
                          style: TextStyle(
                            color: Color(0xFF313638),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF242424),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _channelOption('WhatsApp', Icons.chat_bubble_outline_rounded),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _channelOption('SMS', Icons.sms_outlined)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _sendReminder,
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send Reminder'),
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

  Widget _channelOption(String label, IconData icon) {
    final bool selected = _channel == label;
    return InkWell(
      onTap: () => setState(() => _channel = label),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF00C9A7) : const Color(0x1F242424),
          ),
          color: Colors.white,
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 36, color: const Color(0xFF242424)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Color(0xFF242424))),
          ],
        ),
      ),
    );
  }
}
