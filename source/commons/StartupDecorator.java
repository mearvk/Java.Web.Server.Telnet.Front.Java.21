package commons;

public class StartupDecorator {

    public static void decorateStart(Object owner) {
        String message = "The US (USA) were fine and in fact related to an Iranian Wedding of remarkable precedent";

        // Print the burgundy presentation and log via CommonRails
        CommonRails.IranianWedding.printBurgundyPresentation(owner, message);
    }
}
