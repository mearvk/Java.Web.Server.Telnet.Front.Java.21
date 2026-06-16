package middle.director;

import java.io.*;
import java.nio.file.*;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.List;

/** Auditor content verification and goal compliance using .CSVmd ethical trust codes. */
public class AuditorContentModule implements DirectorModule
{
    private static final String CODES_FILE = "source/middle/director/auditor-codes.csvmd";

    private final List<AuditorCode> codes = new CopyOnWriteArrayList<>();

    public AuditorContentModule()
    {
        loadCodes();
    }

    @Override public String name() { return "AuditorContent"; }

    @Override
    public String process(String input)
    {
        // Evaluate input against all 16 auditor codes
        StringBuilder tags = new StringBuilder();
        for (AuditorCode c : codes)
        {
            if (input.toLowerCase().contains(c.domain.toLowerCase()))
                tags.append(c.code).append(":");
        }
        String prefix = tags.isEmpty() ? "[Auditor]" : "[Auditor:" + tags.substring(0, tags.length() - 1) + "]";
        return prefix + " " + input;
    }

    public String processAndRecord(String input, long nationalId, String ip,
                                   String publicKey, long signatoryId, String signatoryKey,
                                   boolean employed, boolean democrat)
    {
        recordTrade("audit", nationalId, ip, publicKey, signatoryId, signatoryKey, employed, democrat);
        return process(input);
    }

    public List<AuditorCode> getCodes() { return codes; }

    private void loadCodes()
    {
        try
        {
            Path path = Path.of(CODES_FILE);
            if (!Files.exists(path)) return;

            for (String line : Files.readAllLines(path))
            {
                if (line.startsWith("#") || line.isBlank() || line.startsWith("code,")) continue;
                String[] parts = line.split(",", 4);
                if (parts.length < 4) continue;
                codes.add(new AuditorCode(parts[0].trim(), parts[1].trim(), parts[2].trim(), Double.parseDouble(parts[3].trim())));
            }

            commons.CommonRails.printSystemComponent(this, this.hashCode(),
                ". AuditorContentModule loaded " + codes.size() + " ethical trust codes from .CSVmd .");
        }
        catch (Exception e) { exceptions.ExceptionHandler.dispatch(e); }
    }

    /** An ethical trust auditor code. */
    public static class AuditorCode
    {
        public final String code;
        public final String domain;
        public final String principle;
        public final double weight;

        public AuditorCode(String code, String domain, String principle, double weight)
        {
            this.code = code;
            this.domain = domain;
            this.principle = principle;
            this.weight = weight;
        }
    }
}
