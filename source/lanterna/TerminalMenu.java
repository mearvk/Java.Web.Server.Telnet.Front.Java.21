package lanterna;

import com.googlecode.lanterna.SGR;
import com.googlecode.lanterna.TextColor;
import com.googlecode.lanterna.gui2.*;
import com.googlecode.lanterna.graphics.SimpleTheme;
import com.googlecode.lanterna.screen.Screen;
import com.googlecode.lanterna.screen.TerminalScreen;
import com.googlecode.lanterna.terminal.Terminal;
import com.googlecode.lanterna.terminal.ansi.TelnetTerminal;
import com.googlecode.lanterna.terminal.ansi.TelnetTerminalServer;
import com.googlecode.lanterna.terminal.ansi.UnixTerminal;

import java.io.IOException;
import java.nio.charset.Charset;

/**
 * TerminalMenu — Lanterna GUI menu for the 49152 port series.
 * Yellow background, black text buttons.
 *
 * Modes:
 *   - Telnet: listens on MENU_PORT (49200), presents GUI to each connecting telnet client
 *   - Local:  renders directly in the current gnome-terminal TTY
 */
public class TerminalMenu extends Thread
{
    public static final int MENU_PORT = 49200;

    public static final TextColor YELLOW = new TextColor.RGB(255, 255, 0);
    public static final TextColor BLACK  = TextColor.ANSI.BLACK;

    private int selectedPort = -1;

    public TerminalMenu()
    {
        this.setName("TerminalMenu-Lanterna");
        this.setDaemon(true);
    }

    /**
     * Telnet server loop — accepts connections and presents the menu GUI to each client.
     */
    @Override
    public void run()
    {
        try
        {
            TelnetTerminalServer server = new TelnetTerminalServer(MENU_PORT, Charset.defaultCharset());

            commons.CommonRails.printSystemComponent(this, this.hashCode(),
                ". TerminalMenu Lanterna telnet GUI listening on port " + MENU_PORT + " .");

            while (!Thread.currentThread().isInterrupted())
            {
                TelnetTerminal telnetTerminal = server.acceptConnection();

                Thread handler = new Thread(() -> {
                    try { runGui(telnetTerminal); }
                    catch (Exception e) { exceptions.ExceptionHandler.dispatch(e); }
                });
                handler.setDaemon(true);
                handler.start();
            }
        }
        catch (IOException e)
        {
            exceptions.ExceptionHandler.dispatch(e);
        }
    }

    /**
     * Launch menu locally in gnome-terminal.
     */
    public int launchLocal() throws IOException
    {
        UnixTerminal terminal = new UnixTerminal(
            System.in, System.out, Charset.defaultCharset()
        );
        return runGui(terminal);
    }

    private int runGui(Terminal terminal) throws IOException
    {
        Screen screen = new TerminalScreen(terminal);
        screen.startScreen();

        MultiWindowTextGUI gui = new MultiWindowTextGUI(screen, new DefaultWindowManager(), new EmptySpace(BLACK));

        BasicWindow window = new BasicWindow("NWE 49152 Port Series — Service Menu");
        window.setHints(java.util.Arrays.asList(Window.Hint.CENTERED));

        final int[] chosen = {-1};

        Panel panel = new Panel(new LinearLayout(Direction.VERTICAL));
        panel.addComponent(new EmptySpace());

        addMenuButton(panel, window, chosen, "WebExpress Base",           49152);
        addMenuButton(panel, window, chosen, "ConnectionStatusServer",    49155);
        addMenuButton(panel, window, chosen, "ModuleInstallationService", 49166);
        addMenuButton(panel, window, chosen, "ASCIICreatorServer",        49177);
        addMenuButton(panel, window, chosen, "ModuleLoaderDaemon",        49188);
        addMenuButton(panel, window, chosen, "Communicator",              49199);
        addMenuButton(panel, window, chosen, "BinaryHttpServer",          49144);
        addMenuButton(panel, window, chosen, "WeatherServer",             49133);

        panel.addComponent(new EmptySpace());

        Button exitButton = new Button("Exit", () -> { chosen[0] = -1; window.close(); });
        exitButton.setTheme(new SimpleTheme(BLACK, YELLOW, SGR.BOLD));
        panel.addComponent(exitButton);

        window.setComponent(panel);
        gui.addWindowAndWait(window);

        screen.stopScreen();
        terminal.close();

        return chosen[0];
    }

    private void addMenuButton(Panel panel, BasicWindow window, int[] chosen, String label, int port)
    {
        String text = "[" + port + "] " + label;
        Button button = new Button(text, () -> { chosen[0] = port; window.close(); });
        button.setTheme(new SimpleTheme(BLACK, YELLOW, SGR.BOLD));
        panel.addComponent(button);
    }

    /** Returns the last selected port, or -1. */
    public int getSelectedPort() { return selectedPort; }

    /** Standalone local gnome-terminal entry point. */
    public static void main(String[] args) throws Exception
    {
        TerminalMenu menu = new TerminalMenu();
        int port = menu.launchLocal();
        if (port > 0)
            System.out.println("Selected service on port: " + port);
        else
            System.out.println("Exited.");
    }
}
