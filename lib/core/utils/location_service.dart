import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Result of a reverse-geocoded device location.
///
/// [geocodingSucceeded] is `false` when GPS coordinates were obtained but
/// reverse-geocoding could not determine city/state (e.g. no network, system
/// geocoder unavailable). Callers should let users enter city/state manually.
class LocationResult {
  const LocationResult({
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    this.geocodingSucceeded = true,
  });

  final String city;
  final String state;
  final double latitude;
  final double longitude;

  /// `true` if city/state were successfully resolved from coordinates.
  /// `false` if the GPS fix succeeded but reverse-geocoding failed.
  final bool geocodingSucceeded;
}

/// Errors that can be returned when fetching the device location.
enum LocationError {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unknown,
}

class LocationServiceException implements Exception {
  const LocationServiceException(this.error, [this.message]);

  final LocationError error;
  final String? message;

  @override
  String toString() => message ?? error.name;
}

/// Fetches the current device location and reverse-geocodes it to city/state.
///
/// Strategy:
///  1. Try Android/iOS system geocoder (fast, offline-capable on some devices).
///  2. If that returns empty or throws, fall back to OpenStreetMap Nominatim
///     (network-based, works on all devices including emulators).
///  3. If both fail, return coordinates with [geocodingSucceeded] == false so
///     the caller can unlock fields for manual entry.
class LocationService {
  const LocationService._();

  static const String _nominatimUrl =
      'https://nominatim.openstreetmap.org/reverse';

  static Future<LocationResult> fetchCurrentLocation() async {
    // 1. Check that the location service is switched on.
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceException(
        LocationError.serviceDisabled,
        'Location services are disabled. Please enable them in device settings.',
      );
    }

    // 2. Check / request runtime permission.
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationServiceException(
        LocationError.permissionDenied,
        'Location permission denied.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        LocationError.permissionDeniedForever,
        'Location permission permanently denied. Please enable it in app settings.',
      );
    }

    // 3. Get current position.
    // LocationAccuracy.low uses cell/WiFi â€” fast and good enough for city-level.
    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
      ),
    );

    // 4a. Try system geocoder first.
    final LocationResult? systemResult =
        await _trySystemGeocoder(position.latitude, position.longitude);
    if (systemResult != null) return systemResult;

    // 4b. Fall back to OpenStreetMap Nominatim.
    final LocationResult? nominatimResult =
        await _tryNominatim(position.latitude, position.longitude);
    if (nominatimResult != null) return nominatimResult;

    // 4c. Both failed â€” return coordinates only so caller allows manual entry.
    return LocationResult(
      city: '',
      state: '',
      latitude: position.latitude,
      longitude: position.longitude,
      geocodingSucceeded: false,
    );
  }

  // â”€â”€ System geocoder â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<LocationResult?> _trySystemGeocoder(
    double lat,
    double lng,
  ) async {
    try {
      final List<Placemark> places =
          await placemarkFromCoordinates(lat, lng);
      if (places.isEmpty) return null;

      final Placemark p = places.first;
      // Android field mapping varies by device/OS version:
      //   locality              â†’ city (most reliable)
      //   subAdministrativeArea â†’ district / taluka
      //   subLocality           â†’ neighbourhood
      //   administrativeArea    â†’ state
      final String city = _firstNonEmpty([
        p.locality,
        p.subAdministrativeArea,
        p.subLocality,
        p.administrativeArea,
      ]);
      final String state = _firstNonEmpty([
        p.administrativeArea,
        p.subAdministrativeArea,
        p.country,
      ]);

      if (city.isEmpty && state.isEmpty) return null;

      return LocationResult(
        city: city,
        state: state,
        latitude: lat,
        longitude: lng,
      );
    } catch (_) {
      return null;
    }
  }

  // â”€â”€ Nominatim fallback â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<LocationResult?> _tryNominatim(
    double lat,
    double lng,
  ) async {
    try {
      final Dio dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: <String, String>{
          // Nominatim requires a valid User-Agent.
          'User-Agent': 'SportsNeoApp/1.0',
          'Accept-Language': 'en',
        },
      ));

      final Response<dynamic> response = await dio.get<dynamic>(
        _nominatimUrl,
        queryParameters: <String, dynamic>{
          'format': 'json',
          'lat': lat,
          'lon': lng,
          'zoom': 10, // city-level detail
          'addressdetails': 1,
        },
      );

      if (response.data == null) return null;
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(response.data as Map);
      final dynamic rawAddress = data['address'];
      if (rawAddress == null) return null;
      final Map<String, dynamic> address =
          Map<String, dynamic>.from(rawAddress as Map);

      // Nominatim address keys for Indian cities (in priority order):
      //   city / town / village / municipality â†’ city name
      //   state                                â†’ state name
      final String city = _firstNonEmpty([
        address['city']?.toString(),
        address['town']?.toString(),
        address['village']?.toString(),
        address['municipality']?.toString(),
        address['county']?.toString(),
        address['state_district']?.toString(),
      ]);
      final String state = _firstNonEmpty([
        address['state']?.toString(),
        address['state_district']?.toString(),
        address['country']?.toString(),
      ]);

      if (city.isEmpty && state.isEmpty) return null;

      return LocationResult(
        city: city,
        state: state,
        latitude: lat,
        longitude: lng,
      );
    } catch (_) {
      return null;
    }
  }

  // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Returns the first non-null, non-empty string from [values], or ''.
  static String _firstNonEmpty(List<String?> values) {
    for (final String? v in values) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }
}


/// Result of a reverse-geocoded device location.
///
/// [geocodingSucceeded] is `false` when GPS coordinates were obtained but
/// reverse-geocoding could not determine city/state (e.g. no network, system
