class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'GROUND_WALE_API_BASE_URL',
    defaultValue: 'http://localhost:4000/api/v1',
  );
}