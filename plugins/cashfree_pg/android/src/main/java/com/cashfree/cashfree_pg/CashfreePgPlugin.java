package com.cashfree.cashfree_pg;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;

import com.cashfree.pg.CFPaymentService;

import org.json.JSONArray;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

public class CashfreePgPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
  public static final String COLOR_1 = "color1";
  public static final String TOKEN_DATA = "tokenData";
  public static final String HIDE_ORDER_ID = "hideOrderId";
  public static final String STAGE = "stage";
  public static final String COLOR_2 = "color2";
  public static final String CASHFREE_PG = "cashfree_pg";
  public static final String TAG = "CashfreePgPlugin";
  public static final String CF_COLOR = "#784BD2";
  public static final String WHITE_COLOR = "#FFFFFF";
  public static final String MODE_WEB_CHECKOUT = "doPayment";
  public static final String MODE_UPI_PAYMENT = "doUPIPayment";
  public static final String MODE_GET_UPI_APPS = "getUPIApps";

  String[] mandatoryParams = new String[] {TOKEN_DATA, STAGE} ;

  private MethodChannel channel;
  private Activity activity;
  private Result flutterResult;
  private Map<String, String> finalResult = null;

  private Handler uiThreadHandler = new Handler(Looper.getMainLooper());
  public ArrayList<HashMap<String, String>> upiApps;


  private CashfreePgPlugin(Activity activity) {
    this.activity = activity;
  }

  public CashfreePgPlugin() {
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), CASHFREE_PG);
    channel.setMethodCallHandler(this);
  }

  @SuppressWarnings("unchecked")
  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    this.flutterResult = result;
    if(call.method.equals("getPendingResponse")) {
      if(finalResult != null) {
        result.success(finalResult);
        finalResult = null;
      } else {
        result.success(null);
      }
    }
    else if (call.method.equals(MODE_WEB_CHECKOUT)) {
      try {
        CFPaymentService cfPaymentServiceInstance = CFPaymentService.getCFPaymentServiceInstance();
        if (call.arguments != null) {
          Map<String, Object> map = (Map<String, Object>) call.arguments;
          Map<String, String> params = new HashMap<String, String>();
          for (Map.Entry<String, Object> entry : map.entrySet()) {
              params.put(entry.getKey(), String.valueOf(entry.getValue()));
              Log.d(entry.getKey(), String.valueOf(entry.getValue()));
          }
          if (validateInputs(params)) {
            boolean hideOrderId = map.containsKey(HIDE_ORDER_ID) && Boolean.parseBoolean(map.get(HIDE_ORDER_ID)+"");
            params.put("source", "flutter-android");
            if (params.containsKey(COLOR_1) && params.containsKey(COLOR_2)) {
              Log.d(TAG, params.get(COLOR_1) + "\t" + params.get(COLOR_2));
              cfPaymentServiceInstance.doPayment(
                      this.activity,
                      params,
                      params.get(TOKEN_DATA),
                      params.get(STAGE),
                      String.format( Locale.getDefault(),"#%s", params.get(COLOR_1).substring(params.get(COLOR_1).length() - 6)),
                      String.format( Locale.getDefault(), "#%s", params.get(COLOR_2).substring(params.get(COLOR_1).length() - 6)),
                      hideOrderId);
            } else {
              Log.d(TAG, "Theme color not present in input params using default");
              cfPaymentServiceInstance.doPayment(this.activity, params, params.get(TOKEN_DATA), params.get(STAGE), CF_COLOR, WHITE_COLOR, hideOrderId);
            }
          } else sendFailedStatus("Mandatory param missing");
        } else {
          sendFailedStatus("Input params null");
        }
      }catch(Exception e){
        sendFailedStatus();
        e.printStackTrace();
      }
    } else if (call.method.equals(MODE_UPI_PAYMENT)) {
      try {
        if(call.arguments != null) {

          Map<String, Object> map = (Map<String, Object>) call.arguments;
          Map<String, String> params = new HashMap<String, String>();

          for (Map.Entry<String, Object> entry : map.entrySet()) {
            params.put(entry.getKey(), String.valueOf(entry.getValue()));
            Log.d(entry.getKey(), String.valueOf(entry.getValue()));
          }

          if (validateInputs(params)) {
            params.put("source", "flutter-android");
            CFPaymentService cfPaymentServiceInstance = CFPaymentService.getCFPaymentServiceInstance();
            cfPaymentServiceInstance.upiPayment(this.activity, params, params.get(TOKEN_DATA), params.get(STAGE));
          } else {
            sendFailedStatus("Mandatory Params Missing");
          }

        } else {
          sendFailedStatus("Input params null");
        }
      } catch (Exception e) {
        sendFailedStatus();
        e.printStackTrace();
      }
    } else if(call.method.equals(MODE_GET_UPI_APPS)) {
      CFPaymentService cfPaymentServiceInstance = CFPaymentService.getCFPaymentServiceInstance();
      cfPaymentServiceInstance.getUpiClients(this.activity, new CFPaymentService.UPIAppsCallback() {
        @Override
        public void onUPIAppsFetched(final ArrayList<HashMap<String, String>> upiAppList) {
          if (upiAppList.isEmpty()) {
            uiThreadHandler.post(new Runnable() {
              @Override
              public void run() {
                if(flutterResult != null) {
                  ArrayList<HashMap<String, String>> apps = new ArrayList<HashMap<String, String>>();
                  flutterResult.success(apps);
                }
              }
            });
          } else {
            uiThreadHandler.post(new Runnable() {
              @Override
              public void run() {
                if(flutterResult != null) {
                  flutterResult.success(upiAppList);
                }
              }
            });
          }
        }
      });
    } else {
      sendFailedStatus();
      result.notImplemented();
    }
  }

  private boolean validateInputs(Map<String, String> params) {
    boolean invalid = false;
    for (String key : mandatoryParams) {
      if (!params.containsKey(key)) {
        Log.e(TAG, key + " missing in input params");
        invalid = true;
      }
    }
    return !invalid;
  }

  private void sendFailedStatus() {
    sendFailedStatus("SDK Internal Error");
  }
  private void sendFailedStatus(String error) {
    Map<String, String> resultMap = new HashMap<>();
    resultMap.put("txStatus", "FAILED");
    resultMap.put("txMsg", error);
    if(flutterResult != null) {
      flutterResult.success(resultMap);
    }
  }


  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    this.activity = binding.getActivity();
    binding.addActivityResultListener(new PluginRegistry.ActivityResultListener() {
      public boolean onActivityResult(int i, int i1, Intent data) {
        if(i == CFPaymentService.REQ_CODE) {
          if (data != null) {
            Map<String, String> resultMap = new HashMap<String, String>();
            Bundle bundle = data.getExtras();
            if (bundle != null) {
              for (String key : bundle.keySet()) {
                if (bundle.getString(key) != null) {
                  resultMap.put(key, bundle.getString(key));
                }
              }
            }
            if(flutterResult != null) {
              flutterResult.success(resultMap);
            } else {
              finalResult = resultMap;
            }
          } else {
            sendFailedStatus();
          }
        }
        return false;
      }
    });
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding activityPluginBinding) {

  }

  @Override
  public void onDetachedFromActivity() {

  }
}
