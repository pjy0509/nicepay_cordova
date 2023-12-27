package kr.nicepay.cordova;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.UnsupportedEncodingException;
import java.lang.reflect.InvocationTargetException;
import java.net.URL;
import java.net.URLDecoder;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class ConvertUtils {
	public static Map<String, Object> convertJSONObject2Map(JSONObject jsonObject) {
		Map<String, Object> map = new HashMap<>();
		Iterator<String> keys = jsonObject.keys();
		
		while (keys.hasNext()) {
			String key = keys.next();
			Object value = jsonObject.opt(key);
			map.put(key, value);
		}
		
		return map;
	}
	
	public static List<Object> convertJSONArray2List(JSONArray jsonArray) {
		return convertJSONArray2List(jsonArray, Object.class);
	}
	
	public static <T> List<T> convertJSONArray2List(JSONArray jsonArray, Class<T> valueOf) {
		try {
			List<T> list = new ArrayList<>();
			for (int i = 0; i < jsonArray.length(); i++) {
				try {
					list.add(valueOf.getConstructor(String.class).newInstance(jsonArray.getString(i)));
				} catch (IllegalAccessException | InvocationTargetException | NoSuchMethodException | InstantiationException ignored) {
				}
			}
			return list;
		} catch (JSONException e) {
			return new ArrayList<>();
		}
	}
	
	public static String convertMap2JSONString(Map<?, ?> map) {
		return new JSONObject(map).toString();
	}
	
	public static Map<String, Object> convertJSONString2Map(String jsonString) {
		Map<String, Object> map = new HashMap<>();
		
		try {
			JSONObject jsonObject = new JSONObject(jsonString);
			Iterator<String> keys = jsonObject.keys();
			
			while (keys.hasNext()) {
				String key = keys.next();
				Object value = jsonObject.get(key);
				map.put(key, value);
			}
		} catch (JSONException e) {
			e.printStackTrace();
		}
		
		return map;
	}
	
	public static Map<String, Object> convertURLQueryParameter2Map(URL url) {
		return convertURLQueryParameter2Map(url.getQuery());
	}
	
	public static Map<String, Object> convertURLQueryParameter2Map(String query) {
		Map<String, Object> queryParams = new HashMap<>();
		
		if (query != null && !query.isEmpty()) {
			String[] params = query.split("&");
			for (String param : params) {
				String[] keyValue = param.split("=");
				if (keyValue.length == 2) {
					String key = keyValue[0];
					String value = keyValue[1];
					try {
						key = URLDecoder.decode(key, "UTF-8");
						value = decodeUnicodeString(value);
						queryParams.put(key, value);
					} catch (Exception e) {
						queryParams.put(key, value);
					}
				}
			}
		}
		
		return queryParams;
	}
	
	private static String decodeUnicodeString(String string) {
		return decodeUnicodeString(string, "UTF-8");
	}
	
	private static String decodeUnicodeString(String string, String unicode) {
		try {
			String decodedString = URLDecoder.decode(string, unicode);
			Pattern pattern = Pattern.compile("%u([0-9A-Fa-f]{4})|%([0-9A-Fa-f]{2})");
			Matcher matcher = pattern.matcher(decodedString);
			
			StringBuffer sb = new StringBuffer();
			while (matcher.find()) {
				String hexValue = matcher.group(1) != null ? matcher.group(1) : matcher.group(2);
				int unicodeValue = Integer.parseInt(hexValue, 16);
				String replacement = String.valueOf((char) unicodeValue);
				matcher.appendReplacement(sb, replacement);
			}
			matcher.appendTail(sb);
			
			return sb.toString();
		} catch (UnsupportedEncodingException e) {
			e.printStackTrace();
			return null;
		}
	}
	
	public static <T> Map<T, String> convert2StringMap(Map<T, ?> map) {
		Map<T, String> outputMap = new HashMap<>();
		for (Map.Entry<T, ?> entry : map.entrySet()) {
			T key = entry.getKey();
			Object value = entry.getValue();
			outputMap.put(key, String.valueOf(value));
		}
		
		return outputMap;
	}
}
