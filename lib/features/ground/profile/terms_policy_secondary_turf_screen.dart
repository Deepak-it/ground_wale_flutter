import 'package:flutter/material.dart';

import '../../../core/api/ground_wale_api.dart';
import 'profile_turf_ui.dart';

class TermsPolicySecondaryTurfScreen extends StatelessWidget {
  const TermsPolicySecondaryTurfScreen({super.key});

  Future<Map<String, dynamic>> _loadPrivacy() {
    return GroundWaleApi.instance.getPrivacy();
  }

  @override
  Widget build(BuildContext context) {
    return TurfPageScaffold(
      title: 'Tap on Term & Policy',
      subtitle: 'Secondary state (frame 2035:659)',
      child: FutureBuilder<Map<String, dynamic>>(
        future: _loadPrivacy(),
        builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          final List<dynamic> sections = snapshot.data?['sections'] as List<dynamic>? ?? <dynamic>[];
          return TurfCard(
            child: Text(
              sections.isEmpty ? 'Privacy policy unavailable.' : sections.map((dynamic item) => item.toString()).join('\n\n'),
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
          );
        },
      ),
    );
  }
}
