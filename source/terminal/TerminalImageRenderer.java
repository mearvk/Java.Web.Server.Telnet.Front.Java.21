package terminal;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.File;

/**
 * TerminalImageRenderer
 *
 * Renders a JPEG/PNG/BMP image to a GNOME terminal using
 * Unicode half-block characters and 24-bit ANSI TrueColor.
 *
 * Usage:
 *   javac TerminalImageRenderer.java
 *   java TerminalImageRenderer path/to/image.png [width]
 *
 * If width is omitted, defaults to 80 characters.
 */
public class TerminalImageRenderer
{

    // ANSI escape sequences
    private static final String ESC = "\u001b[";
    private static final String RESET = ESC + "0m";

    public static void main(String[] args) throws Exception
    {
        if (args.length < 1) {
            System.err.println("Usage: java TerminalImageRenderer <image> [width]");
            System.exit(1);
        }

        String path = args[0];
        int targetWidth = (args.length >= 2) ? Integer.parseInt(args[1]) : 80;

        BufferedImage img = ImageIO.read(new File(path));

        if (img == null) {
            System.err.println("Could not read image: " + path);
            System.exit(1);
        }

        BufferedImage scaled = scaleToWidth(img, targetWidth);
        renderHalfBlocksTrueColor(scaled);
        System.out.print(RESET);
    }

    /**
     * Scale image to target terminal width, preserving aspect ratio.
     * Height is scaled accordingly; we later compress two vertical pixels
     * into one terminal row using half-block characters.
     */
    private static BufferedImage scaleToWidth(BufferedImage src, int targetWidth)
    {
        int srcWidth = src.getWidth();
        int srcHeight = src.getHeight();

        if (srcWidth <= targetWidth)
        {
            return src; // no scaling needed
        }

        double scale = (double) targetWidth / srcWidth;
        int newWidth = targetWidth;
        int newHeight = (int) Math.round(srcHeight * scale);

        BufferedImage dst = new BufferedImage(newWidth, newHeight, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = dst.createGraphics();
        g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
        g.drawImage(src, 0, 0, newWidth, newHeight, null);
        g.dispose();
        return dst;
    }

    /**
     * Render using Unicode upper half-block (▀) with foreground color
     * for the top pixel and background color for the bottom pixel.
     *
     * Each terminal cell represents two vertical pixels:
     *   - top pixel -> ANSI 38;2;r;g;b (foreground)
     *   - bottom pixel -> ANSI 48;2;r;g;b (background)
     */
    private static void renderHalfBlocksTrueColor(BufferedImage img)
    {
        int width = img.getWidth();
        int height = img.getHeight();

        // Ensure even height for pairing top/bottom pixels
        if (height % 2 != 0) {
            height -= 1;
        }

        StringBuilder sb = new StringBuilder();

        for (int y = 0; y < height; y += 2) {
            for (int x = 0; x < width; x++) {
                int topRGB = img.getRGB(x, y);
                int bottomRGB = img.getRGB(x, y + 1);

                Color top = new Color(topRGB);
                Color bottom = new Color(bottomRGB);

                // ANSI TrueColor: foreground (top), background (bottom)
                sb.append(ESC)
                        .append("38;2;")
                        .append(top.getRed()).append(";")
                        .append(top.getGreen()).append(";")
                        .append(top.getBlue()).append("m");

                sb.append(ESC)
                        .append("48;2;")
                        .append(bottom.getRed()).append(";")
                        .append(bottom.getGreen()).append(";")
                        .append(bottom.getBlue()).append("m");

                // Upper half block character
                sb.append('▀');
            }
            sb.append(RESET).append('\n');
        }

        System.out.print(sb.toString());
    }
}
