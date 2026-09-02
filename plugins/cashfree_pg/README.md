# Cashfree PG Flutter SDK [![pub package](https://img.shields.io/pub/v/cashfree_pg.svg)](https://pub.dartlang.org/packages/cashfree_pg)

# Integration Steps

## Step 1: Add Dependency

Open the pubspec.yaml file located inside the app folder, and add cashfree_pg: under dependencies.

```yaml

 cashfree_pg: 2.0.10+30

```

## Step 2a: Manifest Changes (Android)

The Cashfree PG SDK requires that you add the INTERNET permission in your `Android Manifest` file.

```xml
<manifest ...>
 <uses-permission android:name="android.permission.INTERNET" />
<application ...>
```
Set the tools:node attribute to merge in the definition of your application element in the Android Manifest file.

```xml
<application
        ...
        tools:node="merge">
          <!--Only add it if you need Auto OTP reading feature is enabled-->
        <meta-data android:name="com.google.android.gms.version"
          android:value="@integer/google_play_services_version" />
</application>
```

## Step 2b: Info.plist permissions in iOS

Open the iOS application using XCode or any text editor and add the following into its info.plist file
```xml
<key>LSApplicationCategoryType</key>
<string></string>
<key>LSApplicationQueriesSchemes</key>
<array>
<string>phonepe</string>
<string>tez</string>
<string>paytm</string>
</array>
```

## Step 3: Android Gradle

Set Android Gradle Plugin version to <b>4.1.1 or higher</b>
Set Android Gradle version to <b>6.5 or higher</b>


## Step 4: Generate Token (From Backend)
You will need to generate a token from your backend and pass it to app while initiating payments. For generating token you need to use our token generation API. Please take care that this API is called only from your <b><u>backend</u></b> as it uses **secretKey**. Thus this API should **never be called from App**.


### Request Description

<copybox>

 For production/live usage set the action attribute of the form to:
 `https://api.cashfree.com/api/v2/cftoken/order`

 For testing set the action attribute to:
 `https://test.cashfree.com/api/v2/cftoken/order`

</copybox>

You need to send orderId, orderCurrency and orderAmount as a JSON object to the API endpoint and in response a token will received. Please see the description of request below.

```bash
curl -XPOST -H 'Content-Type: application/json'
-H 'x-client-id: <YOUR_APP_ID>'
-H 'x-client-secret: <YOUR_SECRET_KEY>'
-d '{
 "orderId": "<ORDER_ID>",
 "orderAmount":<ORDER_AMOUNT>,
 "orderCurrency": "INR"
}' 'https://test.cashfree.com/api/v2/cftoken/order'
```

### Request Example

Replace **YOUR_APP_ID** and **YOUR_SECRET_KEY** with actual values.
```bash
curl -XPOST -H 'Content-Type: application/json' -H 'x-client-id: YOUR_APP_ID' -H 'x-client-secret: YOUR_SECRET_KEY' -d '{
 "orderId": "Order0001",
 "orderAmount":1,
 "orderCurrency":"INR"
}' 'https://test.cashfree.com/api/v2/cftoken/order'
```

### Response Example

```bash
{
"status": "OK",
"message": "Token generated",
"cftoken": "v79JCN4MzUIJiOicGbhJCLiQ1VKJiOiAXe0Jye.s79BTM0AjNwUDN1EjOiAHelJCLiIlTJJiOik3YuVmcyV3QyVGZy9mIsEjOiQnb19WbBJXZkJ3biwiIxADMwIXZkJ3TiojIklkclRmcvJye.K3NKICVS5DcEzXm2VQUO_ZagtWMIKKXzYOqPZ4x0r2P_N3-PRu2mowm-8UXoyqAgsG"
}
```

The "cftoken" is the token that is used authenticate your payment request that will be covered in the next step.


## Step 4: Initiate Payment

- App passes the order info and the token to the SDK
- Customer is shown the payment screen where he completes the payment
- Once the payment is complete SDK verifies the payment
- App receives the response from SDK and handles it appropriately


### NOTE

- The order details passed during the token generation and the payment initiation should match. Otherwise you'll get a<b>"invalid order details"</b> error.
- Wrong appId and token will result in <b>"Unable to authenticate merchant"</b> error. The token generated for payment is valid for 5 mins within which the payment has to be initiated. Otherwise you'll get a <b>"Invalid token"</b> error.

# Payment modes


# Web Checkout Integration

## How to integrate


For both the modes (normal and [seamless](https://docs.cashfree.com/docs/android/guide/#seamless-integration)) you need to invoke the <b>doPayment()</b> method. However, there are a few extra parameters you need to pass incase of seamless mode.




### doPayment


```dart

Future<Map<dynamic, dynamic>> doPayment(Map<String, dynamic> inputs)

```

Initiates the payment in a webview. The customer will be taken to the payment page on cashfree server where they will have the option of paying through any payment option that is activated on their account. Once the payment is done the webview will close and the response will be delivered in the callback.

<b>Parameters:</b>

- <code>params</code> A map of all the relevant parameters described in the Request Params section below.

## Sample Code

```dart

CashfreePGSDK.doPayment(inputParams)
        .then((value) => value?.forEach((key, value) {
              print("$key : $value");
              //Do something with the result
            }));

```

# Unified UPI Intent

When the doUPIPayment method is invoked the customer is shown a list of all the installed UPI applications on their phone. After the customer selects their preferred application, the payment confirmation page will open in the application. After payment completion, the response is delivered through a “Future”.

### doUPIPayment

Open the iOS application using XCode or any text editor and add the following into its info.plist file
```xml
<key>LSApplicationCategoryType</key>
<string></string>
<key>LSApplicationQueriesSchemes</key>
<array>
<string>phonepe</string>
<string>tez</string>
<string>paytm</string>
</array>
```

```dart

Future<Map<dynamic, dynamic>> doUPIPayment(Map<String, dynamic> inputs)

```

Initiates the UPI Payment and the customer is shown a list of all the UPI client applications (Paytm, GPay, PhonePe etc.) on their phone. This allows the customer to select any UPI application of their choice to pay with. Once the payment is completed the UPI page will close and the response will be delivered through a Future (See Example Below).

```dart

CashfreePGSDK.doUPIPayment(inputParams)
        .then((value) => value?.forEach((key, value) {
            print("$key : $value");
            //Do something with the result
        }));

```

## Seamless UPI Intent

In case if you do not want to use the UI provided by Cashfree, you can make your own UI and initiate the UPI Payment function as well. This can be done as follows:

**Step 1:- Call this method to get the list of all installed UPI Application**
```dart
CashfreePGSDK.getUPIApps().then((value) => {
        // Value is a List of MAP<String, String>
        // It consists of 3 keys "displayName", "id" and a base64 string "icon"
        // You can convert the base64 string to image and display the app icon
        })
});
```

```dart
//NOTE:- If you wish to use the application Icon provided by Cashfree, the below code can be used to convert base64 String to image.


Uint8List _imageBytesDecoded;
_imageBytesDecoded = Base64Codec().decode(app["icon"]);

// Inside a Widget, you can use this to show icons
Center(
child: this._imageBytesDecoded != null ? Image.memory(_imageBytesDecoded,fit: BoxFit.cover,) : Icon(Icons.image),
)
```

**Step 2:- Send "id" retrieved by the above method as value to the key "appName"**

```dart
Map<String, dynamic> inputParams = {
      .................
      .................
      .................
      .................
      .................
      "appName": selectedApp["id"], // This is one of the Map<> from the getUPIApps() method
};

// Then invoke the doUPIPayment Method
CashfreePGSDK.doUPIPayment(inputParams)
        .then((value) => value?.forEach((key, value) {
            print("$key : $value");
            //Do something with the result
}));

```

<b>Parameters:</b>

- <code>params</code> A map of all the relevant parameters described in the Request Params section below.


# Request Parameters

| Parameter | Required | Description |
|-------------------------------------|-----------|----------------------------------------------------|
| <code>color1</code> | Yes | Background color value of the top bar as Hex String. ex:- "#FFFFFF" |
| <code>color2</code> | Yes | Text color of the topbar as Hex String. ex:- "#000000" |
| <code>stage</code> | Yes | Environment - TEST or PROD |
| <code>appId</code> | Yes | Your app id |
| <code>orderId</code> | Yes | Order/Invoice Id |
| <code>orderAmount</code> | Yes | Bill amount of the order |
| <code>orderNote</code> | No | A help text to make customers know more about the order |
| <code>orderCurrency</code> | Yes | Currency code of the order. Default is INR. |
| <code>customerName</code> | No | Name of the customer |
| <code>customerPhone</code> | Yes | Phone number of customer |
| <code>customerEmail</code> | Yes | Email id of the customer |
| <code>tokenData</code> | Yes | Token generated from step 4 |
| <code>notifyUrl</code> | No | Notification URL for server-server communication. Useful when user’s connection drops after completing payment. |
| <code>paymentModes</code> | No | Allowed payment modes for this order. Available values: cc, dc, nb, paypal, upi, wallet. <strong>Leave it blank if you want to display all modes</strong> |


# Response parameters

These parameters are sent as extras to the onActivityResult(). They contain the details of the transaction.

| Parameter | Description |
|------------------------------------------------|----------------------------------------------------|
| <code>orderId</code> | Order id for which transaction has been processed. Ex: GZ-212 |
| <code>orderAmount</code> | Amount of the order. Ex: 256.00 |
| <code>paymentMode</code> | Payment mode of the transaction. |
| <code>referenceId</code> | Cashfree generated unique transaction Id. Ex: 140388038803 |
| <code>txStatus</code> | Payment status for that order. Values can be : SUCCESS, FLAGGED, PENDING, FAILED, CANCELLED. |
| <code>paymentMode</code> | Payment mode used by customer to make the payment. Ex: DEBIT_CARD, MobiKwik, etc |
| <code>txMsg</code> | Message related to the transaction. Will have the reason, if payment failed |
| <code>txTime</code> | Time of the transaction |
| <code>type</code> | Fixed value : <b>CashFreeResponse</b>. To identify the response is from cashfree SDK. |
| <code>signature</code> | Response signature, more [here.](https://docs.cashfree.com/pg/cf-checkout/#response-verification) |




### NOTE

- There can be scenarios where the SDK is not able to verify the payment within a short period of time. The status of such orders will be <code><b>PENDING</b></code>.
- If the WebView is closing as soon as it opens then most probably something is wrong with the input passed to the SDK. Please check your inputs and if you still need further help reach out to us at techsupport@cashfree.com.
- If you are getting INCOMPLETE as the transaction status please reach out to your account manager or techsupport@cashfree.com.
