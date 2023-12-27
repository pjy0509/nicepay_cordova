package kr.nicepay.cordova;

import android.app.AlertDialog;
import android.webkit.JsResult;
import android.webkit.WebChromeClient;
import android.webkit.WebView;

import java.net.MalformedURLException;
import java.net.URISyntaxException;
import java.net.URL;

public class NicepayWebChromeClient extends WebChromeClient {
    @Override
    public boolean onJsConfirm(WebView view, String url, String message, final JsResult result) {
        new AlertDialog.Builder(view.getContext())
                .setTitle(extractDomainFromUrl(url))
                .setMessage(message)
                .setPositiveButton(
                        android.R.string.ok,
                        (dialog, which) -> result.confirm()
                )
                .setNegativeButton(
                        android.R.string.cancel,
                        (dialog, which) -> result.cancel()
                )
                .create()
                .show();

        return true;
    }

    public String extractDomainFromUrl(String urlString) {
        try {
            URL url = new URL(urlString);
            return url.toURI().getScheme() + "://" + url.toURI().getAuthority();
        } catch (MalformedURLException | URISyntaxException e) {
            return null;
        }
    }
}