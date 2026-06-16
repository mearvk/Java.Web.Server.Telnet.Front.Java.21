package server.nitro.modules;

import commons.CommonRails;
import database.N21Store;
import exceptions.ExceptionHandler;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;

public class ASCIICreatorServer extends Thread
{
    public static final int PORT = 49177;
    private final String HOST;
    private ServerSocket SERVER_SOCKET;

    public ASCIICreatorServer(final String HOST)
    {
        if (HOST == null) throw new commons.security.BodiSecurityException("//bodi/connect", Thread.currentThread().getStackTrace()[1]);

        this.HOST = HOST;

        this.setName("ASCIICreatorServer");

        this.setDaemon(true);
    }

    @Override
    public void run()
    {
        try
        {
            N21Store.createAsciiSignaturesTable();

            SERVER_SOCKET = new ServerSocket(PORT, 64, InetAddress.getByName(HOST));

            CommonRails.printSystemComponent(this, this.hashCode(), ". ASCIICreatorServer listening on port " + PORT + " .");

            while (!Thread.currentThread().isInterrupted())
            {
                Socket client = SERVER_SOCKET.accept();

                Thread h = new Thread(() -> handle(client));

                h.setDaemon(true);

                h.start();
            }
        }
        catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
        }
    }

    private void handle(final Socket CLIENT)
    {
        try (
                BufferedReader in  = new BufferedReader(new InputStreamReader(CLIENT.getInputStream()));
                BufferedWriter out = new BufferedWriter(new OutputStreamWriter(CLIENT.getOutputStream()))
        ) {
            writeLine(out, "[ NWE port " + PORT + " — ASCII Signature Service  |  issues unique binary ASCII signatures per National ID ]");
            writeLine(out, "ASCIICreatorServer — Binary ASCII Signature Service");
            writeLine(out, "Commands: request <nationalId>  |  view <nationalId>  |  quit");

            String line;
            while ((line = in.readLine()) != null)
            {
                line = line.trim();
                if (line.isEmpty()) continue;
                if (line.equalsIgnoreCase("quit") || line.equalsIgnoreCase("exit")) break;

                String[] parts = line.split("\\s+", 2);
                switch (parts[0].toLowerCase())
                {
                    case "request":
                        if (parts.length < 2) { writeLine(out, "Usage: request <nationalId>"); break; }
                        writeLine(out, handleRequest(parts[1], CLIENT.getInetAddress().getHostAddress()));
                        break;
                    case "view":
                        if (parts.length < 2) { writeLine(out, "Usage: view <nationalId>"); break; }
                        writeLine(out, handleView(parts[1]));
                        break;
                    case "lang":
                        if (parts.length < 2) { writeLine(out, "Usage: lang <code>  (" + languages.LanguagePack.SUPPORTED + ")"); break; }
                        writeLine(out, languages.LanguagePack.handleLangCommand(CLIENT.getInetAddress().getHostAddress(), parts[1]));
                        break;
                    default:
                        writeLine(out, "Unknown command. Use: request <nationalId> | view <nationalId> | lang <code> | quit");
                }
            }
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); }
        finally { try { CLIENT.close(); } catch (Exception ignored) {} }
    }

    private String handleRequest(final String NATIONAL_ID_STR, final String SOURCE_IP)
    {
        try
        {
            long nationalId = Long.parseLong(NATIONAL_ID_STR);

            // Verify national ID exists
            national.NationalFinanceID profile = N21Store.loadNationalFinanceID(nationalId);
            if (profile == null) return "[request] National ID " + nationalId + " not found.";

            // Check for existing valid (non-expired) signature
            java.sql.ResultSet existing = N21Store.loadAsciiSignature(nationalId);
            if (existing != null)
            {
                String grid    = existing.getString("ascii_grid");
                String expires = existing.getString("expires_at");
                existing.close();
                return "[request] You already have a valid signature (expires " + expires + ").\r\n" + grid;
            }

            // Assign the next available unique sig_id
            int sigId = N21Store.nextAsciiSigId();
            if (sigId >= (1 << 21))
                return "[request] Signature space exhausted — contact administrator.";

            String grid = ascii.creator.ASCIICreator.generateAsciiCode(sigId);
            N21Store.storeAsciiSignature(nationalId, sigId, grid);

            CommonRails.printSystemComponent(this, this.hashCode(),
                    ". ASCIICreatorServer issued sig_id=" + sigId
                            + " to National ID " + nationalId + " from " + SOURCE_IP + " .");

            return "[request] Binary ASCII signature issued (sig_id=" + sigId
                    + ", valid 1000 days).\r\n" + grid;
        }
        catch (NumberFormatException e) { return "[request] Invalid National ID."; }
        catch (Exception e) { ExceptionHandler.dispatch(e); return "[request] Error: " + e.getMessage(); }
    }

    private String handleView(final String NATIONAL_ID_STR)
    {
        try
        {
            long nationalId = Long.parseLong(NATIONAL_ID_STR);
            java.sql.ResultSet rs = database.N21Store.loadAsciiSignature(nationalId);
            if (rs == null) return "[view] No valid signature for National ID " + nationalId
                    + ". Use: request <nationalId>";
            String grid    = rs.getString("ascii_grid");
            String issued  = rs.getString("issued_at");
            String expires = rs.getString("expires_at");
            rs.close();
            return "[view] National ID " + nationalId + " | issued=" + issued
                    + " | expires=" + expires + "\r\n" + grid;
        }
        catch (NumberFormatException e) { return "[view] Invalid National ID."; }
        catch (Exception e) { ExceptionHandler.dispatch(e); return "[view] Error: " + e.getMessage(); }
    }

    private static void writeLine(final BufferedWriter OUT, final String LINE)
    {
        try { OUT.write(LINE + "\r\n"); OUT.flush(); } catch (Exception ignored) {}
    }
}