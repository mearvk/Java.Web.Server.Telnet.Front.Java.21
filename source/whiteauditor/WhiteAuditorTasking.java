package whiteauditor;

import commons.CommonRails;
import exceptions.ExceptionHandler;

import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.sql.ResultSet;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * WhiteAuditorTasking – secure task‑assignment server on port 49122.
 *
 * Supports:
 *   identify <nationalId>
 *   assign-file <toId> <filename> <base64>
 *   assign-bits <toId> <size> <base64>
 *   assign-signatory <toId> <symbol>
 *   list-tasks <toId>
 *   get-task <taskId>
 *   remove-task <taskId>
 *   quit
 *
 * Sessions expire after 1 hour.
 *
 * @author Max Rupplin
 * @date June 2026
 */
public class WhiteAuditorTasking extends Thread
{
    public static final int PORT = 49122;
    private static final long SESSION_LIMIT_MS = 60 * 60 * 1000L;

    public final String HOST;
    public ServerSocket SERVERSOCKET;

    /** nationalId → live session */
    static final Map<String, Session> LIVE = new ConcurrentHashMap<>();

    public WhiteAuditorTasking(final String host)
    {
        if (host == null) throw new SecurityException("//bodi/connect");

        this.HOST = host;

        this.setName("WhiteAuditorTasking");

        this.setDaemon(true);
    }

    @Override
    public void run()
    {
        try
        {
            database.N21Store.createWhiteAuditorTables();

            this.SERVERSOCKET = new ServerSocket(PORT, 64, InetAddress.getByName(HOST));

            CommonRails.printSystemComponent(this, this.hashCode(), ". WhiteAuditorTasking listening on port " + PORT + " .");

            while(!Thread.currentThread().isInterrupted())
            {
                Socket client = this.SERVERSOCKET.accept();

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

    static final class Session
    {
        public final String IP;
        public final long CONNECTEDAT = System.currentTimeMillis();
        public long NATIONALID = -1;

        public BufferedWriter OUT;

        Session(String IP)
        {
            this.IP = IP;
        }

        boolean expired()
        {
            return System.currentTimeMillis() - CONNECTEDAT > SESSION_LIMIT_MS;
        }

        void writeLine(String line)
        {
            try
            {
                this.OUT.write(line + "\r\n");
                
                this.OUT.flush();
            }
            catch (Exception ignored)
            {
                ExceptionHandler.dispatch(ignored);
            }
        }
    }

    // -------------------------------------------------------------------------
    // Connection handler
    // -------------------------------------------------------------------------

    private void handle(final Socket client)
    {
        Session session = new Session(client.getInetAddress().getHostAddress());

        try
        (
                BufferedReader in  = new BufferedReader(new InputStreamReader(client.getInputStream(), StandardCharsets.UTF_8));

                BufferedWriter out = new BufferedWriter(new OutputStreamWriter(client.getOutputStream(), StandardCharsets.UTF_8))
        )
        {
            session.OUT = out;

            writeLine(out, "WhiteAuditorTasking server on port " + PORT);

            writeLine(out, "identify <nationalId> to begin");

            client.setSoTimeout(10_000);

            String line;

            while ((line = readLine(in)) != null)
            {
                if (session.expired())
                {
                    writeLine(out, "[WAT] Session expired (1-hour limit).");
                    break;
                }

                line = line.trim();

                if (line.isEmpty()) continue;

                if (line.equalsIgnoreCase("quit")) break;

                String[] parts = line.split("\\s+", 4);

                String cmd = parts[0].toLowerCase();

                if (cmd.equals("identify") && session.NATIONALID < 0)
                {
                    if (parts.length < 2)
                    {
                        writeLine(out, "Usage: identify <nationalId>"); continue;
                    }

                    writeLine(out, cmdIdentify(parts[1], session));

                    continue;
                }

                if (session.NATIONALID < 0)
                {
                    writeLine(out, "Identify first: identify <nationalId>");

                    continue;
                }

                switch (cmd)
                {
                    case "assign-file"      -> writeLine(out, cmdAssignFile(parts, line, session));

                    case "assign-bits"      -> writeLine(out, cmdAssignBits(parts, line, session));

                    case "assign-signatory" -> writeLine(out, cmdAssignSignatory(parts, line, session));

                    case "list-tasks"       -> writeLine(out, cmdListTasks(parts));

                    case "get-task"         -> writeLine(out, cmdGetTask(parts));

                    case "remove-task"      -> writeLine(out, cmdRemoveTask(parts));

                    default -> writeLine(out, "Unknown command.\r\n" + HELP);
                }
            }
        }
        catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
        }
        finally
        {
            if (session.NATIONALID >= 0)
            {
                LIVE.remove(String.valueOf(session.NATIONALID));
            }

            try
            {
                client.close();
            }
            catch (Exception ignored)
            {
                ExceptionHandler.dispatch(ignored);
            }
        }
    }

    private String cmdIdentify(String idStr, Session session) {
        try
        {
            long id = Long.parseLong(idStr);

            var profile = database.N21Store.loadNationalFinanceID(id);

            if (profile == null) return "[identify] National ID not found.";

            session.NATIONALID = id;

            LIVE.put(idStr, session);

            return "[identify] Welcome, National ID " + id + ".\r\n" + HELP;
        }
        catch (Exception e)
        {
            return "[identify] Invalid National ID.";
        }
    }

    private String cmdAssignFile(String[] parts, String raw, Session from) throws Exception
    {
        if (parts.length < 4)
        {
            return "Usage: assign-file <toId> <filename> <base64>";
        }

        String toId = parts[1];

        String filename = parts[2];

        String base64 = raw.substring(raw.indexOf(filename) + filename.length()).trim();

        database.N21Store.storeAssignedFile(from.NATIONALID, Long.parseLong(toId), filename, base64);

        return "[assign-file] Stored file for " + toId + ".";
    }

    private String cmdAssignBits(String[] parts, String raw, Session from)
    {
        if (parts.length < 4)
        {
            return "Usage: assign-bits <toId> <size> <base64>";
        }

        String toId = parts[1];

        int size = Integer.parseInt(parts[2]);

        if (size > 8_000_000) return "[assign-bits] Max size is 8MB.";

        String base64 = raw.substring(raw.indexOf(parts[2]) + parts[2].length()).trim();

        database.N21Store.storeAssignedBits(from.NATIONALID, Long.parseLong(toId), size, base64);

        return "[assign-bits] Stored " + size + " bytes for " + toId + ".";
    }

    private String cmdAssignSignatory(String[] parts, String raw, Session from)
    {
        if (parts.length < 3)
        {
            return "Usage: assign-signatory <toId> <symbol>";
        }

        String toId = parts[1];

        String symbol = raw.substring(raw.indexOf(toId) + toId.length()).trim();

        database.N21Store.storeAssignedSignatory(from.NATIONALID, Long.parseLong(toId), symbol);

        return "[assign-signatory] Stored signatory for " + toId + ".";
    }

    private String cmdListTasks(String[] parts)
    {
        if (parts.length < 2) return "Usage: list-tasks <toId>";

        try
        {
            ResultSet rs = database.N21Store.loadTasksFor(Long.parseLong(parts[1]));

            if (rs == null) return "[list-tasks] No tasks.";

            StringBuilder sb = new StringBuilder("[list-tasks]\r\n");

            while (rs.next())
            {
                sb.append("  Task ").append(rs.getLong("id"))
                        .append("  Type=").append(rs.getString("type"))
                        .append("  From=").append(rs.getLong("from_national_id"))
                        .append("\r\n");
            }

            rs.close();

            return sb.toString().stripTrailing();
        }
        catch (Exception e)
        {
            return "[list-tasks] Error: " + e.getMessage();
        }
    }

    private String cmdGetTask(String[] parts)
    {
        if (parts.length < 2) return "Usage: get-task <taskId>";

        try
        {
            ResultSet rs = database.N21Store.loadTask(Long.parseLong(parts[1]));

            if (rs == null || !rs.next()) return "[get-task] Not found.";

            return "[get-task]\r\nType=" + rs.getString("type") + "\r\nPayload=" + rs.getString("payload");
        }
        catch (Exception e)
        {
            return "[get-task] Error: " + e.getMessage();
        }
    }

    private String cmdRemoveTask(String[] parts)
    {
        if (parts.length < 2) return "Usage: remove-task <taskId>";

        try
        {
            database.N21Store.deleteTask(Long.parseLong(parts[1]));

            return "[remove-task] Removed.";
        }
        catch (Exception e)
        {
            return "[remove-task] Error: " + e.getMessage();
        }
    }

    // -------------------------------------------------------------------------
    // IO helpers
    // -------------------------------------------------------------------------

    private static String readLine(BufferedReader in)
    {
        try
        {
            return in.readLine();
        }
        catch (SocketTimeoutException e)
        {
            return "";
        }
        catch (Exception e)
        {
            return null;
        }
    }

    private static void writeLine(BufferedWriter out, String line)
    {
        try
        {
            out.write(line + "\r\n"); out.flush();
        }
        catch
        (Exception ignored)
        {
            ExceptionHandler.dispatch(ignored);
        }
    }

    // -------------------------------------------------------------------------
    // Help
    // -------------------------------------------------------------------------

    private static final String HELP =
            "Commands:\r\n" +
                    "  assign-file <toId> <filename> <base64>\r\n" +
                    "  assign-bits <toId> <size> <base64>\r\n" +
                    "  assign-signatory <toId> <symbol>\r\n" +
                    "  list-tasks <toId>\r\n" +
                    "  get-task <taskId>\r\n" +
                    "  remove-task <taskId>\r\n" +
                    "  quit";
}
