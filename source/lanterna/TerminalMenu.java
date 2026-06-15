package lanterna;

import com.googlecode.lanterna.TextColor;
import com.googlecode.lanterna.gui2.*;
import com.googlecode.lanterna.gui2.dialogs.MessageDialog;
import com.googlecode.lanterna.screen.Screen;
import com.googlecode.lanterna.screen.TerminalScreen;
import com.googlecode.lanterna.terminal.DefaultTerminalFactory;
import com.googlecode.lanterna.terminal.Terminal;
import com.googlecode.lanterna.SGR;

/**
 * TerminalMenu — Lanterna-based terminal GUI with yellow/black menu buttons
 * for the 49152 port series services.
 */
public class TerminalMenu
{
    public static final TextColor YELLOW = new TextColor.RGB(255, 255, 0);
    public static final TextColor BLACK  = TextColor.ANSI.BLACK;

    private Screen screen;
    private MultiWindowTextGUI gui;

    public void launch() throws Exception
    {
        Terminal terminal = new DefaultTerminalFactory().createTerminal();
        screen = new TerminalScreen(terminal);
        screen.startScreen();

        gui = new MultiWindowTextGUI(screen, new DefaultWindowManager(), new EmptySpace(TextColor.ANSI.BLACK));

        BasicWindow window = new BasicWindow("NWE 49152 Port Series — Service Menu");
        window.setHints(java.util.Arrays.asList(Window.Hint.CENTERED));

        Panel panel = new Panel(new LinearLayout(Direction.VERTICAL));
        panel.addComponent(new EmptySpace());

        addMenuButton(panel, "WebExpress Base",           49152);
        addMenuButton(panel, "ConnectionStatusServer",    49155);
        addMenuButton(panel, "ModuleInstallationService", 49166);
        addMenuButton(panel, "ASCIICreatorServer",        49177);
        addMenuButton(panel, "ModuleLoaderDaemon",        49188);
        addMenuButton(panel, "Communicator",              49199);
        addMenuButton(panel, "BinaryHttpServer",          49144);
        addMenuButton(panel, "WeatherServer",             49133);

        panel.addComponent(new EmptySpace());

        Button exitButton = new Button("Exit", () -> window.close());
        exitButton.setTheme(buildYellowTheme());
        panel.addComponent(exitButton);

        window.setComponent(panel);
        gui.addWindowAndWait(window);

        screen.stopScreen();
    }

    private void addMenuButton(Panel panel, String label, int port)
    {
        String text = "[" + port + "] " + label;
        Button button = new Button(text, () ->
            MessageDialog.showMessageDialog(gui, "Connect", "Connecting to " + label + " on port " + port + "...")
        );
        button.setTheme(buildYellowTheme());
        panel.addComponent(button);
    }

    private com.googlecode.lanterna.graphics.Theme buildYellowTheme()
    {
        return com.googlecode.lanterna.bundle.LanternaThemes.getRegisteredTheme("default")
            != null ? new com.googlecode.lanterna.graphics.SimpleTheme(BLACK, YELLOW, SGR.BOLD)
                    : new com.googlecode.lanterna.graphics.SimpleTheme(BLACK, YELLOW, SGR.BOLD);
    }

    public static void main(String[] args) throws Exception
    {
        new TerminalMenu().launch();
    }
}
