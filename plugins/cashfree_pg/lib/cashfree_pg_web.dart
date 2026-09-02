import 'dart:async';
import 'dart:collection';
import 'dart:convert';
// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show window;
import 'dart:html';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// A web implementation of the CashfreePg plugin.
class CashfreePgWeb {
  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
      'cashfree_pg',
      const StandardMethodCodec(),
      registrar,
    );

    final pluginInstance = CashfreePgWeb();
    channel.setMethodCallHandler(pluginInstance.handleMethodCall);
  }

  /// Handles method calls over the MethodChannel of this plugin.
  /// Note: Check the "federated" architecture for a new way of doing this:
  /// https://flutter.dev/go/federated-plugins
  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'doPayment':
        var arguments = call.arguments as LinkedHashMap<Object?, Object?>;
        Map<String, dynamic> mapData = {};
        arguments.forEach((key, value) {
          mapData[key as String] = value;
        });
        return doPayment(mapData);
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'cashfree_pg for web doesn\'t implement \'${call.method}\'',
        );
    }
  }

  /// WEB
  Future<Map<dynamic, dynamic>?> doPayment(Map<String, dynamic> inputParams) async {

    var window = html.window;
    var document = window.document;

    /// FORM
    var my_form = document.createElement('FORM') as FormElement ;
    my_form.id = 'redirectForm';
    my_form.method = 'POST';
    my_form.target = 'POPUPW';

    String URL = "";
    if(inputParams["stage"].toString().toUpperCase() == "TEST") {
      URL = 'https://test.cashfree.com/billpay/checkout/post/submit';
    } else {
      URL = 'https://www.cashfree.com/checkout/post/submit';
    }

    my_form.action = URL;

    /// Adding source
    inputParams["source"] = "flutter-hyb";

    /// Adding all form paramters
    inputParams.forEach((key, value) {
      var my_tb = document.createElement('INPUT') as InputElement;
      my_tb.type = 'HIDDEN';
      my_tb.name = key;
      my_tb.value = value;
      my_form.children.add(my_tb);
    });

    document.querySelector("body")?.children.add(my_form);
    var paymentWindow = window.open('about:blank', 'POPUPW');

    /// Form Submit
    my_form.submit();

    /// Timer
    Timer.periodic(Duration(milliseconds: 500), (timer) {
      if(paymentWindow.closed == true) {
        timer.cancel();
        var cancelledResponse = {
          "txStatus": "CANCELLED",
          "txMsg": "transaction cancelled by the user",
          "orderId": inputParams["orderId"]
        };
        window.postMessage(cancelledResponse, "*");
      }
    });

    /// Awaiting for first message
    var response = await window.onMessage.first;

    /// Closing the window
    paymentWindow.close();

    /// Sending back the response
    if(response.data is String) {
      var completer = new Completer<Map<dynamic, dynamic>>();
      var r = jsonDecode(response.data);
      completer.complete(r);
      return completer.future;
    } else {
      var completer = new Completer<Map<dynamic, dynamic>>();
      completer.complete(response.data);
      return completer.future;
    }
  }
}
