package source.gov;

import java.io.*;
import java.net.*;
import java.net.http.*;
import java.net.http.HttpResponse.BodyHandlers;
import java.time.Duration;

/**
 * USPSClient — USPS Web Tools API Client for Brarner.M.Alete™
 *
 * Communicates with USPS Address Information APIs via HTTPS GET.
 * XML request payload passed in query string parameter &XML=...
 *
 * APIs supported:
 *   - Verify (Address Validation / Standardization)
 *   - ZipCodeLookup (Address → ZIP+4)
 *   - CityStateLookup (ZIP → City/State)
 *
 * Scope: Township → City → County → State → National
 *
 * Registration: https://www.usps.com/business/web-tools-apis/
 * Requires USPS Web Tools USERID (set via env USPS_USERID or config).
 *
 * Installer Tech ID: Max Rupplin
 * MEARVK LLC — NitroWebExpress™ 2026
 */
public class USPSClient {

    private static final String ENDPOINT = "https://secure.shippingapis.com/ShippingAPI.dll";
    private static final Duration TIMEOUT = Duration.ofSeconds(10);

    private final String userId;
    private final HttpClient client;

    public USPSClient(String userId) {
        this.userId = userId;
        this.client = HttpClient.newBuilder()
                .connectTimeout(TIMEOUT)
                .build();
    }

    public USPSClient() {
        this(System.getenv("USPS_USERID") != null ? System.getenv("USPS_USERID") : "XXXXXXXXXX");
    }

    /**
     * Verify (Standardize) an address.
     * Returns XML response with corrected address fields.
     *
     * @param address2 Street address (required) — e.g. "555 South Mangum St"
     * @param city     City (optional if ZIP provided) — e.g. "Durham"
     * @param state    Two-letter state code — e.g. "NC"
     * @param zip5     5-digit ZIP (optional if city+state provided) — e.g. "27701"
     * @return XML response string from USPS
     */
    public String verifyAddress(String address1, String address2, String city, String state, String zip5, String zip4) throws Exception {
        String xml = "<AddressValidateRequest USERID=\"" + userId + "\">" +
                "<Revision>1</Revision>" +
                "<Address ID=\"0\">" +
                "<FirmName/>" +
                "<Address1>" + esc(address1) + "</Address1>" +
                "<Address2>" + esc(address2) + "</Address2>" +
                "<City>" + esc(city) + "</City>" +
                "<State>" + esc(state) + "</State>" +
                "<Urbanization/>" +
                "<Zip5>" + esc(zip5) + "</Zip5>" +
                "<Zip4>" + esc(zip4) + "</Zip4>" +
                "</Address>" +
                "</AddressValidateRequest>";
        return callApi("Verify", xml);
    }

    /**
     * Shorthand: verify with minimal fields.
     */
    public String verifyAddress(String street, String city, String state, String zip) throws Exception {
        return verifyAddress("", street, city, state, zip, "");
    }

    /**
     * ZIP Code Lookup — given an address, returns the ZIP+4.
     */
    public String zipCodeLookup(String address2, String city, String state) throws Exception {
        String xml = "<ZipCodeLookupRequest USERID=\"" + userId + "\">" +
                "<Address ID=\"0\">" +
                "<Address1/>" +
                "<Address2>" + esc(address2) + "</Address2>" +
                "<City>" + esc(city) + "</City>" +
                "<State>" + esc(state) + "</State>" +
                "<Zip5/><Zip4/>" +
                "</Address>" +
                "</ZipCodeLookupRequest>";
        return callApi("ZipCodeLookup", xml);
    }

    /**
     * City/State Lookup — given a ZIP, returns city and state.
     * Use for township/city identification from postal code.
     */
    public String cityStateLookup(String zip5) throws Exception {
        String xml = "<CityStateLookupRequest USERID=\"" + userId + "\">" +
                "<ZipCode ID=\"0\">" +
                "<Zip5>" + esc(zip5) + "</Zip5>" +
                "</ZipCode>" +
                "</CityStateLookupRequest>";
        return callApi("CityStateLookup", xml);
    }

    /**
     * Batch city/state lookup — up to 5 ZIP codes per request.
     */
    public String cityStateLookupBatch(String... zips) throws Exception {
        StringBuilder xml = new StringBuilder("<CityStateLookupRequest USERID=\"" + userId + "\">");
        int count = Math.min(zips.length, 5);
        for (int i = 0; i < count; i++) {
            xml.append("<ZipCode ID=\"").append(i).append("\"><Zip5>").append(esc(zips[i])).append("</Zip5></ZipCode>");
        }
        xml.append("</CityStateLookupRequest>");
        return callApi("CityStateLookup", xml.toString());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Internal
    // ═══════════════════════════════════════════════════════════════════════

    private String callApi(String apiName, String xml) throws Exception {
        String url = ENDPOINT + "?API=" + apiName + "&XML=" + URLEncoder.encode(xml, "UTF-8");
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .GET()
                .timeout(TIMEOUT)
                .build();
        HttpResponse<String> response = client.send(request, BodyHandlers.ofString());
        if (response.statusCode() != 200) {
            throw new IOException("USPS API returned HTTP " + response.statusCode());
        }
        return response.body();
    }

    private static String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Quick test
    // ═══════════════════════════════════════════════════════════════════════
    public static void main(String[] args) throws Exception {
        USPSClient usps = new USPSClient();
        System.out.println("=== USPS Address Verify ===");
        System.out.println(usps.verifyAddress("555 South Mangum St", "Durham", "NC", "27701"));
        System.out.println("\n=== City/State from ZIP ===");
        System.out.println(usps.cityStateLookup("27701"));
        System.out.println("\n=== ZIP Lookup ===");
        System.out.println(usps.zipCodeLookup("555 South Mangum St", "Durham", "NC"));
    }
}
