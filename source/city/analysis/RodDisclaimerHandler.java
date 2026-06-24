/**
 * RodDisclaimerHandler — Programmatically accepts the Durham County ROD disclaimer
 * to access the document search page at rodweb.dconc.gov.
 *
 * The ROD site shows a disclaimer with a dynamic form (id ending in "-disclaimerForm").
 * This handler fetches the page, extracts the form action URL, POSTs to accept,
 * then follows through to the original search page.
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date June 24 2026 EST
 */

package city_analysis;

import commons.CommonRails;
import exceptions.ExceptionHandler;

import javax.net.ssl.*;
import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.regex.*;

public class RodDisclaimerHandler
{
    private static final String ROD_SEARCH_URL = "https://rodweb.dconc.gov/web/search/DOCSEARCH5S1";
    private static final String ROD_BASE = "https://rodweb.dconc.gov";

    private static final Pattern FORM_ACTION_PATTERN =
        Pattern.compile("id=[\"']SelfService-\\d+-disclaimerForm[\"'][^>]*action=[\"']([^\"']+)[\"']", Pattern.CASE_INSENSITIVE);
    private static final Pattern FORM_ACTION_ALT =
        Pattern.compile("\\$\\('#SelfService-\\d+-disclaimerForm'\\)\\.attr\\('action'\\)");
    private static final Pattern FORM_ID_PATTERN =
        Pattern.compile("id=[\"'](SelfService-\\d+-disclaimerForm)[\"']", Pattern.CASE_INSENSITIVE);
    private static final Pattern ACTION_ATTR_PATTERN =
        Pattern.compile("action=[\"']([^\"']+)[\"']", Pattern.CASE_INSENSITIVE);

    private String sessionCookie;

    /**
     * Returns the session cookie acquired during disclaimer acceptance.
     */
    public String getSessionCookie()
    {
        return sessionCookie;
    }

    /**
     * Fetches the ROD disclaimer page, accepts it, and returns the content of
     * the actual document search page (DOCSEARCH5S1).
     *
     * @return HTML content of the search page post-disclaimer, or null on failure
     */
    public String acceptAndFetch()
    {
        try
        {
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". CityAnalysis™ ROD disclaimer handler — fetching disclaimer page .");

            // Step 1: GET the disclaimer page, capture cookies
            String disclaimerHtml = httpGet(ROD_SEARCH_URL);
            if (disclaimerHtml == null) return null;

            // Step 2: Extract the form action URL
            String actionUrl = extractFormAction(disclaimerHtml);
            if (actionUrl == null)
            {
                // Page might already be past disclaimer (no form found)
                CommonRails.printSystemComponent(this, this.hashCode(),
                    ". CityAnalysis™ ROD no disclaimer detected — page already accessible .");
                return disclaimerHtml;
            }

            // Resolve relative action URL
            if (!actionUrl.startsWith("http")) actionUrl = ROD_BASE + actionUrl;

            CommonRails.printSystemComponent(this, this.hashCode(),
                ". CityAnalysis™ ROD disclaimer accepting — POST to " + actionUrl + " .");

            // Step 3: POST to accept the disclaimer
            String postResponse = httpPost(actionUrl);

            // Step 4: Follow through to original search page
            String searchHtml = httpGet(ROD_SEARCH_URL);

            CommonRails.printSystemComponent(this, this.hashCode(),
                ". CityAnalysis™ ROD disclaimer accepted — search page loaded .");

            return searchHtml;
        }
        catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
            return null;
        }
    }

    private String extractFormAction(String html)
    {
        // Try direct form tag with action
        Matcher m = FORM_ACTION_PATTERN.matcher(html);
        if (m.find()) return m.group(1);

        // Fallback: find the form by id, then look for action in nearby context
        Matcher idMatcher = FORM_ID_PATTERN.matcher(html);
        if (idMatcher.find())
        {
            int start = Math.max(0, idMatcher.start() - 200);
            int end = Math.min(html.length(), idMatcher.end() + 200);
            String context = html.substring(start, end);
            Matcher actionMatcher = ACTION_ATTR_PATTERN.matcher(context);
            if (actionMatcher.find()) return actionMatcher.group(1);
        }

        // Fallback: extract from JS — the form action is set via ajax submitUrl
        // Pattern: var submitUrl = $('#SelfService-NNNN-disclaimerForm').attr('action');
        // The actual action is on the form element; parse the form tag itself
        Pattern formTag = Pattern.compile("<form[^>]*id=[\"']SelfService-\\d+-disclaimerForm[\"'][^>]*>", Pattern.CASE_INSENSITIVE);
        Matcher ftMatcher = formTag.matcher(html);
        if (ftMatcher.find())
        {
            Matcher aMatcher = ACTION_ATTR_PATTERN.matcher(ftMatcher.group());
            if (aMatcher.find()) return aMatcher.group(1);
        }

        return null;
    }

    private String httpGet(String urlStr) throws Exception
    {
        HttpURLConnection conn = openConnection(urlStr);
        conn.setRequestMethod("GET");
        if (sessionCookie != null) conn.setRequestProperty("Cookie", sessionCookie);

        int code = conn.getResponseCode();
        captureCookies(conn);

        if (code == 200) return readBody(conn);
        if (code == 302 || code == 301)
        {
            String loc = conn.getHeaderField("Location");
            if (loc != null)
            {
                if (!loc.startsWith("http")) loc = ROD_BASE + loc;
                return httpGet(loc);
            }
        }
        return null;
    }

    private String httpPost(String urlStr) throws Exception
    {
        HttpURLConnection conn = openConnection(urlStr);
        conn.setRequestMethod("POST");
        conn.setDoOutput(true);
        conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
        if (sessionCookie != null) conn.setRequestProperty("Cookie", sessionCookie);
        conn.setInstanceFollowRedirects(false);

        try (OutputStream os = conn.getOutputStream()) { os.write(new byte[0]); }

        int code = conn.getResponseCode();
        captureCookies(conn);

        if (code == 200) return readBody(conn);
        if (code == 302 || code == 301)
        {
            String loc = conn.getHeaderField("Location");
            if (loc != null)
            {
                if (!loc.startsWith("http")) loc = ROD_BASE + loc;
                return httpGet(loc);
            }
        }
        return readBody(conn);
    }

    private HttpURLConnection openConnection(String urlStr) throws Exception
    {
        URL url = new URL(urlStr);
        if ("https".equalsIgnoreCase(url.getProtocol()))
        {
            HttpsURLConnection httpsConn = (HttpsURLConnection) url.openConnection();
            TrustManager[] trustAll = new TrustManager[]{
                new X509TrustManager()
                {
                    public java.security.cert.X509Certificate[] getAcceptedIssuers() { return null; }
                    public void checkClientTrusted(java.security.cert.X509Certificate[] c, String a) {}
                    public void checkServerTrusted(java.security.cert.X509Certificate[] c, String a) {}
                }
            };
            SSLContext ctx = SSLContext.getInstance("TLS");
            ctx.init(null, trustAll, new SecureRandom());
            httpsConn.setSSLSocketFactory(ctx.getSocketFactory());
            httpsConn.setHostnameVerifier((h, s) -> true);
            httpsConn.setConnectTimeout(15000);
            httpsConn.setReadTimeout(15000);
            httpsConn.setRequestProperty("User-Agent", "NitroWebExpress/CityAnalysis 1.0");
            httpsConn.setInstanceFollowRedirects(false);
            return httpsConn;
        }
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setConnectTimeout(15000);
        conn.setReadTimeout(15000);
        conn.setRequestProperty("User-Agent", "NitroWebExpress/CityAnalysis 1.0");
        conn.setInstanceFollowRedirects(false);
        return conn;
    }

    private void captureCookies(HttpURLConnection conn)
    {
        String cookies = conn.getHeaderField("Set-Cookie");
        if (cookies != null)
        {
            String cookie = cookies.split(";")[0];
            sessionCookie = (sessionCookie == null) ? cookie : sessionCookie + "; " + cookie;
        }
    }

    private String readBody(HttpURLConnection conn) throws IOException
    {
        InputStream is = (conn.getResponseCode() >= 400) ? conn.getErrorStream() : conn.getInputStream();
        if (is == null) return "";
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8)))
        {
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) sb.append(line).append("\n");
            return sb.toString();
        }
    }
}
