import 'package:flutter/material.dart';

import '../../../core/api/ground_wale_api.dart';
import 'profile_turf_ui.dart';
import 'terms_policy_secondary_turf_screen.dart';

class TermsPolicyTurfScreen extends StatelessWidget {
  const TermsPolicyTurfScreen({super.key});

  Future<Map<String, dynamic>> _loadTerms() {
    return GroundWaleApi.instance.getTerms();
  }

  @override
  Widget build(BuildContext context) {
    return TurfPageScaffold(
      title: 'Tap on Term & Policy',
      child: FutureBuilder<Map<String, dynamic>>(
        future: _loadTerms(),
        builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          final List<dynamic> sections = snapshot.data?['sections'] as List<dynamic>? ?? <dynamic>[];
          return ListView(
            children: <Widget>[
              TurfCard(
                child: Text(
                  sections.isEmpty ? 'No terms available.' : sections.map((dynamic item) => item.toString()).join('\n\n'),
                  style: const TextStyle(color: Colors.white70, height: 1.5),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TermsPolicySecondaryTurfScreen())),
                child: const Text('Open second Term & Policy state'),
              ),
            ],
          );
        },
      ),
    );
  }
}
