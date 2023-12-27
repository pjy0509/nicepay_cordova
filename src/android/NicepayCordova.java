package kr.nicepay.cordova;

import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.os.Bundle;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Locale;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.Map;

import android.content.pm.PackageManager;


public class NicepayCordova extends CordovaPlugin {
	Intent intent;
	
	static final int REQUEST_CODE = 6018;
	static final String WEBVIEW_PATH = "file:///android_asset/www/nicepay-webview.html";
	
	public CallbackContext callback;
	
	@Override
	public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
		if (action.equals("setup")) {
			callback = callbackContext;
			intent = new Intent(cordova.getActivity().getApplicationContext(), NicepayActivity.class);
			
			Map<String, Object> params = ConvertUtils.convertJSONObject2Map(args.getJSONObject(0));
			Map<String, Object> options = ConvertUtils.convertJSONObject2Map(args.getJSONObject(1));
			
			ArrayList<String> endpoint = new ArrayList<String>() {{
				Object obj = params.get("Endpoint");
				if (obj instanceof JSONArray) {
					addAll(ConvertUtils.convertJSONArray2List(((JSONArray) obj), String.class));
				} else if (obj instanceof String) {
					add(String.valueOf(obj));
				} else if (obj == null) {
					add(String.valueOf(params.get("ReturnURL")));
				}
			}};
			
			Object withHeader = options.get("withHeader");
			Map<String, String> headers = null;
			if (withHeader instanceof JSONObject) {
				headers = ConvertUtils.convert2StringMap(ConvertUtils.convertJSONObject2Map((JSONObject) options.get("withHeader")));
			}
			
			params.remove("Endpoint");
			params.put("NpLang", getDefault(String.valueOf(params.get("NpLang")), getSystemNpLang()));
			params.put("CurrencyCode", getDefault(String.valueOf(params.get("CurrencyCode")), getSystemCurrencyCode()));
			options.put("title", getDefault(String.valueOf(options.get("title")), getSystemTitle()));
			
			intent.putExtra("params", ConvertUtils.convertMap2JSONString(params));
			intent.putExtra("options", ConvertUtils.convertMap2JSONString(options));
			intent.putExtra("endpoint", endpoint);
			intent.putExtra("headers", ConvertUtils.convertMap2JSONString(headers));
			
			cordova.setActivityResultCallback(this);
			cordova.getActivity().startActivityForResult(intent, REQUEST_CODE);
			
			return true;
		}
		return false;
	}
	
	@Override
	public void onActivityResult(int requestCode, int resultCode, Intent intent) {
		super.onActivityResult(requestCode, resultCode, intent);
		if (requestCode == REQUEST_CODE) {
			if (intent != null) {
				Bundle extras = intent.getExtras();
				String response = extras.getString("response");
				Map<String, Object> result = ConvertUtils.convertJSONString2Map(response);
				
				if (result.get("status").equals("success")) {
					callback.success(response);
				} else {
					callback.error(response);
				}
			} else {
				callback.error(
						ConvertUtils.convertMap2JSONString(
								new HashMap<String, Object>() {{
									put("status", "fail");
									put("responseCode", "-100");
									put("message", "사용자 취소");
								}}
						)
				);
			}
		}
	}
	
	protected String getSystemNpLang() {
		String lang = Locale.getDefault().getLanguage().toUpperCase();
		
		if (lang.equals("KO") || lang.equals("CN")) {
			return lang;
		} else {
			return "EN";
		}
	}
	
	protected String getSystemCurrencyCode() {
		String country = new Locale("", Locale.getDefault().getCountry()).getCountry().toUpperCase();
		
		if (country.equals("KR")) {
			return "KRW";
		} else if (country.equals("CN")) {
			return "CNY";
		} else {
			return "USD";
		}
	}
	
	protected String getSystemTitle() {
		try {
			Context ct = cordova.getActivity().getApplicationContext();
			PackageManager pm = ct.getPackageManager();
			PackageInfo pi = pm.getPackageInfo(ct.getPackageName(), 0);
			return pi.applicationInfo.loadLabel(pm).toString();
		} catch (PackageManager.NameNotFoundException e) {
			return "";
		}
	}
	
	protected String getDefault(String string, String defaultValue) {
		String stringValue = string != null ? string : "";
		return stringValue.equals("@SYSTEM") ? defaultValue : string;
	}
}
