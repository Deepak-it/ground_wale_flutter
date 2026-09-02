import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CashfreePGSDK {

  static List<String> _required = [
    "stage",
    "appId",
    "orderId",
    "orderAmount",
    "orderCurrency",
    "customerEmail",
    "customerPhone",
    "tokenData"
  ];

  /// Function to initiate the web checkout flow.
  static Future<Map<dynamic, dynamic>?> doPayment(Map<String, dynamic> inputs) async {
    Future<Map<dynamic, dynamic>?> response;
    for (String element in _required) {
      if (!inputs.containsKey(element) || inputs[element].toString().isEmpty) {
        return _failureResponse(element + " not provided");
      }
    }

    if(kIsWeb) {
      MethodChannel channel = const MethodChannel('cashfree_pg');
      response = channel.invokeMethod(
          'doPayment', inputs);
      return response;
    } else {

      /// The below checks if there is any pending responses that has to be sent back to the user from the previous transaction
      /// This uses orderId to match the response
      MethodChannel previousResponseChannel = const MethodChannel(
          'cashfree_pg');
      var previousResponse = await previousResponseChannel.invokeMethod(
          'getPendingResponse');
      if (previousResponse != null &&
          previousResponse["orderId"] == inputs["orderId"]) {
        var completer = new Completer<Map<dynamic, dynamic>>();
        completer.complete(previousResponse);
        return completer.future;
      }

      /// The below code establishes a channel to communicate with the native layer for payment invocation
      MethodChannel channel = const MethodChannel('cashfree_pg');
      // ignore: unnecessary_null_comparison
      if (channel != null) {
        response = channel.invokeMethod('doPayment', inputs);
      } else {
        response = _failureResponse('Invalid channel');
      }
      return response;
    }
  }

  /// Function to initiate UPI Intent
  static Future<Map<dynamic, dynamic>?> doUPIPayment(Map<String, dynamic> inputs) async {
    Future<Map<dynamic, dynamic>?> response;
    for (String element in _required) {
      if (!inputs.containsKey(element) || inputs[element].toString().isEmpty) {
        return _failureResponse(element + " not provided");
      }
    }

    if(kIsWeb) {
      return _failureResponse("This method does not exist for web platform");
    }
    /// The below checks if there is any pending responses that has to be sent back to the user from the previous transaction
    /// This uses orderId to match the response
    MethodChannel previousResponseChannel = const MethodChannel('cashfree_pg');
    var previousResponse = await previousResponseChannel.invokeMethod('getPendingResponse');
    if(previousResponse != null && previousResponse["orderId"] == inputs["orderId"]) {
      var completer = new Completer<Map<dynamic, dynamic>>();
      completer.complete(previousResponse);
      return completer.future;
    }

    /// The below code establishes a channel to communicate with the native layer for payment invocation
    MethodChannel channel = const MethodChannel('cashfree_pg');
    // ignore: unnecessary_null_comparison
    if(channel != null) {
      response = channel.invokeMapMethod("doUPIPayment", inputs);
    } else {
      response = _failureResponse("Invalid Channel");
    }
    return response;
  }

  /// This method returns the list of installed UPI applications
  static Future<List?> getUPIApps() {
    Future<List?> response;

    if(kIsWeb) {
      var completer = new Completer<List>();
      completer.complete(<dynamic>[]);
      response = completer.future;
    }
    MethodChannel channel = const MethodChannel("cashfree_pg");
    // ignore: unnecessary_null_comparison
    if(channel != null) {
      response = channel.invokeListMethod("getUPIApps");
    } else {
      var completer = new Completer<List>();
      completer.complete(<dynamic>[]);
      response = completer.future;
    }
    return response;
  }

  /// Creates a failure response
  static Future<Map<dynamic, dynamic>> _failureResponse(String s) {
    var completer = new Completer<Map<dynamic, dynamic>>();
    Map<dynamic, dynamic> failureResponse = new Map<dynamic, dynamic>();
    failureResponse['txMsg'] = s;
    failureResponse['txStatus'] = 'FAILED';
    completer.complete(failureResponse);
    return completer.future;
  }
}