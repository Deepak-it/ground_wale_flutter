class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'GROUND_WALE_API_BASE_URL',
    // defaultValue: 'https://h0xz1rwore.execute-api.ap-south-1.amazonaws.com/default/centific-cric/api/v1',
    defaultValue: 'http://localhost:4000/api/v1',

  );
}