import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cashfree_pg/cashfree_pg.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    setState(() {});
  }

  void startNextScreen() {
    fetchPost();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('CFSDK Sample'),
        ),
        body: Center(
          child: ElevatedButton(
            child: Text('DO PAYMENT'),
            onPressed: () {
              startNextScreen();
            },
          ),
        ),
      ),
    );
  }

  fetchPost() async {
    var order = new Order();
//    print(order.toString());
    var dio = Dio();
    final response = await dio
        .post(
            order.stage == "TEST"
                ? 'https://test.cashfree.com/api/v2/cftoken/order'
                : 'https://api.cashfree.com/api/v2/cftoken/order',
            options: Options(headers: {
              'x-client-id': order.appId,
              'x-client-secret': order.stage == "TEST"
                  ? '4c41ca2022d1fa588efa91b73af7bb3489421735'
                  : '62f1476aee1c57c7bef6259e104f9a868b068ed6',
              'Content-Type': 'application/json'
            }),
            data: jsonEncode({
              'orderId': order.orderId,
              'orderAmount': order.orderAmount,
              'orderCurrency': order.orderCurrency,
            }));

    print("Token Gen Resp : " + response.data.toString());
    if (response.statusCode == 200) {
      order.tokenData = response.data['cftoken'];
      print('Token : ' + order.tokenData.toString());
      // If server returns an OK response, parse the JSON.
      var inputs = order.toMap();
      inputs.addAll(UIMeta().toMap());
      inputs.putIfAbsent('tokenData', () {
        return response.data['cftoken'];
      });
      inputs.forEach((key, value) {
        print("$key : $value");
      });
      CashfreePGSDK.doPayment(inputs)
          .then((value) => value?.forEach((key, value) {
        print("$key : $value");
      }));
    } else {
      // If that response was not OK, throw an error.
      print('Failed to generate token');
    }
  }
}

class Token {
  final String cfToken;

  Token({this.cfToken});

  factory Token.fromJson(Map<String, dynamic> json) {
    return Token(
      cfToken: json['cftoken'],
    );
  }
}

class Order {
  Order() {
    appId = stage == "TEST"
        ? "1831dac3fd47d13be98b7fd11381"
        : "1848d0ce8441fb8ffa258bc98481";
  }

  String stage = "PROD";
  String orderId = getRandomNo();
  String orderAmount = "1";
  String tokenData = "";
  String customerName = "Arjun";
  String orderNote = "Order Note";
  String orderCurrency = "INR";
  String appId;
  String customerPhone = "9012341234";
  String customerEmail = "sample@gmail.com";
  String notifyUrl = "https://test.gocashfree.com/notify";

  static String getRandomNo() {
    var rng = new Random();
    return 'order ${rng.nextInt(1000000)}';
  }

  Map<String, dynamic> toMap() {
    return {
      "orderId": orderId,
      "orderAmount": orderAmount,
      "customerName": customerName,
      "orderNote": orderNote,
      "orderCurrency": orderCurrency,
      "appId": appId,
      "customerPhone": customerPhone,
      "customerEmail": customerEmail,
      "stage": stage,
      "tokenData": tokenData,
      "notifyUrl": notifyUrl
    };
  }

  String toString() {
    return " \norderId" +
        orderId +
        " \norderAmount " +
        orderAmount +
        " \ncustomerName " +
        customerName +
        " \norderNote " +
        orderNote +
        " \norderCurrency " +
        orderCurrency +
        " \nappId " +
        appId +
        " \ncustomerPhone " +
        customerPhone +
        " \ncustomerEmail " +
        customerEmail +
        " \nstage " +
        stage +
        " \nnotifyUrl " +
        notifyUrl+
        " \ntokenData " +
        tokenData;
  }
}

class UIMeta {
  String color1 = "#FF233F";
  String color2 = "#033400";
  String hideOrderId = "false";

  static String getRandomNo() {
    var rng = new Random();
    return 'order ${rng.nextInt(1000000)}';
  }

  Map<String, dynamic> toMap() {
    return {"color1": color1, "color2": color2};
  }

  String toString() {
    return " \ncolor1 $color1 \ncolor1  $color2  \nhideOrderId $hideOrderId";
  }
}
