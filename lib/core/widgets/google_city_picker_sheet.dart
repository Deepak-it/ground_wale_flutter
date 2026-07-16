import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class GoogleCitySelection {
  const GoogleCitySelection({
    required this.city,
    required this.state,
    required this.label,
  });

  final String city;
  final String state;
  final String label;

  bool get isEmpty => city.isEmpty && state.isEmpty;
}

class _GoogleCitySuggestion {
  const _GoogleCitySuggestion({
    required this.label,
    this.placeId,
    this.city,
    this.state,
    this.secondaryText = '',
    this.isClear = false,
  });

  final String label;
  final String? placeId;
  final String? city;
  final String? state;
  final String secondaryText;
  final bool isClear;
}

class _GooglePlacesService {
  static const String _apiKey = String.fromEnvironment('GOOGLE_PLACES_API_KEY');
  static const String _autocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const String _detailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';
  static const String _fallbackUrl =
      'https://nominatim.openstreetmap.org/search';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: <String, String>{
        'User-Agent': 'SportsNeoApp/1.0',
        'Accept-Language': 'en',
      },
    ),
  );

  bool get hasGoogleApiKey => _apiKey.trim().isNotEmpty;

  Future<List<_GoogleCitySuggestion>> searchCities(String query) async {
    final String trimmedQuery = query.trim();
    if (trimmedQuery.length < 2) {
      return <_GoogleCitySuggestion>[];
    }

    if (hasGoogleApiKey) {
      final List<_GoogleCitySuggestion> googleResults =
          await _searchGoogleCities(trimmedQuery);
      if (googleResults.isNotEmpty) {
        return googleResults;
      }
    }

    return _searchFallbackCities(trimmedQuery);
  }

  Future<GoogleCitySelection?> resolveSuggestion(
    _GoogleCitySuggestion suggestion,
  ) async {
    if (suggestion.isClear) {
      return const GoogleCitySelection(city: '', state: '', label: '');
    }

    if ((suggestion.city ?? '').isNotEmpty) {
      final String city = suggestion.city!.trim();
      final String state = (suggestion.state ?? '').trim();
      return GoogleCitySelection(
        city: city,
        state: state,
        label: state.isEmpty ? city : '$city, $state',
      );
    }

    if (!hasGoogleApiKey || suggestion.placeId == null) {
      return null;
    }

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        _detailsUrl,
        queryParameters: <String, dynamic>{
          'place_id': suggestion.placeId,
          'fields': 'address_component,name,formatted_address',
          'key': _apiKey,
        },
      );
      if (response.data is! Map) {
        return null;
      }
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(response.data as Map);
      if (data['status']?.toString() != 'OK') {
        return null;
      }
      final Map<String, dynamic> result =
          Map<String, dynamic>.from(data['result'] as Map);
      final List<dynamic> components =
          result['address_components'] as List<dynamic>? ?? const <dynamic>[];

      String city = '';
      String state = '';
      for (final dynamic component in components) {
        if (component is! Map) {
          continue;
        }
        final Map<String, dynamic> item = Map<String, dynamic>.from(component);
        final List<String> types = (item['types'] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic value) => value.toString())
            .toList();
        final String longName = item['long_name']?.toString().trim() ?? '';
        if (longName.isEmpty) {
          continue;
        }
        if (city.isEmpty &&
            (types.contains('locality') ||
                types.contains('administrative_area_level_3') ||
                types.contains('administrative_area_level_2'))) {
          city = longName;
        }
        if (state.isEmpty && types.contains('administrative_area_level_1')) {
          state = longName;
        }
      }

      if (city.isEmpty) {
        city = result['name']?.toString().trim() ?? '';
      }
      if (city.isEmpty) {
        return null;
      }

      return GoogleCitySelection(
        city: city,
        state: state,
        label: state.isEmpty ? city : '$city, $state',
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<_GoogleCitySuggestion>> _searchGoogleCities(String query) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        _autocompleteUrl,
        queryParameters: <String, dynamic>{
          'input': '$query, India',
          'types': '(cities)',
          'components': 'country:in',
          'key': _apiKey,
        },
      );
      if (response.data is! Map) {
        return <_GoogleCitySuggestion>[];
      }
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(response.data as Map);
      if (data['status']?.toString() != 'OK') {
        return <_GoogleCitySuggestion>[];
      }
      final List<dynamic> predictions =
          data['predictions'] as List<dynamic>? ?? const <dynamic>[];
      return predictions
          .whereType<Map>()
          .map((Map item) {
            final Map<String, dynamic> map = Map<String, dynamic>.from(item);
            final Map<String, dynamic> formatting =
                map['structured_formatting'] is Map<String, dynamic>
                ? Map<String, dynamic>.from(
                    map['structured_formatting'] as Map<String, dynamic>,
                  )
                : map['structured_formatting'] is Map
                ? Map<String, dynamic>.from(map['structured_formatting'] as Map)
                : <String, dynamic>{};
            return _GoogleCitySuggestion(
              label: formatting['main_text']?.toString().trim().isNotEmpty == true
                  ? formatting['main_text'].toString().trim()
                  : map['description']?.toString().trim() ?? '',
              secondaryText:
                  formatting['secondary_text']?.toString().trim() ?? '',
              placeId: map['place_id']?.toString(),
            );
          })
          .where((_GoogleCitySuggestion item) => item.label.isNotEmpty)
          .take(8)
          .toList();
    } catch (_) {
      return <_GoogleCitySuggestion>[];
    }
  }

  Future<List<_GoogleCitySuggestion>> _searchFallbackCities(String query) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        _fallbackUrl,
        queryParameters: <String, dynamic>{
          'q': '$query, India',
          'format': 'jsonv2',
          'addressdetails': 1,
          'countrycodes': 'in',
          'limit': 8,
        },
      );
      if (response.data is! List) {
        return <_GoogleCitySuggestion>[];
      }

      final Set<String> seen = <String>{};
      final List<_GoogleCitySuggestion> results = <_GoogleCitySuggestion>[];
      for (final dynamic item in response.data as List<dynamic>) {
        if (item is! Map) {
          continue;
        }
        final Map<String, dynamic> data = Map<String, dynamic>.from(item);
        final Map<String, dynamic> address =
            data['address'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['address'] as Map<String, dynamic>)
            : data['address'] is Map
            ? Map<String, dynamic>.from(data['address'] as Map)
            : <String, dynamic>{};
        final String city = _firstNonEmpty(<String?>[
          address['city']?.toString(),
          address['town']?.toString(),
          address['municipality']?.toString(),
          address['village']?.toString(),
          address['state_district']?.toString(),
        ]);
        if (city.isEmpty) {
          continue;
        }
        final String state = _firstNonEmpty(<String?>[
          address['state']?.toString(),
          address['state_district']?.toString(),
        ]);
        final String label = state.isEmpty ? city : '$city, $state';
        if (!seen.add(label.toLowerCase())) {
          continue;
        }
        results.add(
          _GoogleCitySuggestion(
            label: city,
            city: city,
            state: state,
            secondaryText: state,
          ),
        );
      }
      return results;
    } catch (_) {
      return <_GoogleCitySuggestion>[];
    }
  }

  String _firstNonEmpty(List<String?> values) {
    for (final String? value in values) {
      final String text = value?.trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }
}

Future<GoogleCitySelection?> showGoogleCityPickerSheet({
  required BuildContext context,
  String title = 'Select City',
  String initialQuery = '',
  bool allowClear = false,
}) async {
  final _GooglePlacesService service = _GooglePlacesService();
  final TextEditingController cityController =
      TextEditingController(text: initialQuery);
  final List<_GoogleCitySuggestion> suggestions = <_GoogleCitySuggestion>[];
  bool searching = false;
  int requestToken = 0;

  Future<void> search(
    String query,
    StateSetter sheetSet,
    BuildContext sheetContext,
  ) async {
    final int currentToken = ++requestToken;
    final String trimmedQuery = query.trim();
    if (trimmedQuery.length < 2) {
      if (!sheetContext.mounted) {
        return;
      }
      sheetSet(() {
        suggestions.clear();
        searching = false;
      });
      return;
    }

    sheetSet(() => searching = true);
    final List<_GoogleCitySuggestion> results = await service.searchCities(
      trimmedQuery,
    );
    if (!sheetContext.mounted || currentToken != requestToken) {
      return;
    }
    sheetSet(() {
      suggestions
        ..clear()
        ..addAll(results);
      searching = false;
    });
  }

  try {
    final _GoogleCitySuggestion? picked =
        await showModalBottomSheet<_GoogleCitySuggestion>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext innerContext, StateSetter sheetSet) {
            return Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(innerContext).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF121C3E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0x40FFFFFF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'City',
                    style: TextStyle(
                      color: Color(0xCCFFFFFF),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x3DFFFFFF)),
                      color: const Color(0x0AFFFFFF),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.location_city_outlined,
                          color: Color(0x99FFFFFF),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: cityController,
                            onChanged: (String value) =>
                                search(value, sheetSet, innerContext),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Search city',
                              hintStyle: TextStyle(color: Color(0x66FFFFFF)),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!service.hasGoogleApiKey) ...<Widget>[
                    const SizedBox(height: 10),
                    const Text(
                      'Google Places API key not configured. Showing fallback city results.',
                      style: TextStyle(
                        color: Color(0xB3FFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                  if (allowClear) ...<Widget>[
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => Navigator.of(innerContext).pop(
                        const _GoogleCitySuggestion(
                          label: 'Show all cities',
                          isClear: true,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0x0AFFFFFF),
                          border: Border.all(color: const Color(0x1FFFFFFF)),
                        ),
                        child: const Text(
                          'Show all cities',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (searching)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    )
                  else if (cityController.text.trim().length >= 2 &&
                      suggestions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No matching cities found',
                        style: TextStyle(
                          color: Color(0xB3FFFFFF),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else if (suggestions.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: suggestions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (BuildContext context, int index) {
                          final _GoogleCitySuggestion suggestion =
                              suggestions[index];
                          return InkWell(
                            onTap: () => Navigator.of(innerContext).pop(
                              suggestion,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: const Color(0x0AFFFFFF),
                                border: Border.all(
                                  color: const Color(0x1FFFFFFF),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    suggestion.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (suggestion.secondaryText.isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 2),
                                    Text(
                                      suggestion.secondaryText,
                                      style: const TextStyle(
                                        color: Color(0xB3FFFFFF),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );

    if (picked == null) {
      return null;
    }
    return service.resolveSuggestion(picked);
  } finally {
    cityController.dispose();
  }
}