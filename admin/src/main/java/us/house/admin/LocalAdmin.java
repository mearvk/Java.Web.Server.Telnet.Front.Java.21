package us.house.admin;

import javafx.application.Application;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Scene;
import javafx.scene.control.*;
import javafx.scene.layout.*;
import javafx.scene.paint.Color;
import javafx.scene.text.Font;
import javafx.scene.text.FontWeight;
import javafx.stage.Stage;

/** JWSTF white local administration console. */
public final class LocalAdmin extends Application {
    private final Label status = new Label("Healthy");
    private final TextArea activity = new TextArea();

    @Override
    public void start(Stage stage) {
        BorderPane root = new BorderPane();
        root.setPadding(new Insets(24));
        root.setStyle("-fx-background-color:#f7f8fa;");

        VBox header = new VBox(4);
        Label eyebrow = label("JWSTF  /  LOCAL ADMINISTRATION", 12, true);
        eyebrow.setTextFill(Color.web("#5d6670"));
        Label title = label("Administration", 30, true);
        Label subtitle = label("A calm, local view of your Java 21 system.", 15, false);
        subtitle.setTextFill(Color.web("#59636d"));
        header.getChildren().addAll(eyebrow, title, subtitle);
        root.setTop(header);

        VBox nav = new VBox(8);
        nav.setPadding(new Insets(28, 24, 0, 0));
        for (String item : new String[]{"Overview","Services","Software","Modules","Configuration","Evidence","Maintenance"}) {
            Button b = new Button(item);
            b.setMaxWidth(Double.MAX_VALUE);
            b.setAlignment(Pos.CENTER_LEFT);
            b.setPrefHeight(40);
            b.setStyle("-fx-background-color:white;-fx-background-radius:8;-fx-border-color:#e1e5e9;-fx-border-radius:8;-fx-padding:0 14;");
            nav.getChildren().add(b);
        }
        root.setLeft(nav);

        VBox content = new VBox(18);
        content.setPadding(new Insets(28, 0, 0, 0));

        HBox health = card();
        VBox healthText = new VBox(3);
        Label healthTitle = label("System health", 17, true);
        status.setTextFill(Color.web("#277447"));
        status.setFont(Font.font("System", FontWeight.BOLD, 14));
        healthText.getChildren().addAll(healthTitle, status);
        Region spacer = new Region();
        HBox.setHgrow(spacer, Priority.ALWAYS);
        Label java = label("Java 21", 14, false);
        java.setTextFill(Color.web("#5d6670"));
        health.getChildren().addAll(healthText, spacer, java);

        HBox services = card();
        services.getChildren().addAll(metric("Web Server","Ready"), metric("Telnet Frontend","Ready"), metric("Modules","Managed"));

        HBox actions = new HBox(10);
        actions.getChildren().addAll(action("Install / Repair","install"), action("Update","update"), action("Verify","verify"), action("Remove","remove"));

        VBox logCard = new VBox(8);
        logCard.setPadding(new Insets(18));
        logCard.setStyle("-fx-background-color:white;-fx-background-radius:10;-fx-border-color:#e1e5e9;-fx-border-radius:10;");
        Label logTitle = label("Activity", 16, true);
        activity.setEditable(false);
        activity.setPrefRowCount(7);
        activity.setText("Ready. No privileged operation has been requested.\n");
        activity.setStyle("-fx-control-inner-background:white;-fx-border-color:#edf0f2;");
        logCard.getChildren().addAll(logTitle, activity);

        content.getChildren().addAll(health, services, actions, logCard);
        root.setCenter(content);

        stage.setTitle("JWSTF Local Administration");
        stage.setScene(new Scene(root, 1040, 700));
        stage.setMinWidth(900);
        stage.setMinHeight(620);
        stage.show();
    }

    private static Label label(String text, double size, boolean bold) {
        Label l = new Label(text);
        l.setFont(Font.font("System", bold ? FontWeight.BOLD : FontWeight.NORMAL, size));
        return l;
    }

    private static HBox card() {
        HBox box = new HBox(18);
        box.setAlignment(Pos.CENTER_LEFT);
        box.setPadding(new Insets(18));
        box.setStyle("-fx-background-color:white;-fx-background-radius:10;-fx-border-color:#e1e5e9;-fx-border-radius:10;");
        return box;
    }

    private static VBox metric(String name, String value) {
        VBox box = new VBox(3);
        Label n = label(name, 13, false);
        n.setTextFill(Color.web("#66717b"));
        Label v = label(value, 16, true);
        box.getChildren().addAll(n, v);
        HBox.setHgrow(box, Priority.ALWAYS);
        return box;
    }

    private Button action(String name, String operation) {
        Button b = new Button(name);
        b.setPrefHeight(42);
        b.setStyle("-fx-background-color:white;-fx-border-color:#d7dce1;-fx-border-radius:8;-fx-background-radius:8;-fx-padding:0 16;");
        b.setOnAction(e -> activity.appendText("Requested: " + operation + " — review required before execution.\n"));
        return b;
    }

    public static void main(String[] args) { launch(args); }
}
