import 'package:cashfree_pg/cashfree_pg.dart';

class CashfreeCheckout {
  static Future<void> payWithToken(
    Map<String, dynamic> token, {
    required String fallbackPhone,
    String fallbackName = 'Sports Neo User',
    String fallbackEmail = 'customer@sportsneo.app',
    String fallbackOrderNote = 'Payment via Sports Neo',
    String color1 = '#08B36A',
    String color2 = '#1C333B',
  }) async {
    final Map<String, dynamic> checkoutInput = <String, dynamic>{
      'stage': token['stage']?.toString() ?? 'TEST',
      'appId': token['appId']?.toString() ?? '',
      'orderId': token['orderId']?.toString() ?? '',
      'orderAmount': '${token['orderAmount']}',
      'orderCurrency': token['orderCurrency']?.toString() ?? 'INR',
      'customerName': token['customerName']?.toString() ?? fallbackName,
      'customerPhone': token['customerPhone']?.toString() ?? fallbackPhone,
      'customerEmail': token['customerEmail']?.toString() ?? fallbackEmail,
      'orderNote': token['orderNote']?.toString() ?? fallbackOrderNote,
      'tokenData': token['tokenData']?.toString() ?? '',
      'color1': color1,
      'color2': color2,
      if ((token['notifyUrl']?.toString() ?? '').isNotEmpty)
        'notifyUrl': token['notifyUrl']?.toString() ?? '',
    };

    final Map<dynamic, dynamic>? response = await CashfreePGSDK.doPayment(
      checkoutInput,
    );

    if (response == null) {
      throw Exception('Cashfree payment did not return any response');
    }

    final String txStatus =
        response['txStatus']?.toString().toUpperCase() ?? 'FAILED';

    if (txStatus != 'SUCCESS') {
      final String message =
          response['txMsg']?.toString() ?? 'Payment failed or cancelled';
      throw Exception(message);
    }
  }
}
