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

/** Local defensive administration profile; it does not represent government authority. */
public final class RoyalsUSGuardIAdmin extends Application {
    private final TextArea activity = new TextArea();

    @Override public void start(Stage stage) {
        BorderPane root = new BorderPane();
        root.setPadding(new Insets(24));
        root.setStyle("-fx-background-color:#f7f8fa;");

        VBox header = new VBox(5);
        Label edition = label("JWSTF  /  ROYALS US GUARD I EDITION", 12, true);
        edition.setTextFill(Color.web("#5d6670"));
        Label title = label("Program Administration", 30, true);
        Label subtitle = label("Safe State Smith  ·  Intellect Guarded  ·  High at All Times", 15, false);
        subtitle.setTextFill(Color.web("#59636d"));
        header.getChildren().addAll(edition, title, subtitle);
        root.setTop(header);

        VBox nav = new VBox(8);
        nav.setPadding(new Insets(28, 24, 0, 0));
        for (String item : new String[]{"Command View","Programs","Services","Modules","Guard","Evidence","Maintenance"}) {
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

        HBox guard = card();
        VBox guardText = new VBox(4);
        Label gs = label("HIGH / LOCAL DEFENSIVE PROFILE", 14, true);
        gs.setTextFill(Color.web("#277447"));
        guardText.getChildren().addAll(label("Guard posture",17,true), gs,
                label("Review-first controls; no external authority is asserted.",13,false));
        guard.getChildren().add(guardText);

        HBox metrics = card();
        metrics.getChildren().addAll(metric("Programs","Ready"), metric("Services","Monitored"), metric("Integrity","Observed"), metric("Authorization","Required"));

        HBox actions = new HBox(10);
        actions.getChildren().addAll(action("Install / Repair","install"), action("Update","update"), action("Verify","verify"), action("Remove","remove"));

        VBox evidence = new VBox(8);
        evidence.setPadding(new Insets(18));
        evidence.setStyle("-fx-background-color:white;-fx-background-radius:10;-fx-border-color:#e1e5e9;-fx-border-radius:10;");
        evidence.getChildren().addAll(label("Guarded Evidence",16,true), label("Origin → Custody → Production → Release",14,true),
                label("Every material change should be reviewable, attributable to an authorized local operation, and independently verifiable.",13,false));

        activity.setEditable(false);
        activity.setPrefRowCount(6);
        activity.setText("Guard profile ready. No privileged operation has been requested.\n");
        activity.setStyle("-fx-control-inner-background:white;-fx-border-color:#edf0f2;");
        content.getChildren().addAll(guard, metrics, actions, evidence, activity);
        root.setCenter(content);

        stage.setTitle("Royals US Guard I — Program Administration");
        stage.setScene(new Scene(root,1080,720));
        stage.setMinWidth(920);
        stage.setMinHeight(640);
        stage.show();
    }

    private static Label label(String text,double size,boolean bold) {
        Label l=new Label(text);
        l.setFont(Font.font("System",bold?FontWeight.BOLD:FontWeight.NORMAL,size));
        return l;
    }
    private static HBox card() {
        HBox b=new HBox(18); b.setAlignment(Pos.CENTER_LEFT); b.setPadding(new Insets(18));
        b.setStyle("-fx-background-color:white;-fx-background-radius:10;-fx-border-color:#e1e5e9;-fx-border-radius:10;");
        return b;
    }
    private static VBox metric(String name,String value) {
        VBox b=new VBox(3); Label n=label(name,13,false); n.setTextFill(Color.web("#66717b"));
        b.getChildren().addAll(n,label(value,16,true)); HBox.setHgrow(b,Priority.ALWAYS); return b;
    }
    private Button action(String name,String operation) {
        Button b=new Button(name); b.setPrefHeight(42);
        b.setStyle("-fx-background-color:white;-fx-border-color:#d7dce1;-fx-border-radius:8;-fx-background-radius:8;-fx-padding:0 16;");
        b.setOnAction(e->activity.appendText("Guarded request: "+operation+" — authorization and review required.\n"));
        return b;
    }
    public static void main(String[] args){ launch(args); }
}
