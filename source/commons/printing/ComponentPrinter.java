package commons.printing;

import commons.color.ColorResolver;
import commons.color.ColorPalette;
import commons.formatting.LineFormatter;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.TimeZone;

public final class ComponentPrinter {

    private static final int CLASSNAME_WIDTH = 39;

    private ComponentPrinter() {}

    public static void print(Object owner, int hash, String line) {
        String simple = owner.getClass().getSimpleName();
        String padded = padClassname(simple);

        int resolvedHash = configuration.HashCodeRegistry.resolve(owner);
        String hashStr = String.format("%010d", resolvedHash);
        String coloredHash = ColorResolver.resolveCategoryColor(simple) + hashStr + ColorPalette.OID_DEFAULT;

        String date = timestamp();
        String formatted = LineFormatter.normalize(line);

        String ref = ColorPalette.OID_DEFAULT + "-- : [Object ID: " + coloredHash + "] " + date + " " + padded + " " + formatted + ColorPalette.OID_DEFAULT;

        FinePrinter.fadePrint(ref);
    }

    private static String timestamp() {
        SimpleDateFormat fmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss z");
        fmt.setTimeZone(TimeZone.getTimeZone("America/New_York"));
        return "[Date: " + fmt.format(new Date()) + "]";
    }

    private static String padClassname(String name) {
        int pad = Math.max(0, CLASSNAME_WIDTH - ("Current: @" + name).length());
        return "[Current: @" + name + " ".repeat(pad) + "]";
    }
}
