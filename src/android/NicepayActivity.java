package kr.nicepay.cordova;

import android.annotation.SuppressLint;
import android.app.ActionBar;
import android.app.Activity;
import android.app.AlertDialog;
import android.app.Application;
import android.content.Intent;
import android.content.res.ColorStateList;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.Drawable;
import android.os.Build;
import android.os.Bundle;
import android.view.Gravity;
import android.view.MenuItem;
import android.view.View;
import android.webkit.JavascriptInterface;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.widget.Button;
import android.widget.LinearLayout;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Map;

import kr.co.hotelguide.hotelga.R;


public class NicepayActivity extends Activity {
	WebView webView;
	NicepayWebViewClient nicepayWebViewClient;
	
	@SuppressLint("SetJavaScriptEnabled")
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		
		Application application = getApplication();
		String packageName = application.getPackageName();
		
		int identifier = application.getResources().getIdentifier("nicepay_activity", "layout", packageName);
		setContentView(identifier);
		
		int webViewId = getResources().getIdentifier("webview", "id", getPackageName());
		webView = findViewById(webViewId);
		
		WebSettings settings = webView.getSettings();
		settings.setJavaScriptEnabled(true);
		settings.setDomStorageEnabled(true);
		
		webView.loadUrl(NicepayCordova.WEBVIEW_PATH);
		webView.setWebChromeClient(new NicepayWebChromeClient());
		
		Bundle extras = getIntent().getExtras();
		
		String paramsString = extras.getString("params");
		String optionsString = extras.getString("options");
		ArrayList<String> endpoints = extras.getStringArrayList("endpoint");
		String headersString = extras.getString("headers");
		
		Map<String, Object> params = ConvertUtils.convertJSONString2Map(paramsString);
		Map<String, Object> options = ConvertUtils.convertJSONString2Map(optionsString);
		Map<String, String> headers = ConvertUtils.convert2StringMap(ConvertUtils.convertJSONString2Map(headersString));
		
		setActionBar(options);
		
		webView.addJavascriptInterface(new NicepayBridge(), "NicepayBridge");
		
		nicepayWebViewClient = new NicepayWebViewClient(this, params, options, endpoints, headers) {
			@SuppressLint("ObsoleteSdkInt")
			@Override
			public void onPageFinished(WebView view, String url) {
				if (!isWebViewLoaded && Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
					view.evaluateJavascript("requestPayment(" + paramsString + ")", null);
					isWebViewLoaded = true;
				}
			}
		};
		
		webView.setWebViewClient(nicepayWebViewClient);
	}
	
	@SuppressLint({"ClickableViewAccessibility", "UseCompatTextViewDrawableApis"})
	protected void setActionBar(Map<String, Object> options) {
		ActionBar ab = getActionBar();
		boolean withNavigation = parseBoolean(options.get("withNavigation"));
		
		if (!withNavigation) {
			ab.hide();
		} else {
			String title = String.valueOf(options.get("title"));
			int backgroundColor = colorSelector(String.valueOf(options.get("backgroundColor")), Color.WHITE);
			int titleColor = colorSelector(String.valueOf(options.get("titleColor")));
			int buttonColor = colorSelector(String.valueOf(options.get("buttonColor")));
			boolean withBackButton = parseBoolean(options.get("withBackButton"));
			boolean withCloseButton = parseBoolean(options.get("withCloseButton"));
			
			ab.setBackgroundDrawable(new ColorDrawable(backgroundColor));
			ab.setDisplayOptions(ActionBar.DISPLAY_SHOW_CUSTOM);
			ab.setCustomView(
					new LinearLayout(NicepayActivity.this) {{
						Button backButton = new androidx.appcompat.widget.AppCompatButton(NicepayActivity.this) {{
							setPadding(16, 0, 16, 0);
							setCompoundDrawablesWithIntrinsicBounds(R.drawable.ic_np_back, 0, 0, 0);
							if (withBackButton) {
								setVisibility(View.VISIBLE);
								setOnTouchListener(
										(view, motionEvent) -> {
											goBack();
											return false;
										}
								);
							} else {
								setVisibility(View.INVISIBLE);
								setOnTouchListener((view, motionEvent) -> false);
							}
						}};
						
						Button closeButton = new androidx.appcompat.widget.AppCompatButton(NicepayActivity.this) {{
							setPadding(16, 0, 16, 0);
							setCompoundDrawablesWithIntrinsicBounds(R.drawable.ic_np_close, 0, 0, 0);
							if (withCloseButton) {
								setVisibility(View.VISIBLE);
								setOnTouchListener(
										(view, motionEvent) -> {
											showCancelAlert();
											return false;
										}
								);
							} else {
								setVisibility(View.INVISIBLE);
								setOnTouchListener((view, motionEvent) -> false);
							}
						}};
						
						if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
							backButton.setCompoundDrawableTintList(ColorStateList.valueOf(buttonColor));
						} else {
							Drawable backButtonDrawable = closeButton.getCompoundDrawables()[0];
							backButtonDrawable.setTint(buttonColor);
							backButton.setCompoundDrawables(backButtonDrawable, null, null, null);
						}
						
						if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
							closeButton.setCompoundDrawableTintList(ColorStateList.valueOf(buttonColor));
						} else {
							Drawable closeButtonDrawable = closeButton.getCompoundDrawables()[0];
							closeButtonDrawable.setTint(buttonColor);
							closeButton.setCompoundDrawables(closeButtonDrawable, null, null, null);
						}
						
						setOrientation(LinearLayout.HORIZONTAL);
						setLayoutParams(new LinearLayout.LayoutParams(
								LinearLayout.LayoutParams.MATCH_PARENT,
								LinearLayout.LayoutParams.MATCH_PARENT
						));
						setGravity(Gravity.CENTER_VERTICAL);
						addView(
								backButton,
								new LinearLayout.LayoutParams(
										LinearLayout.LayoutParams.WRAP_CONTENT,
										LayoutParams.MATCH_PARENT
								)
						);
						addView(
								new androidx.appcompat.widget.AppCompatTextView(NicepayActivity.this) {{
									setText(title);
									setTextColor(titleColor);
									setGravity(Gravity.CENTER);
									setLayoutParams(
											new LinearLayout.LayoutParams(
													LinearLayout.LayoutParams.MATCH_PARENT,
													LinearLayout.LayoutParams.MATCH_PARENT
											) {{
												weight = 1;
											}}
									);
								}}
						);
						addView(
								closeButton,
								new LinearLayout.LayoutParams(
										LinearLayout.LayoutParams.WRAP_CONTENT,
										LinearLayout.LayoutParams.WRAP_CONTENT
								)
						);
					}}
			);
		}
	}
	
	@Override
	protected void onDestroy() {
		super.onDestroy();
		
		webView.clearHistory();
		webView.clearCache(true);
		webView.destroy();
		webView = null;
	}
	
	@Override
	protected void onActivityResult(int requestCode, int resultCode, Intent data) {
		super.onActivityResult(requestCode, resultCode, data);
	}
	
	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		if (item.getItemId() == android.R.id.home) {
			finish();
		}
		
		return super.onOptionsItemSelected(item);
	}
	
	@Override
	public void onBackPressed() {
		goBack();
	}
	
	protected void goBack() {
		if (webView.canGoBack()) {
			webView.goBack();
		} else {
			showCancelAlert();
		}
	}
	
	protected void showCancelAlert() {
		new AlertDialog.Builder(this)
				.setTitle("")
				.setMessage("결제를 취소하시겠습니까?")
				.setPositiveButton("확인", (dialogInterface, i) -> NicepayActivity.super.onBackPressed())
				.setNegativeButton("취소", (dialogInterface, i) -> {
				})
				.create()
				.show();
	}
	
	protected int colorSelector(String string) {
		return colorSelector(string, Color.BLACK);
	}
	
	protected int colorSelector(String string, int defaultColor) {
		try {
			return Color.class.getField(string).getInt(null);
		} catch (NoSuchFieldException | IllegalAccessException e1) {
			if (string.startsWith("#"))
				string = string.replace("#", "");
			
			if (isHexString(string))
				try {
					return Color.parseColor("#" + string);
				} catch (IllegalArgumentException e2) {
					return defaultColor;
				}
			
			return defaultColor;
		}
	}
	
	protected boolean isHexString(String str) {
		return str.matches("^[0-9A-Fa-f]+$");
	}
	
	protected boolean parseBoolean(Object object) {
		return new ArrayList<>(Arrays.asList("1", "true", "yes")).contains(String.valueOf(object));
	}
	
	public class NicepayBridge {
		@JavascriptInterface
		public void getBody(String body) {
			nicepayWebViewClient.nextBody = body;
		}
	}
}