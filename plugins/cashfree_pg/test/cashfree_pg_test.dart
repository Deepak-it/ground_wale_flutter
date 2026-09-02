import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// import 'package:cashfree_pg/cashfree_pg.dart';

void main() {
  const MethodChannel channel = MethodChannel('cashfree_pg');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  // test('getPlatformVersion', () async {
  //   expect(await CashfreePg.platformVersion, '42');
  // });
}
