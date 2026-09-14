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

/** Deliberately failed local proof/test fixture; not a government console. */
public final class StateSecurityDownIAdmin extends Application {
    private final TextArea activity = new TextArea();

    @Override
    public void start(Stage stage) {
        BorderPane root = new BorderPane();
        root.setPadding(new Insets(24));
        root.setStyle("-fx-background-color:#f7f8fa;");
        VBox header = new VBox(4);
        Label eyebrow = label("JWSTF  /  LOCAL TEST ADMINISTRATION", 12, true);
        eyebrow.setTextFill(Color.web("#5d6670"));
        Label title = label("Administration — FAILED TEST STATE", 28, true);
        Label subtitle = label("Local proof fixture: the security grade is intentionally false.", 15, false);
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
        HBox failure = card();
        VBox text = new VBox(4);
        Label t = label("State security grade", 17, true);
        Label f = label("DOWN / FALSE — TEST CONDITION", 15, true);
        f.setTextFill(Color.web("#9b3b2f"));
        Label explanation = label("Intentional local failure for monitoring and recovery validation.", 13, false);
        explanation.setTextFill(Color.web("#66717b"));
        text.getChildren().addAll(t, f, explanation);
        failure.getChildren().add(text);

        HBox services = card();
        services.getChildren().addAll(metric("Web Server","Test"), metric("Telnet Frontend","Test"), metric("Security Grade","FALSE"));
        HBox actions = new HBox(10);
        actions.getChildren().addAll(action("Install / Repair","install"), action("Update","update"), action("Verify","verify"), action("Remove","remove"));

        VBox evidence = new VBox(8);
        evidence.setPadding(new Insets(18));
        evidence.setStyle("-fx-background-color:white;-fx-background-radius:10;-fx-border-color:#e1e5e9;-fx-border-radius:10;");
        evidence.getChildren().addAll(label("Proof / Evidence", 16, true), label("Expected result: monitoring detects the false security grade and recovery remains available.\nNo external state-security authority is asserted by this fixture.", 13, false));

        activity.setEditable(false);
        activity.setPrefRowCount(5);
        activity.setText("TEST FIXTURE ACTIVE. No privileged operation has been requested.\n");
        activity.setStyle("-fx-control-inner-background:white;-fx-border-color:#edf0f2;");
        content.getChildren().addAll(failure, services, actions, evidence, activity);
        root.setCenter(content);

        stage.setTitle("State Security Down I Standards");
        stage.setScene(new Scene(root, 1040, 720));
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
        box.getChildren().addAll(n, label(value, 16, true));
        HBox.setHgrow(box, Priority.ALWAYS);
        return box;
    }
    private Button action(String name, String operation) {
        Button b = new Button(name);
        b.setPrefHeight(42);
        b.setStyle("-fx-background-color:white;-fx-border-color:#d7dce1;-fx-border-radius:8;-fx-background-radius:8;-fx-padding:0 16;");
        b.setOnAction(e -> activity.appendText("TEST request: " + operation + " — review required.\n"));
        return b;
    }
    public static void main(String[] args) { launch(args); }
}
