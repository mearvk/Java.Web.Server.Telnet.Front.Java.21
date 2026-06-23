package commons.printing;

import commons.color.ColorPalette;

public final class FinePrinter {

    private FinePrinter() {}

    public static void fadePrint(String text) {
        fadePrint(text, 20, 20, 200, true);
    }

    public static void fadePrint(String text, int steps, int delayMs, int postDelayMs, boolean colored) {
        if (!colored) {
            System.out.println(text);
            System.out.print(ColorPalette.ANSI_RESET);
            return;
        }

        int[] grayscale = new int[steps];
        for (int i = 0; i < steps; i++) grayscale[i] = 236 + i;

        try {
            for (int code : grayscale) {
                System.out.print("\033[38;5;" + code + "m" + text + "\r");
                Thread.sleep(delayMs);
            }
            System.out.print(ColorPalette.OID_DEFAULT);
            Thread.sleep(postDelayMs);
            System.out.println(text);
            System.out.print(ColorPalette.OID_DEFAULT);
        } catch (Exception ignored) {}
    }
}
