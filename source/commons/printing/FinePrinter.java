package commons.printing;

import commons.color.ColorPalette;

public final class FinePrinter {

    private FinePrinter() {}

    public static void fadePrint(String text) {
        int[] grayscale = new int[20];
        for (int i = 0; i < 20; i++) grayscale[i] = 236 + i;

        try {
            for (int code : grayscale) {
                System.out.print("\033[38;5;" + code + "m" + text + "\r");
                Thread.sleep(20);
            }
            System.out.print(ColorPalette.OID_DEFAULT);
            Thread.sleep(200);
            System.out.println(text);
            System.out.print(ColorPalette.OID_DEFAULT);
        } catch (Exception ignored) {}
    }
}
