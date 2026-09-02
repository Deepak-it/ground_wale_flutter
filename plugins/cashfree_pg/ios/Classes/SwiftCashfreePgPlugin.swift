import Flutter
import UIKit
import CFSDK

public class SwiftCashfreePgPlugin: NSObject, FlutterPlugin, ResultDelegate {
    var storyboard : UIStoryboard?
    public func onPaymentCompletion(msg: String) {
        print(msg)
        if msg.first == "[" {
            //Here we are removing any occurrences of "[" and "]"
            let replacingBraces = msg.replacingOccurrences(of: "[", with: "", options: [], range: Range(NSRange(location: 0, length: 1), in: msg))
            let result = replacingBraces.replacingOccurrences(of: "]", with: "", options: [], range: Range(NSRange(location: replacingBraces.count - 1, length: 1), in: replacingBraces))
            var resultToSend: [String: String] = [:]
            //Here we are removing any occurrences of " present in the string
            let newResult = result.replacingOccurrences(of: "\"", with: "").split(separator: ",")
            for val in newResult {
                let newRes = val.split(separator: ":")
                var key = String(newRes[0])
                var value = String(newRes[1])
                if key.first == " " {
                    key = key.replacingOccurrences(of: " ", with: "", options: [], range: Range(NSRange(location: 0, length: 1), in: key))
                }
                if value.first == " " {
                    value = value.replacingOccurrences(of: " ", with: "", options: [], range: Range(NSRange(location: 0, length: 1), in: value))
                }
                //Here we are creating the dictionary to send it to the user
                resultToSend["\(key)"] = "\(value)"
            }
            if flutterResult != nil {
                flutterResult!(resultToSend)
            }
        } else {
            self.sendResult(message: msg)
        }
    }

    private func sendResult(message: String) {
        let data :NSData = message.data(using: String.Encoding.utf8)! as NSData
        do {
            let result :Dictionary = try JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as! Dictionary<String, String>
            if flutterResult != nil {
                flutterResult!(result)
            }
        } catch {
            sendFailedResult(msg: "SDK Internal error")
        }
    }
    
    func sendFailedResult(msg: String) {
        var failureResult : Dictionary<String, String> = Dictionary();
        failureResult["txStatus"] = "FAILED"
        failureResult["txMsg"] = msg
        if flutterResult != nil {
            flutterResult!(failureResult)
        }
    }
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let msr = registrar.messenger()
        let channel = FlutterMethodChannel(name: "cashfree_pg", binaryMessenger: msr)
        let instance = SwiftCashfreePgPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    private var flutterResult:FlutterResult?
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if(call.method == "getUPIApps") {
           let apps = CFPaymentService().getUPIApps()//["installedApps": CFPaymentService().getUPIApps()] // Convert this to JSON String if it doesn't work in Android
           result(apps)
        } else {
            self.flutterResult = result
            var args = call.arguments as? Dictionary<String, Any>
            if (args?["appId"]) == nil || (args?["stage"]) == nil {
                sendFailedResult(msg: "mandatory params missing")
                return
            }
            args?["source"] = "flutter-ios-sdk"
            if(call.method == "doUPIPayment") {
                DispatchQueue.main.async {
                    CFPaymentService().doUPIPayment(params: args!, env: args!["stage"] as! String, callback: self)
                }
            } else {
                DispatchQueue.main.async {
                    CFPaymentService().doWebCheckoutPayment(params: args!, env: args!["stage"] as! String, callback: self)
                }
            }
        }
    }
}
