/**
 * VocabularyComposer — Lightweight facade for StrernaryServer and other modules.
 *
 * Any module can call:
 *   VocabularyComposer.humanGradeResponse(input, rawFact) → polished response
 *
 * This wraps VocabularyInferrer + VocabularyLink into a single method call
 * so existing modules don't need to change their structure — they just route
 * their output through the composer before sending to the user.
 *
 * Integration example (in StrernaryServer.bestGuess or DemocraticAIServer.processRequest):
 *
 *   String rawAnswer = fetcher.lookup(input);         // existing fact lookup
 *   return VocabularyComposer.humanGradeResponse(input, rawAnswer);  // NEW: polished
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date August 3 2026 EST
 */

package ai.vocabulary;

public final class VocabularyComposer
{
    private static volatile boolean initialized = false;

    private VocabularyComposer() {}

    /**
     * Initialize the vocabulary system (call once at startup).
     * Safe to call multiple times.
     */
    public static void initialize()
    {
        if (initialized) return;
        synchronized (VocabularyComposer.class)
        {
            if (initialized) return;
            VocabularyTrainingLoader.loadAll();
            initialized = true;
            System.out.println("[VocabularyComposer] Initialized — " + VocabularyTrainingLoader.status());
        }
    }

    /**
     * Takes raw input and raw factual content, returns a human-grade response.
     *
     * @param input       The user's original input text
     * @param rawFact     The factual answer (from DB, Wikipedia, DJL, etc.) — may be null
     * @return            A thoughtful, educated, human-grade response
     */
    public static String humanGradeResponse(String input, String rawFact)
    {
        if (!initialized) initialize();

        if (rawFact == null || rawFact.isBlank())
            return VocabularyLink.respond(input);

        return VocabularyLink.frame(input, rawFact);
    }

    /**
     * Session-aware version — maintains conversational coherence.
     *
     * @param input       The user's input
     * @param rawFact     The factual answer (may be null)
     * @param sessionId   Session identifier (IP, NationalID, connection hash)
     * @return            Context-aware human-grade response
     */
    public static String humanGradeResponse(String input, String rawFact, String sessionId)
    {
        if (!initialized) initialize();

        if (rawFact == null || rawFact.isBlank())
            return VocabularyLink.respondInContext(input, sessionId);

        // Infer, compose with session context
        VocabularyInferrer inferrer = VocabularyInferrer.getInstance();
        VocabularyInferrer.InferenceResult inf = inferrer.infer(input);
        VocabularyLink.SessionContext ctx = VocabularyLink.getSession(sessionId);
        String response = inferrer.compose(inf, rawFact, ctx.summarizeContext());
        ctx.recordExchange(input, response, inf);
        return response;
    }

    /**
     * Pure vocabulary inference — returns analysis of input without generating a response.
     * Useful for modules that want to understand the input before deciding how to respond.
     */
    public static VocabularyInferrer.InferenceResult analyze(String input)
    {
        if (!initialized) initialize();
        return VocabularyInferrer.getInstance().infer(input);
    }

    /**
     * Returns system status string.
     */
    public static String status()
    {
        return "VocabularyComposer|initialized=" + initialized
            + "|training=" + VocabularyTrainingLoader.status()
            + "|modules=" + VocabularyLink.moduleCount();
    }

    /**
     * Register a module with the vocabulary link system.
     * Convenience method — delegates to VocabularyLink.register().
     */
    public static void registerModule(String name,
                                      VocabularyInferrer.TopicDomain[] domains,
                                      java.util.function.Function<String, String> factLookup,
                                      int priority)
    {
        VocabularyLink.register(name, domains, factLookup, priority);
    }
}
