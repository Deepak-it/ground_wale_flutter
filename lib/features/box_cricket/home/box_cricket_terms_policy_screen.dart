import 'package:flutter/material.dart';

import '../../../core/api/ground_wale_api.dart';

class BoxCricketTermsPolicyScreen extends StatefulWidget {
  const BoxCricketTermsPolicyScreen({super.key});

  @override
  State<BoxCricketTermsPolicyScreen> createState() =>
      _BoxCricketTermsPolicyScreenState();
}

class _BoxCricketTermsPolicyScreenState
    extends State<BoxCricketTermsPolicyScreen> {
  bool _isTermsSelected = true;
  bool _isLoading = true;
  String _termsText = '';
  String _privacyText = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _toBodyText(Map<String, dynamic> payload) {
    final dynamic sections = payload['sections'];
    if (sections is List<dynamic> && sections.isNotEmpty) {
      return sections.map((dynamic item) => item.toString()).join('\n\n');
    }
    if (payload['content'] is String) {
      return payload['content'].toString();
    }
    if (payload['text'] is String) {
      return payload['text'].toString();
    }
    return '';
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final List<Map<String, dynamic>> data =
          await Future.wait<Map<String, dynamic>>(
            <Future<Map<String, dynamic>>>[
              GroundWaleApi.instance.getTerms(),
              GroundWaleApi.instance.getPrivacy(),
            ],
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _termsText = _toBodyText(data[0]);
        _privacyText = _toBodyText(data[1]);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String body = _isTermsSelected
        ? (_termsText.isEmpty ? 'No terms available.' : _termsText)
        : (_privacyText.isEmpty ? 'Privacy policy unavailable.' : _privacyText);

    return Scaffold(
      backgroundColor: const Color(0xFF1B1F1B),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF08B36A)),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFFDDF730),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Term & Policy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            setState(() => _isTermsSelected = true);
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: _isTermsSelected
                                  ? const Color(0xFF08B36A)
                                  : const Color(0x08FFFFFF),
                              borderRadius: BorderRadius.circular(8),
                              border: _isTermsSelected
                                  ? null
                                  : Border.all(color: const Color(0x1FFFFFFF)),
                            ),
                            child: const Center(
                              child: Text(
                                'Term of Service',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            setState(() => _isTermsSelected = false);
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: !_isTermsSelected
                                  ? const Color(0xFF08B36A)
                                  : const Color(0x08FFFFFF),
                              borderRadius: BorderRadius.circular(8),
                              border: !_isTermsSelected
                                  ? null
                                  : Border.all(color: const Color(0x1FFFFFFF)),
                            ),
                            child: const Center(
                              child: Text(
                                'Privacy Policy',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x1FFFFFFF)),
                    ),
                    child: Text(
                      body,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
