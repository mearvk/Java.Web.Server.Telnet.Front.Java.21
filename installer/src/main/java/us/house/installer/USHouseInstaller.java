package us.house.installer;

import javafx.application.Application;
import javafx.geometry.Insets;
import javafx.scene.Scene;
import javafx.scene.control.*;
import javafx.scene.layout.*;
import javafx.stage.Stage;

/** Cross-platform JavaFX installer UI for Windows, macOS and Linux. */
public final class USHouseInstaller extends Application {
    private final CheckBox core = new CheckBox("1 — Core US House runtime");
    private final CheckBox tools = new CheckBox("2 — Software-house tools and conveniences");
    private final CheckBox configure = new CheckBox("3 — Configure after installation");
    private final CheckBox microsoft = new CheckBox("Microsoft software integration");
    private final CheckBox apple = new CheckBox("Apple software integration");
    private final CheckBox launch = new CheckBox("Launch after installation");
    private final TextArea log = new TextArea();

    @Override public void start(Stage stage) {
        core.setSelected(true); tools.setSelected(true); configure.setSelected(true);
        Label title = new Label("US House — Installation");
        title.setStyle("-fx-font-size:22px;-fx-font-weight:bold;");
        Label platform = new Label("Platform: " + System.getProperty("os.name") + " / " + System.getProperty("os.arch"));
        VBox order = new VBox(8, core, tools, configure);
        TitledPane integrations = new TitledPane("Software integrations", new VBox(8, microsoft, apple, launch));
        integrations.setExpanded(true);
        Button install = new Button("Install");
        Button close = new Button("Close");
        install.setDefaultButton(true); install.setOnAction(e -> plan()); close.setOnAction(e -> stage.close());
        log.setEditable(false); log.setPrefRowCount(10);
        log.setText("Select installation stages and configuration options.\n");
        VBox root = new VBox(14, title, platform, new Label("Installation order"), order,
                integrations, new Label("Installer output"), log, new HBox(8, install, close));
        root.setPadding(new Insets(18));
        stage.setTitle("US House Installer"); stage.setScene(new Scene(root, 620, 560)); stage.show();
    }

    private void plan() {
        log.clear();
        log.appendText("US House installation plan\n");
        log.appendText("1. Origin: installation request\n");
        if (core.isSelected()) log.appendText("  • Core runtime selected\n");
        if (tools.isSelected()) log.appendText("  • Tools/conveniences selected\n");
        if (configure.isSelected()) log.appendText("  • Post-install configuration selected\n");
        if (microsoft.isSelected()) log.appendText("  • Microsoft integration selected\n");
        if (apple.isSelected()) log.appendText("  • Apple integration selected\n");
        if (launch.isSelected()) log.appendText("  • Launch-after-install selected\n");
        log.appendText("2. Custody: selected installation targets\n");
        log.appendText("3. Production: platform launcher actions\n");
        log.appendText("4. Release: installation result and verification\n");
        log.appendText("\nGUI plan prepared. Privileged platform changes require the corresponding OS launcher.\n");
    }

    public static void main(String[] args) { launch(args); }
}
