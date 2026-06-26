package video.viewer;

import javafx.application.Application;
import javafx.scene.Group;
import javafx.scene.Scene;
import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.media.Media;
import javafx.scene.media.MediaPlayer;
import javafx.scene.paint.Color;
import javafx.stage.Stage;
import java.io.File;

public class AudioVisualizer extends Application {

    private static final int BANDS = 60; // Number of frequency bars
    private float[] currentMagnitudes = new float[BANDS];

    @Override
    public void start(Stage primaryStage) {
        // 1. Load your audio file
        String audioPath = "path/to/your/audio.mp3";
        Media media = new Media(new File(audioPath).toURI().toString());
        MediaPlayer mediaPlayer = new MediaPlayer(media);

        // 2. Configure Spectrum Settings
        mediaPlayer.setAudioSpectrumNumBands(BANDS);
        mediaPlayer.setAudioSpectrumInterval(0.05); // Updates 20 times per second

        // 3. Set up the Spectrum Listener to grab volume & frequency
        mediaPlayer.setAudioSpectrumListener((timestamp, duration, magnitudes, phases) -> {
            // Save the magnitudes to read during rendering
            this.currentMagnitudes = magnitudes.clone();
        });

        // 4. Create visual widgets (Canvas)
        Canvas canvas = new Canvas(800, 400);
        GraphicsContext gc = canvas.getGraphicsContext2D();

        // 5. Setup the Rendering Loop
        javafx.animation.AnimationTimer timer = new javafx.animation.AnimationTimer() {
            @Override
            public void handle(long now) {
                // Clear the canvas
                gc.setFill(Color.BLACK);
                gc.fillRect(0, 0, canvas.getWidth(), canvas.getHeight());

                // Draw frequency bars
                gc.setFill(Color.AQUA);
                double barWidth = canvas.getWidth() / BANDS;

                for (int i = 0; i < BANDS; i++) {
                    // Magnitudes are in decibels (e.g., -60dB to 0dB), so we offset them
                    double minDB = -60.0;
                    double magnitude = currentMagnitudes[i];
                    double percent = (magnitude - minDB) / (-minDB);
                    percent = Math.max(0, Math.min(1, percent)); // Clamp between 0 and 1

                    double barHeight = percent * canvas.getHeight();
                    double x = i * barWidth;
                    double y = canvas.getHeight() - barHeight;

                    gc.fillRect(x, y, barWidth - 2, barHeight);
                }
            }
        };

        // Layout & Launch
        Group root = new Group(canvas);
        Scene scene = new Scene(root, 800, 400);
        primaryStage.setScene(scene);
        primaryStage.setTitle("JavaFX Audio Spectrum");
        primaryStage.show();

        // Start playback and rendering
        timer.start();
        mediaPlayer.play();
    }
}
