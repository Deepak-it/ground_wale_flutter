import 'package:dio/dio.dart';

Future<void> main() async {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:4000/api/v1',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: <String, String>{'Content-Type': 'application/json'},
    ),
  );

  final Stopwatch stopwatch = Stopwatch()..start();
  try {
    final Response<dynamic> response = await dio.get<dynamic>(
      '/academy/6a4ec14745eae11d4e271424/academies',
    );
    stopwatch.stop();
    final List<dynamic> data = response.data as List<dynamic>;
    final Map<String, dynamic> first = data.isNotEmpty
        ? Map<String, dynamic>.from(data.first as Map)
        : <String, dynamic>{};
    print(
      'status=${response.statusCode} ms=${stopwatch.elapsedMilliseconds} count=${data.length} hasImage=${first.containsKey('image')} imageLen=${(first['image']?.toString() ?? '').length}',
    );
  } catch (error, stackTrace) {
    stopwatch.stop();
    print('ERR ms=${stopwatch.elapsedMilliseconds}');
    print(error);
    print(stackTrace);
  }
}
