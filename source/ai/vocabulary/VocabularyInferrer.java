/**
 * VocabularyInferrer — Central vocabulary reasoning engine for NWE AI modules.
 *
 * Takes raw input text (any standard communication: question, statement, request,
 * opinion, complaint, greeting) and infers:
 *   1. Intent class (what the person wants)
 *   2. Vocabulary grade (sophistication level of the input)
 *   3. Topic domain (what subject area the input concerns)
 *   4. Emotional register (tone: formal, casual, urgent, hostile, curious)
 *   5. Response vocabulary set (which words/phrases to draw from for reply)
 *
 * Produces human-grade, thoughtful, informed, educated responses by:
 *   - Matching input sophistication level (don't talk down, don't talk over)
 *   - Drawing from domain-specific vocabulary sets
 *   - Using rhetorical structures appropriate to the intent
 *   - Maintaining conversational coherence across exchanges
 *
 * All NWE AI modules (Strernary, DemocraticAI, DefinedAI, SpectrumTandem)
 * can call VocabularyInferrer.compose() to generate human-grade responses.
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date August 3 2026 EST
 */

package ai.vocabulary;

import java.io.*;
import java.nio.file.*;
import java.sql.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.stream.*;

public class VocabularyInferrer
{
    // ── Intent Classes ─────────────────────────────────────────────────────────

    public enum Intent
    {
        QUESTION_FACTUAL,       // "What is X?" "When did Y happen?"
        QUESTION_OPINION,       // "What do you think about X?"
        QUESTION_HOW,           // "How do I do X?"
        QUESTION_WHY,           // "Why does X happen?"
        REQUEST_ACTION,         // "Please do X" "Can you X?"
        REQUEST_INFORMATION,    // "Tell me about X" "I need info on X"
        STATEMENT_FACT,         // "X is true" "The system does Y"
        STATEMENT_OPINION,      // "I think X" "X seems wrong"
        GREETING,               // "Hello" "Good morning"
        FAREWELL,               // "Goodbye" "Thanks, bye"
        COMPLAINT,              // "X is broken" "This doesn't work"
        GRATITUDE,              // "Thank you" "Appreciate it"
        CLARIFICATION,          // "What do you mean?" "Can you elaborate?"
        AGREEMENT,              // "Yes" "That's correct" "I agree"
        DISAGREEMENT,           // "No" "That's wrong" "I disagree"
        CONTINUATION,           // "And then?" "What else?" "Go on"
        META_CONVERSATION,      // About the conversation itself
        UNKNOWN                 // Insufficient signal
    }

    // ── Vocabulary Grade ───────────────────────────────────────────────────────

    public enum VocabularyGrade
    {
        BASIC(1),               // Simple words, short sentences, everyday language
        CONVERSATIONAL(2),      // Normal adult conversation, some complexity
        EDUCATED(3),            // Professional language, technical or formal
        SCHOLARLY(4),           // Academic, precise, domain-expert vocabulary
        LITERARY(5);            // Poetic, philosophical, deeply nuanced

        public final int level;
        VocabularyGrade(int level) { this.level = level; }
    }

    // ── Topic Domain ───────────────────────────────────────────────────────────

    public enum TopicDomain
    {
        TECHNOLOGY, SCIENCE, MATHEMATICS, PHILOSOPHY, ETHICS, LAW,
        POLITICS, ECONOMICS, FINANCE, MEDICINE, PSYCHOLOGY, HISTORY,
        GEOGRAPHY, CULTURE, ARTS, MUSIC, LITERATURE, EDUCATION,
        ENVIRONMENT, ENGINEERING, MILITARY, SPORTS, FOOD, TRAVEL,
        SOCIAL, PERSONAL, PROFESSIONAL, GENERAL, SYSTEM_OPERATIONS
    }

    // ── Emotional Register ─────────────────────────────────────────────────────

    public enum EmotionalRegister
    {
        FORMAL, CASUAL, URGENT, CURIOUS, FRUSTRATED, GRATEFUL,
        NEUTRAL, WARM, COLD, ACADEMIC, PLAYFUL
    }

    // ── Inference Result ───────────────────────────────────────────────────────

    public static class InferenceResult
    {
        public final Intent intent;
        public final VocabularyGrade grade;
        public final TopicDomain domain;
        public final EmotionalRegister register;
        public final double confidence;
        public final String[] keyTerms;

        public InferenceResult(Intent intent, VocabularyGrade grade, TopicDomain domain,
                               EmotionalRegister register, double confidence, String[] keyTerms)
        {
            this.intent = intent;
            this.grade = grade;
            this.domain = domain;
            this.register = register;
            this.confidence = confidence;
            this.keyTerms = keyTerms;
        }
    }

    // ── Internal State ─────────────────────────────────────────────────────────

    private final Map<TopicDomain, List<String>> domainVocabulary = new ConcurrentHashMap<>();
    private final Map<VocabularyGrade, List<String>> transitionPhrases = new ConcurrentHashMap<>();
    private final Map<Intent, List<String>> responseFrameworks = new ConcurrentHashMap<>();
    private final Map<String, TopicDomain> domainKeywords = new ConcurrentHashMap<>();
    private final List<String[]> conversationalPairs = new CopyOnWriteArrayList<>();
    private final Map<String, String> idiomExpansions = new ConcurrentHashMap<>();

    private static volatile VocabularyInferrer INSTANCE;

    // ── Singleton ──────────────────────────────────────────────────────────────

    public static VocabularyInferrer getInstance()
    {
        if (INSTANCE == null)
        {
            synchronized (VocabularyInferrer.class)
            {
                if (INSTANCE == null)
                {
                    INSTANCE = new VocabularyInferrer();
                    INSTANCE.loadAllVocabulary();
                }
            }
        }
        return INSTANCE;
    }

    private VocabularyInferrer() {}

    // ── Core Inference Method ──────────────────────────────────────────────────

    /**
     * Infers intent, vocabulary grade, domain, and emotional register from input text.
     */
    public InferenceResult infer(String input)
    {
        if (input == null || input.isBlank()) return new InferenceResult(
            Intent.UNKNOWN, VocabularyGrade.BASIC, TopicDomain.GENERAL,
            EmotionalRegister.NEUTRAL, 0.0, new String[0]);

        String normalized = input.trim();
        String lower = normalized.toLowerCase();
        String[] words = normalized.split("\\s+");
        String[] keyTerms = extractKeyTerms(words);

        Intent intent = inferIntent(lower, words);
        VocabularyGrade grade = inferGrade(words, normalized);
        TopicDomain domain = inferDomain(lower, keyTerms);
        EmotionalRegister register = inferRegister(lower, words, normalized);
        double confidence = computeConfidence(intent, grade, domain, words);

        return new InferenceResult(intent, grade, domain, register, confidence, keyTerms);
    }

    // ── Response Composition ───────────────────────────────────────────────────

    /**
     * Composes a human-grade response given an inference result and the factual
     * content to communicate. This is the main entry point for all NWE AI modules.
     *
     * @param inference  The inferred properties of the incoming message
     * @param content    The factual answer or information to convey
     * @param context    Optional previous exchange context (for coherence)
     * @return           A thoughtful, educated, human-grade response string
     */
    public String compose(InferenceResult inference, String content, String context)
    {
        if (content == null || content.isBlank())
            return composeEmptyResponse(inference);

        StringBuilder response = new StringBuilder();

        // 1. Opening frame — matches intent and register
        String opening = selectOpening(inference);
        if (opening != null && !opening.isEmpty())
            response.append(opening).append(" ");

        // 2. Core content — reframed at the appropriate vocabulary grade
        String reframed = reframeContent(content, inference.grade, inference.domain);
        response.append(reframed);

        // 3. Transitional elaboration — adds depth if grade warrants
        if (inference.grade.level >= VocabularyGrade.EDUCATED.level)
        {
            String elaboration = addElaboration(inference, content);
            if (elaboration != null)
                response.append(" ").append(elaboration);
        }

        // 4. Closing frame — wraps with appropriate conclusion style
        String closing = selectClosing(inference);
        if (closing != null && !closing.isEmpty())
            response.append(" ").append(closing);

        return response.toString().trim();
    }

    /**
     * Quick compose: infers from input, then composes response around content.
     * One-call convenience for modules that just need input → response.
     */
    public String compose(String input, String factualContent)
    {
        InferenceResult inference = infer(input);
        return compose(inference, factualContent, null);
    }

    // ── Intent Inference ───────────────────────────────────────────────────────

    private Intent inferIntent(String lower, String[] words)
    {
        // Question detection
        if (lower.endsWith("?") || lower.startsWith("what ") || lower.startsWith("who ")
            || lower.startsWith("where ") || lower.startsWith("when "))
        {
            if (lower.contains("think") || lower.contains("opinion") || lower.contains("feel"))
                return Intent.QUESTION_OPINION;
            if (lower.startsWith("how ") || lower.contains("how do") || lower.contains("how can"))
                return Intent.QUESTION_HOW;
            if (lower.startsWith("why ") || lower.contains("why does") || lower.contains("why is"))
                return Intent.QUESTION_WHY;
            return Intent.QUESTION_FACTUAL;
        }
        if (lower.startsWith("how ")) return Intent.QUESTION_HOW;
        if (lower.startsWith("why ")) return Intent.QUESTION_WHY;

        // Request detection
        if (lower.startsWith("please ") || lower.startsWith("can you ") || lower.startsWith("could you ")
            || lower.startsWith("would you ") || lower.startsWith("i need ") || lower.startsWith("i want "))
        {
            if (lower.contains("tell") || lower.contains("info") || lower.contains("explain")
                || lower.contains("describe") || lower.contains("show"))
                return Intent.REQUEST_INFORMATION;
            return Intent.REQUEST_ACTION;
        }

        // Greeting
        if (matchesAny(lower, "hello", "hi", "hey", "good morning", "good afternoon",
            "good evening", "greetings", "howdy", "what's up", "hiya"))
            return Intent.GREETING;

        // Farewell
        if (matchesAny(lower, "goodbye", "bye", "see you", "farewell", "later",
            "take care", "good night", "signing off"))
            return Intent.FAREWELL;

        // Gratitude
        if (lower.contains("thank") || lower.contains("appreciate") || lower.contains("grateful"))
            return Intent.GRATITUDE;

        // Complaint
        if (lower.contains("broken") || lower.contains("doesn't work") || lower.contains("not working")
            || lower.contains("frustrated") || lower.contains("terrible") || lower.contains("awful")
            || lower.contains("fix this") || lower.contains("problem"))
            return Intent.COMPLAINT;

        // Agreement/Disagreement
        if (matchesAny(lower, "yes", "correct", "right", "agreed", "exactly", "indeed", "absolutely"))
            return Intent.AGREEMENT;
        if (matchesAny(lower, "no", "wrong", "incorrect", "disagree", "not true", "false"))
            return Intent.DISAGREEMENT;

        // Clarification
        if (lower.contains("what do you mean") || lower.contains("elaborate") || lower.contains("clarify")
            || lower.contains("explain more") || lower.contains("not sure i understand"))
            return Intent.CLARIFICATION;

        // Continuation
        if (matchesAny(lower, "and then", "what else", "go on", "continue", "more", "next"))
            return Intent.CONTINUATION;

        // Statement (default for declarative sentences)
        if (lower.contains("i think") || lower.contains("i believe") || lower.contains("in my opinion")
            || lower.contains("seems") || lower.contains("i feel"))
            return Intent.STATEMENT_OPINION;

        return Intent.STATEMENT_FACT;
    }

    // ── Vocabulary Grade Inference ─────────────────────────────────────────────

    private VocabularyGrade inferGrade(String[] words, String raw)
    {
        if (words.length == 0) return VocabularyGrade.BASIC;

        // Compute metrics
        double avgWordLength = Arrays.stream(words).mapToInt(String::length).average().orElse(4.0);
        long uniqueWords = Arrays.stream(words).map(String::toLowerCase).distinct().count();
        double lexicalDiversity = (double) uniqueWords / words.length;
        long complexWords = Arrays.stream(words).filter(w -> w.length() > 8).count();
        double complexRatio = (double) complexWords / words.length;

        // Count subordinate/academic markers
        String lower = raw.toLowerCase();
        int academicMarkers = 0;
        for (String marker : ACADEMIC_VOCABULARY)
            if (lower.contains(marker)) academicMarkers++;

        int literaryMarkers = 0;
        for (String marker : LITERARY_VOCABULARY)
            if (lower.contains(marker)) literaryMarkers++;

        // Score
        double score = 0;
        score += avgWordLength * 0.5;                    // longer words = higher grade
        score += lexicalDiversity * 3.0;                 // more unique words = higher
        score += complexRatio * 8.0;                     // complex word density
        score += academicMarkers * 1.5;                  // academic markers
        score += literaryMarkers * 2.0;                  // literary markers

        // Sentence structure complexity (nested clauses indicated by commas, semicolons)
        long punctuation = raw.chars().filter(c -> c == ',' || c == ';' || c == ':' || c == '—').count();
        score += Math.min(punctuation * 0.5, 3.0);

        if (score >= 12.0) return VocabularyGrade.LITERARY;
        if (score >= 8.0) return VocabularyGrade.SCHOLARLY;
        if (score >= 5.0) return VocabularyGrade.EDUCATED;
        if (score >= 3.0) return VocabularyGrade.CONVERSATIONAL;
        return VocabularyGrade.BASIC;
    }

    // ── Domain Inference ───────────────────────────────────────────────────────

    private TopicDomain inferDomain(String lower, String[] keyTerms)
    {
        // Score each domain by keyword hits
        Map<TopicDomain, Integer> scores = new EnumMap<>(TopicDomain.class);
        for (TopicDomain d : TopicDomain.values()) scores.put(d, 0);

        for (Map.Entry<String, TopicDomain> entry : domainKeywords.entrySet())
        {
            if (lower.contains(entry.getKey()))
                scores.merge(entry.getValue(), 1, Integer::sum);
        }

        // Also check key terms
        for (String term : keyTerms)
        {
            TopicDomain d = domainKeywords.get(term.toLowerCase());
            if (d != null) scores.merge(d, 2, Integer::sum);
        }

        return scores.entrySet().stream()
            .max(Map.Entry.comparingByValue())
            .filter(e -> e.getValue() > 0)
            .map(Map.Entry::getKey)
            .orElse(TopicDomain.GENERAL);
    }

    // ── Emotional Register Inference ───────────────────────────────────────────

    private EmotionalRegister inferRegister(String lower, String[] words, String raw)
    {
        // Check for urgency
        if (lower.contains("urgent") || lower.contains("immediately") || lower.contains("asap")
            || lower.contains("emergency") || raw.contains("!!!") || raw.contains("HELP"))
            return EmotionalRegister.URGENT;

        // Frustration
        if (lower.contains("frustrated") || lower.contains("annoyed") || lower.contains("angry")
            || lower.contains("ridiculous") || lower.contains("unacceptable"))
            return EmotionalRegister.FRUSTRATED;

        // Gratitude/warmth
        if (lower.contains("thank") || lower.contains("grateful") || lower.contains("appreciate")
            || lower.contains("wonderful") || lower.contains("great job"))
            return EmotionalRegister.GRATEFUL;

        // Curiosity
        if (lower.endsWith("?") && (lower.contains("curious") || lower.contains("wonder")
            || lower.contains("interesting") || lower.contains("fascinating")))
            return EmotionalRegister.CURIOUS;

        // Formal indicators
        if (lower.contains("dear") || lower.contains("respectfully") || lower.contains("hereby")
            || lower.contains("pursuant") || lower.contains("regarding"))
            return EmotionalRegister.FORMAL;

        // Casual indicators
        if (lower.contains("hey") || lower.contains("gonna") || lower.contains("wanna")
            || lower.contains("lol") || lower.contains("btw") || lower.contains("tbh"))
            return EmotionalRegister.CASUAL;

        // Academic
        if (lower.contains("hypothesis") || lower.contains("methodology") || lower.contains("empirical")
            || lower.contains("furthermore") || lower.contains("consequently"))
            return EmotionalRegister.ACADEMIC;

        return EmotionalRegister.NEUTRAL;
    }

    // ── Response Construction Helpers ──────────────────────────────────────────

    private String selectOpening(InferenceResult inf)
    {
        List<String> frameworks = responseFrameworks.get(inf.intent);
        if (frameworks == null || frameworks.isEmpty()) return "";

        // Select based on register
        return switch (inf.register)
        {
            case FORMAL -> frameworks.stream().filter(f -> !f.contains("!")).findFirst().orElse(frameworks.get(0));
            case CASUAL -> frameworks.stream().filter(f -> f.length() < 30).findFirst().orElse(frameworks.get(0));
            case URGENT -> "To address this directly:";
            case FRUSTRATED -> "I understand the concern.";
            case GRATEFUL -> "You're welcome.";
            case CURIOUS -> "That's a good question.";
            default -> frameworks.get(ThreadLocalRandom.current().nextInt(frameworks.size()));
        };
    }

    private String reframeContent(String content, VocabularyGrade targetGrade, TopicDomain domain)
    {
        // If content is already at grade, return as-is
        String[] contentWords = content.split("\\s+");
        VocabularyGrade contentGrade = inferGrade(contentWords, content);

        if (contentGrade == targetGrade) return content;

        // For higher grades: add domain-specific vocabulary enrichment
        if (targetGrade.level > contentGrade.level)
        {
            List<String> domainWords = domainVocabulary.get(domain);
            if (domainWords != null && !domainWords.isEmpty())
            {
                // Insert a domain-relevant qualifier
                String qualifier = domainWords.get(ThreadLocalRandom.current().nextInt(
                    Math.min(domainWords.size(), 5)));
                if (!content.toLowerCase().contains(qualifier.toLowerCase()))
                {
                    // Add as context enrichment at natural break points
                    int midpoint = content.indexOf(". ");
                    if (midpoint > 0 && midpoint < content.length() - 10)
                        return content.substring(0, midpoint + 2)
                            + "In " + qualifier + " terms, " + content.substring(midpoint + 2);
                }
            }
        }

        return content;
    }

    private String addElaboration(InferenceResult inf, String content)
    {
        List<String> transitions = transitionPhrases.get(inf.grade);
        if (transitions == null || transitions.isEmpty()) return null;

        String transition = transitions.get(ThreadLocalRandom.current().nextInt(transitions.size()));

        return switch (inf.intent)
        {
            case QUESTION_FACTUAL -> transition + " this is well-established in the field.";
            case QUESTION_HOW -> transition + " the process involves careful attention to each step.";
            case QUESTION_WHY -> transition + " understanding the underlying mechanism is key.";
            case QUESTION_OPINION -> transition + " reasonable perspectives may differ on this.";
            case COMPLAINT -> transition + " addressing this systematically should help resolve it.";
            default -> null;
        };
    }

    private String selectClosing(InferenceResult inf)
    {
        return switch (inf.intent)
        {
            case QUESTION_FACTUAL, QUESTION_HOW, QUESTION_WHY ->
                inf.grade.level >= 3 ? "Let me know if you'd like further detail." : "";
            case QUESTION_OPINION -> "That said, thoughtful disagreement is always welcome.";
            case COMPLAINT -> "I'm here to help resolve this.";
            case GREETING -> "";
            case FAREWELL -> "Take care.";
            case GRATITUDE -> "";
            default -> "";
        };
    }

    private String composeEmptyResponse(InferenceResult inf)
    {
        return switch (inf.intent)
        {
            case GREETING -> "Hello. How can I help you today?";
            case FAREWELL -> "Goodbye. Take care.";
            case GRATITUDE -> "You're welcome. Happy to help.";
            case AGREEMENT -> "Good. Let me know if there's anything else.";
            case CONTINUATION -> "I'm listening — please go ahead.";
            default -> "I don't have enough information to give you a thorough answer on that yet. Could you provide more detail?";
        };
    }

    // ── Key Term Extraction ────────────────────────────────────────────────────

    private String[] extractKeyTerms(String[] words)
    {
        // Filter out stop words, keep content words
        return Arrays.stream(words)
            .map(w -> w.replaceAll("[^a-zA-Z0-9-]", ""))
            .filter(w -> w.length() > 3)
            .filter(w -> !STOP_WORDS.contains(w.toLowerCase()))
            .distinct()
            .limit(8)
            .toArray(String[]::new);
    }

    private double computeConfidence(Intent intent, VocabularyGrade grade, TopicDomain domain, String[] words)
    {
        double conf = 0.5; // base
        if (intent != Intent.UNKNOWN) conf += 0.2;
        if (domain != TopicDomain.GENERAL) conf += 0.15;
        if (words.length > 5) conf += 0.1;
        if (grade.level >= 3) conf += 0.05;
        return Math.min(conf, 1.0);
    }

    // ── Vocabulary Loading ─────────────────────────────────────────────────────

    private void loadAllVocabulary()
    {
        loadDomainKeywords();
        loadTransitionPhrases();
        loadResponseFrameworks();
        loadDomainVocabulary();
        loadConversationalPairs();
        loadIdiomExpansions();
    }

    private void loadDomainKeywords()
    {
        // Technology
        for (String k : new String[]{"computer", "software", "hardware", "algorithm", "database",
            "server", "network", "api", "code", "program", "linux", "kernel", "cpu", "gpu",
            "memory", "disk", "cloud", "docker", "kubernetes", "java", "python", "javascript",
            "compiler", "runtime", "thread", "process", "port", "socket", "http", "tcp", "udp",
            "encryption", "ssl", "tls", "certificate", "key", "hash", "binary", "byte"})
            domainKeywords.put(k, TopicDomain.TECHNOLOGY);

        // Science
        for (String k : new String[]{"physics", "chemistry", "biology", "molecule", "atom",
            "cell", "gene", "evolution", "experiment", "hypothesis", "theory", "quantum",
            "relativity", "gravity", "photon", "electron", "proton", "neutron", "energy",
            "force", "mass", "velocity", "acceleration", "entropy", "thermodynamics"})
            domainKeywords.put(k, TopicDomain.SCIENCE);

        // Mathematics
        for (String k : new String[]{"equation", "calculus", "algebra", "geometry", "theorem",
            "proof", "integral", "derivative", "matrix", "vector", "probability", "statistics",
            "prime", "factorial", "logarithm", "exponential", "polynomial", "topology", "set",
            "function", "limit", "convergence", "series", "sequence", "permutation"})
            domainKeywords.put(k, TopicDomain.MATHEMATICS);

        // Philosophy & Ethics
        for (String k : new String[]{"ethics", "moral", "philosophy", "metaphysics", "epistemology",
            "ontology", "consciousness", "existence", "truth", "justice", "virtue", "duty",
            "freedom", "will", "determinism", "utilitarianism", "deontology", "categorical",
            "imperative", "phenomenology", "hermeneutics", "dialectic"})
            domainKeywords.put(k, TopicDomain.PHILOSOPHY);

        // Law
        for (String k : new String[]{"legal", "law", "statute", "regulation", "court", "judge",
            "attorney", "plaintiff", "defendant", "verdict", "sentence", "contract", "tort",
            "jurisdiction", "precedent", "constitution", "amendment", "rights", "due process",
            "habeas corpus", "litigation", "arbitration", "compliance"})
            domainKeywords.put(k, TopicDomain.LAW);

        // Economics & Finance
        for (String k : new String[]{"economy", "market", "stock", "bond", "investment", "gdp",
            "inflation", "interest", "fiscal", "monetary", "trade", "tariff", "deficit",
            "surplus", "supply", "demand", "equilibrium", "recession", "growth", "tax",
            "revenue", "budget", "portfolio", "dividend", "yield", "bitcoin", "crypto"})
            domainKeywords.put(k, TopicDomain.FINANCE);

        // Politics
        for (String k : new String[]{"politics", "government", "democracy", "republic", "senator",
            "congress", "president", "election", "vote", "party", "liberal", "conservative",
            "progressive", "policy", "legislation", "cabinet", "parliament", "diplomacy"})
            domainKeywords.put(k, TopicDomain.POLITICS);

        // Medicine
        for (String k : new String[]{"medical", "doctor", "patient", "diagnosis", "treatment",
            "surgery", "medication", "therapy", "symptom", "disease", "virus", "bacteria",
            "vaccine", "immune", "clinical", "hospital", "pharmaceutical", "anatomy"})
            domainKeywords.put(k, TopicDomain.MEDICINE);

        // History
        for (String k : new String[]{"history", "historical", "ancient", "medieval", "colonial",
            "revolution", "war", "empire", "dynasty", "civilization", "century", "era",
            "epoch", "renaissance", "enlightenment", "industrial"})
            domainKeywords.put(k, TopicDomain.HISTORY);

        // Engineering
        for (String k : new String[]{"engineering", "design", "mechanical", "electrical", "civil",
            "structural", "aerospace", "manufacturing", "prototype", "specification", "tolerance",
            "circuit", "signal", "frequency", "bandwidth", "antenna", "sensor"})
            domainKeywords.put(k, TopicDomain.ENGINEERING);

        // Education
        for (String k : new String[]{"education", "school", "university", "college", "curriculum",
            "student", "teacher", "professor", "degree", "diploma", "course", "lecture",
            "research", "thesis", "dissertation", "pedagogy", "learning"})
            domainKeywords.put(k, TopicDomain.EDUCATION);

        // System operations (NWE-specific)
        for (String k : new String[]{"port", "module", "strernary", "nwe", "nitro", "server",
            "service", "status", "config", "install", "boot", "kernel", "daemon", "systemctl",
            "mysql", "dave", "epmp", "negamane", "clamav", "chromium", "tomcat", "apache"})
            domainKeywords.put(k, TopicDomain.SYSTEM_OPERATIONS);
    }

    private void loadTransitionPhrases()
    {
        transitionPhrases.put(VocabularyGrade.BASIC, List.of(
            "Also,", "And", "Plus,", "So,"
        ));
        transitionPhrases.put(VocabularyGrade.CONVERSATIONAL, List.of(
            "Additionally,", "On top of that,", "It's worth noting that",
            "Keep in mind that", "Along those lines,"
        ));
        transitionPhrases.put(VocabularyGrade.EDUCATED, List.of(
            "Furthermore,", "It bears mentioning that", "In this context,",
            "From a practical standpoint,", "Notably,"
        ));
        transitionPhrases.put(VocabularyGrade.SCHOLARLY, List.of(
            "Moreover,", "It is germane to observe that", "In the broader framework,",
            "From an analytical perspective,", "This intersects with the consideration that"
        ));
        transitionPhrases.put(VocabularyGrade.LITERARY, List.of(
            "One might further observe,", "In the broader tapestry of this matter,",
            "The consideration extends naturally to", "There is a quiet resonance here —"
        ));
    }

    private void loadResponseFrameworks()
    {
        responseFrameworks.put(Intent.QUESTION_FACTUAL, List.of(
            "To answer directly:", "The answer is as follows.",
            "Based on what I know:", "Here's the factual breakdown:",
            "In short:"
        ));
        responseFrameworks.put(Intent.QUESTION_HOW, List.of(
            "Here's how:", "The process involves the following steps:",
            "To accomplish this:", "The approach is:",
            "You'd want to:"
        ));
        responseFrameworks.put(Intent.QUESTION_WHY, List.of(
            "The reason is:", "This happens because:",
            "The underlying cause:", "To explain the mechanism:",
            "It comes down to:"
        ));
        responseFrameworks.put(Intent.QUESTION_OPINION, List.of(
            "From my assessment:", "My informed view:",
            "Weighing the factors:", "Considering the evidence:",
            "A balanced perspective suggests:"
        ));
        responseFrameworks.put(Intent.REQUEST_INFORMATION, List.of(
            "Here's what I can tell you:", "The relevant information:",
            "To address your request:", "Based on available data:",
            "Here's the overview:"
        ));
        responseFrameworks.put(Intent.COMPLAINT, List.of(
            "I understand the frustration.", "Let me help address this.",
            "I see the issue.", "That's a valid concern.",
            "Let me look into this."
        ));
        responseFrameworks.put(Intent.GREETING, List.of(
            "Hello!", "Good to hear from you.", "Welcome.",
            "Hi there.", "Greetings."
        ));
        responseFrameworks.put(Intent.CLARIFICATION, List.of(
            "Let me clarify.", "To put it more precisely:",
            "What I mean is:", "In other words:",
            "To elaborate:"
        ));
        responseFrameworks.put(Intent.STATEMENT_FACT, List.of(
            "Understood.", "Noted.", "I see.", "That's consistent with what I know.",
            "That aligns with the current understanding."
        ));
        responseFrameworks.put(Intent.STATEMENT_OPINION, List.of(
            "I appreciate that perspective.", "That's a thoughtful point.",
            "I can see the reasoning there.", "That's worth considering.",
            "An interesting take."
        ));
    }

    private void loadDomainVocabulary()
    {
        domainVocabulary.put(TopicDomain.TECHNOLOGY, List.of(
            "computational", "algorithmic", "architectural", "scalable", "distributed",
            "concurrent", "asynchronous", "deterministic", "fault-tolerant", "modular",
            "interoperable", "idempotent", "stateless", "polymorphic", "encapsulated"
        ));
        domainVocabulary.put(TopicDomain.SCIENCE, List.of(
            "empirical", "theoretical", "observational", "quantitative", "qualitative",
            "reproducible", "systematic", "causal", "correlative", "falsifiable",
            "predictive", "explanatory", "reductionist", "holistic", "emergent"
        ));
        domainVocabulary.put(TopicDomain.PHILOSOPHY, List.of(
            "epistemic", "ontological", "phenomenological", "dialectical", "teleological",
            "deontological", "consequentialist", "existential", "hermeneutic", "transcendental",
            "normative", "descriptive", "analytic", "synthetic", "a priori"
        ));
        domainVocabulary.put(TopicDomain.LAW, List.of(
            "jurisprudential", "statutory", "adjudicative", "prosecutorial", "equitable",
            "fiduciary", "procedural", "substantive", "appellate", "legislative",
            "regulatory", "contractual", "tortious", "jurisdictional", "constitutional"
        ));
        domainVocabulary.put(TopicDomain.FINANCE, List.of(
            "fiscal", "monetary", "actuarial", "fiduciary", "speculative",
            "deflationary", "inflationary", "macroeconomic", "microeconomic", "derivatives",
            "amortized", "capitalized", "leveraged", "hedged", "diversified"
        ));
        domainVocabulary.put(TopicDomain.MEDICINE, List.of(
            "pathological", "physiological", "pharmacological", "epidemiological", "clinical",
            "diagnostic", "therapeutic", "prophylactic", "symptomatic", "idiopathic",
            "comorbid", "palliative", "surgical", "oncological", "immunological"
        ));
        domainVocabulary.put(TopicDomain.ENGINEERING, List.of(
            "structural", "thermal", "electromagnetic", "kinematic", "dynamic",
            "resonant", "parametric", "toleranced", "calibrated", "optimized",
            "load-bearing", "fatigue-resistant", "precision-machined", "spec-compliant", "field-tested"
        ));
        domainVocabulary.put(TopicDomain.GENERAL, List.of(
            "practical", "systematic", "well-considered", "measured", "contextual",
            "proportional", "substantive", "meaningful", "coherent", "reliable"
        ));
    }

    private void loadConversationalPairs()
    {
        // Load from TSV if available
        Path vocabTsv = Path.of("training/vocabulary/conversational-pairs.tsv");
        if (Files.exists(vocabTsv))
        {
            try (BufferedReader reader = Files.newBufferedReader(vocabTsv))
            {
                String line;
                while ((line = reader.readLine()) != null)
                {
                    String[] parts = line.split("\t", 2);
                    if (parts.length == 2)
                        conversationalPairs.add(parts);
                }
            }
            catch (IOException ignored) {}
        }
    }

    private void loadIdiomExpansions()
    {
        idiomExpansions.put("in a nutshell", "to summarize concisely");
        idiomExpansions.put("at the end of the day", "ultimately");
        idiomExpansions.put("cutting edge", "at the forefront of current development");
        idiomExpansions.put("game changer", "a fundamentally transformative factor");
        idiomExpansions.put("the bottom line", "the essential conclusion");
        idiomExpansions.put("food for thought", "something worth careful consideration");
        idiomExpansions.put("the big picture", "the broader context and implications");
        idiomExpansions.put("rule of thumb", "a practical general guideline");
        idiomExpansions.put("state of the art", "representing the highest current standard");
        idiomExpansions.put("on the same page", "sharing a common understanding");
    }

    // ── Utility ────────────────────────────────────────────────────────────────

    private boolean matchesAny(String input, String... candidates)
    {
        for (String c : candidates)
            if (input.startsWith(c) || input.equals(c) || input.contains(c))
                return true;
        return false;
    }

    // ── Vocabulary Constants ───────────────────────────────────────────────────

    private static final Set<String> STOP_WORDS = Set.of(
        "the", "a", "an", "is", "are", "was", "were", "be", "been", "being",
        "have", "has", "had", "do", "does", "did", "will", "would", "could",
        "should", "may", "might", "shall", "can", "need", "dare", "ought",
        "used", "to", "of", "in", "for", "on", "with", "at", "by", "from",
        "as", "into", "through", "during", "before", "after", "above", "below",
        "between", "under", "again", "further", "then", "once", "here", "there",
        "when", "where", "why", "how", "all", "each", "every", "both", "few",
        "more", "most", "other", "some", "such", "no", "nor", "not", "only",
        "own", "same", "than", "too", "very", "just", "because", "but", "and",
        "or", "if", "while", "about", "this", "that", "these", "those", "it",
        "its", "they", "them", "their", "what", "which", "who", "whom"
    );

    private static final String[] ACADEMIC_VOCABULARY = {
        "furthermore", "consequently", "nevertheless", "notwithstanding", "accordingly",
        "subsequently", "predominantly", "fundamentally", "inherently", "substantively",
        "empirically", "theoretically", "systematically", "methodologically", "conceptually",
        "paradigm", "framework", "methodology", "ontological", "epistemological",
        "heuristic", "deterministic", "probabilistic", "axiomatic", "canonical"
    };

    private static final String[] LITERARY_VOCABULARY = {
        "wherein", "thereof", "herein", "heretofore", "inasmuch", "insofar",
        "juxtaposition", "dichotomy", "paradox", "allegory", "ephemeral",
        "transcendent", "ineffable", "quintessential", "verisimilitude",
        "melancholy", "sublime", "luminous", "resonance", "cadence"
    };
}
