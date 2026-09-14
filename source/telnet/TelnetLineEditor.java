package telnet;

import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.List;

/**
 * TelnetLineEditor — provides readline-style editing for telnet connections.
 *
 * Supports:
 *   Up/Down arrow   — command history navigation
 *   Left/Right arrow — cursor movement within current line
 *   Backspace/Delete — character deletion
 *
 * Operates on raw telnet streams (char-at-a-time mode).
 * Maintains per-instance history.
 */
public class TelnetLineEditor
{
    private final List<String> history = new ArrayList<>();
    private int historyIndex = 0;
    private static final int MAX_HISTORY = 100;

    // Telnet control
    private static final byte IAC  = (byte) 255;
    private static final byte WILL = (byte) 251;
    private static final byte WONT = (byte) 252;
    private static final byte DO   = (byte) 253;
    private static final byte DONT = (byte) 254;
    private static final byte SGA  = (byte) 3;   // Suppress Go Ahead
    private static final byte ECHO = (byte) 1;

    /**
     * Send telnet negotiation to put client in character mode (no local echo, no line buffering).
     */
    public void enableCharMode(OutputStream out)
    {
        try
        {
            // IAC WILL ECHO — server will echo
            out.write(new byte[]{IAC, WILL, ECHO});
            // IAC WILL SGA — suppress go-ahead (char-at-a-time)
            out.write(new byte[]{IAC, WILL, SGA});
            // IAC DO SGA — ask client to suppress go-ahead
            out.write(new byte[]{IAC, DO, SGA});
            out.flush();
        }
        catch (Exception ignored) {}
    }

    /**
     * Read a line with arrow key support. Handles:
     *   ESC[A (up), ESC[B (down) — history
     *   ESC[C (right), ESC[D (left) — cursor
     *   Backspace (127, 8) — delete char
     *   Enter (13, 10) — submit
     */
    public String readLine(InputStream in, OutputStream out, String promptText)
    {
        try
        {
            out.write(promptText.getBytes());
            out.flush();

            StringBuilder line = new StringBuilder();
            int cursor = 0;
            historyIndex = history.size();

            while (true)
            {
                int b = in.read();
                if (b == -1) return null;

                // Skip telnet IAC negotiation sequences
                if (b == 255)
                {
                    int cmd = in.read();
                    if (cmd == -1) return null;
                    if (cmd >= 251 && cmd <= 254) in.read(); // consume option byte
                    continue;
                }

                // Enter
                if (b == 13)
                {
                    int peek = in.read(); // consume LF if present
                    if (peek != 10 && peek != -1 && peek != 0) { /* push back not possible, ignore */ }
                    out.write("\r\n".getBytes());
                    out.flush();
                    String result = line.toString();
                    if (!result.trim().isEmpty())
                    {
                        history.add(result);
                        if (history.size() > MAX_HISTORY) history.removeFirst();
                    }
                    return result;
                }
                if (b == 10) // bare LF
                {
                    out.write("\r\n".getBytes());
                    out.flush();
                    String result = line.toString();
                    if (!result.trim().isEmpty())
                    {
                        history.add(result);
                        if (history.size() > MAX_HISTORY) history.removeFirst();
                    }
                    return result;
                }

                // Escape sequence
                if (b == 27)
                {
                    int next = in.read();
                    if (next == '[')
                    {
                        int code = in.read();
                        switch (code)
                        {
                            case 'A' -> // Up arrow — previous history
                            {
                                if (historyIndex > 0)
                                {
                                    historyIndex--;
                                    replaceLine(out, line, cursor, history.get(historyIndex));
                                    line = new StringBuilder(history.get(historyIndex));
                                    cursor = line.length();
                                }
                            }
                            case 'B' -> // Down arrow — next history
                            {
                                if (historyIndex < history.size() - 1)
                                {
                                    historyIndex++;
                                    replaceLine(out, line, cursor, history.get(historyIndex));
                                    line = new StringBuilder(history.get(historyIndex));
                                    cursor = line.length();
                                }
                                else
                                {
                                    historyIndex = history.size();
                                    replaceLine(out, line, cursor, "");
                                    line = new StringBuilder();
                                    cursor = 0;
                                }
                            }
                            case 'C' -> // Right arrow
                            {
                                if (cursor < line.length())
                                {
                                    cursor++;
                                    out.write("\033[C".getBytes());
                                    out.flush();
                                }
                            }
                            case 'D' -> // Left arrow
                            {
                                if (cursor > 0)
                                {
                                    cursor--;
                                    out.write("\033[D".getBytes());
                                    out.flush();
                                }
                            }
                        }
                    }
                    continue;
                }

                // Backspace (127 or 8)
                if (b == 127 || b == 8)
                {
                    if (cursor > 0)
                    {
                        line.deleteCharAt(cursor - 1);
                        cursor--;
                        // Redraw: move back, print rest of line + space, reposition cursor
                        out.write("\b".getBytes());
                        String tail = line.substring(cursor) + " ";
                        out.write(tail.getBytes());
                        // Move cursor back to position
                        for (int i = 0; i < tail.length(); i++) out.write("\b".getBytes());
                        out.flush();
                    }
                    continue;
                }

                // Regular printable character
                if (b >= 32 && b < 127)
                {
                    line.insert(cursor, (char) b);
                    cursor++;
                    // Echo: print from cursor position to end, then reposition
                    String tail = line.substring(cursor - 1);
                    out.write(tail.getBytes());
                    // Move cursor back to correct position
                    for (int i = 1; i < tail.length(); i++) out.write("\b".getBytes());
                    out.flush();
                }
            }
        }
        catch (Exception e) { return null; }
    }

    /** Clear current display line and replace with new text. */
    private void replaceLine(OutputStream out, StringBuilder oldLine, int cursor, String newText)
    {
        try
        {
            // Move to start of input
            for (int i = 0; i < cursor; i++) out.write("\b".getBytes());
            // Overwrite with spaces
            for (int i = 0; i < oldLine.length(); i++) out.write(" ".getBytes());
            // Move back to start
            for (int i = 0; i < oldLine.length(); i++) out.write("\b".getBytes());
            // Write new text
            out.write(newText.getBytes());
            out.flush();
        }
        catch (Exception ignored) {}
    }
}
