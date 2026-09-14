package middle.director;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

/**
 * PublicKeyVerifier — checks that psychiatry/secrets/public.key exists
 * on github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21.
 *
 * If the public.key is up (HTTP 200), the software is free to operate
 * within existing guidelines, agreements, and contracts.
 *
 * A local copy of both key files (public.key and secret.key) is kept
 * by the Owner of the Software. The secret.key is never pushed to GitHub.
 */
public class PublicKeyVerifier
{
    private static final String RAW_URL =
        "https://raw.githubusercontent.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/main/psychiatry/secrets/public.key";

    private static boolean VERIFIED = false;

    /** Check if public.key is present on GitHub. */
    public static boolean verify()
    {
        try
        {
            HttpRequest req = HttpRequest.newBuilder()
                .uri(URI.create(RAW_URL))
                .method("HEAD", HttpRequest.BodyPublishers.noBody())
                .build();

            HttpResponse<Void> resp = HttpClient.newHttpClient()
                .send(req, HttpResponse.BodyHandlers.discarding());

            VERIFIED = resp.statusCode() == 200;
        }
        catch (Exception e)
        {
            VERIFIED = false;
        }

        if (VERIFIED)
            commons.CommonRails.printSystemComponent(new PublicKeyVerifier(), 0,
                ". PublicKeyVerifier: public.key confirmed on GitHub — software authorized to operate .");
        else
            commons.CommonRails.printSystemComponent(new PublicKeyVerifier(), 0,
                ". PublicKeyVerifier: public.key NOT found on GitHub — operating in restricted mode .");

        return VERIFIED;
    }

    public static boolean isVerified() { return VERIFIED; }
}
