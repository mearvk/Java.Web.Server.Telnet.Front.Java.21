/**
 * VocabularyLink — Cross-module vocabulary linking system.
 *
 * Connects all NWE AI modules (Strernary, DemocraticAI, DefinedAI, SpectrumTandem)
 * to the central VocabularyInferrer. Each module registers its domain expertise,
 * and the link system routes vocabulary requests to the most appropriate module.
 *
 * The linking system also maintains a shared conversational memory so that
 * responses across modules feel coherent and informed by prior exchanges.
 *
 * Modules register with:
 *   VocabularyLink.register("ModuleName", TopicDomain[], callback)
 *
 * Any module can then call:
 *   VocabularyLink.respond(input) → human-grade response
 *   VocabularyLink.respondInContext(input, sessionHistory) → contextual response
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date August 3 2026 EST
 */

package ai.vocabulary;

import java.util.*;
import java.util.concurrent.*;
import java.util.function.Function;

public class VocabularyLink
{
    // ── Registered Module ──────────────────────────────────────────────────────

    public static class RegisteredModule
    {
        public final String name;
        public final VocabularyInferrer.TopicDomain[] domains;
        public final Function<String, String> factLookup;  // module's own knowledge lookup
        public final int priority;                          // higher = preferred for domain

        public RegisteredModule(String name, VocabularyInferrer.TopicDomain[] domains,
                                Function<String, String> factLookup, int priority)
        {
            this.name = name;
            this.domains = domains;
            this.factLookup = factLookup;
            this.priority = priority;
        }
    }

    // ── Session Context ────────────────────────────────────────────────────────

    public static class SessionContext
    {
        private final Deque<String[]> history = new ArrayDeque<>();  // [input, response] pairs
        private final int maxHistory;
        private VocabularyInferrer.TopicDomain lastDomain;
        private VocabularyInferrer.VocabularyGrade lastGrade;

        public SessionContext(int maxHistory)
        {
            this.maxHistory = maxHistory;
        }

        public void recordExchange(String input, String response, VocabularyInferrer.InferenceResult inf)
        {
            if (history.size() >= maxHistory) history.pollFirst();
            history.addLast(new String[]{input, response});
            lastDomain = inf.domain;
            lastGrade = inf.grade;
        }

        public String summarizeContext()
        {
            if (history.isEmpty()) return "";
            StringBuilder sb = new StringBuilder();
            for (String[] pair : history)
                sb.append("Q: ").append(truncate(pair[0], 80))
                  .append(" A: ").append(truncate(pair[1], 120)).append("\n");
            return sb.toString();
        }

        public VocabularyInferrer.TopicDomain getLastDomain() { return lastDomain; }
        public VocabularyInferrer.VocabularyGrade getLastGrade() { return lastGrade; }

        private String truncate(String s, int max)
        {
            return s.length() > max ? s.substring(0, max) + "..." : s;
        }
    }

    // ── State ──────────────────────────────────────────────────────────────────

    private static final List<RegisteredModule> modules = new CopyOnWriteArrayList<>();
    private static final ConcurrentHashMap<String, SessionContext> sessions = new ConcurrentHashMap<>();
    private static final VocabularyInferrer inferrer = VocabularyInferrer.getInstance();

    // ── Registration ───────────────────────────────────────────────────────────

    /**
     * Register a module's domain expertise and fact lookup function.
     */
    public static void register(String name, VocabularyInferrer.TopicDomain[] domains,
                                Function<String, String> factLookup, int priority)
    {
        modules.add(new RegisteredModule(name, domains, factLookup, priority));
        System.out.println("[VocabularyLink] Registered module: " + name
            + " domains=" + Arrays.toString(domains) + " priority=" + priority);
    }

    /**
     * Shorthand: register with default priority.
     */
    public static void register(String name, VocabularyInferrer.TopicDomain[] domains,
                                Function<String, String> factLookup)
    {
        register(name, domains, factLookup, 5);
    }

    // ── Response Generation ────────────────────────────────────────────────────

    /**
     * Generate a human-grade response to any input text.
     * Routes through VocabularyInferrer and the best-matching registered module.
     */
    public static String respond(String input)
    {
        return respondInContext(input, "default");
    }

    /**
     * Generate a human-grade response with session context for coherence.
     *
     * @param input     The incoming text
     * @param sessionId A session identifier (IP, NationalID, connection hash)
     * @return          A thoughtful, human-grade response
     */
    public static String respondInContext(String input, String sessionId)
    {
        if (input == null || input.isBlank())
            return "I'm listening. Please go ahead.";

        // 1. Infer properties of the input
        VocabularyInferrer.InferenceResult inference = inferrer.infer(input);

        // 2. Get or create session context
        SessionContext ctx = sessions.computeIfAbsent(sessionId, k -> new SessionContext(20));

        // 3. Find the best module for this domain
        String factualContent = lookupFact(input, inference.domain, inference.keyTerms);

        // 4. Compose human-grade response
        String response = inferrer.compose(inference, factualContent, ctx.summarizeContext());

        // 5. Record exchange in session context
        ctx.recordExchange(input, response, inference);

        return response;
    }

    /**
     * Direct composition: caller provides the factual content, system wraps it
     * in human-grade vocabulary and framing appropriate to the input.
     */
    public static String frame(String input, String rawFact)
    {
        return inferrer.compose(input, rawFact);
    }

    // ── Fact Lookup Across Modules ─────────────────────────────────────────────

    private static String lookupFact(String input, VocabularyInferrer.TopicDomain domain, String[] keyTerms)
    {
        // Sort modules by relevance to this domain
        List<RegisteredModule> relevant = modules.stream()
            .filter(m -> Arrays.asList(m.domains).contains(domain))
            .sorted((a, b) -> Integer.compare(b.priority, a.priority))
            .toList();

        // Try each relevant module's fact lookup
        for (RegisteredModule mod : relevant)
        {
            try
            {
                String fact = mod.factLookup.apply(input);
                if (fact != null && !fact.isBlank())
                    return fact;
            }
            catch (Exception ignored) {}
        }

        // Fallback: try all modules regardless of domain
        for (RegisteredModule mod : modules)
        {
            if (relevant.contains(mod)) continue;
            try
            {
                String fact = mod.factLookup.apply(input);
                if (fact != null && !fact.isBlank())
                    return fact;
            }
            catch (Exception ignored) {}
        }

        return null; // No factual content found — compose will handle gracefully
    }

    // ── Session Management ─────────────────────────────────────────────────────

    /**
     * Create or get a session context for multi-turn conversations.
     */
    public static SessionContext getSession(String sessionId)
    {
        return sessions.computeIfAbsent(sessionId, k -> new SessionContext(20));
    }

    /**
     * Clear a session (e.g., on disconnect).
     */
    public static void clearSession(String sessionId)
    {
        sessions.remove(sessionId);
    }

    /**
     * Get total registered modules count (for status).
     */
    public static int moduleCount() { return modules.size(); }

    /**
     * Get registered module names (for status display).
     */
    public static List<String> moduleNames()
    {
        return modules.stream().map(m -> m.name).toList();
    }
}
