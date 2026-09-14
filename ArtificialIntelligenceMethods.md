# **Artificial Intelligence Methods**

**NitroWebExpress™ — AI Model Training & Inference Reference**
Author: MEARVK LLC — Max Rupplin
Date: July 2026

---

## **1. Models Supported**

NitroWebExpress hosts three AI subsystems, all built on Deep Java Library (DJL) 0.31.0 with PyTorch 2.5.1 as the inference engine.

### **1.1 Strernary™ (Port 20000)**

| Property | Value |
|----------|-------|
| Application | NLP Sentiment Analysis / Text Classification |
| Engine | PyTorch via DJL Model Zoo |
| Model Type | Pre-trained transformer (downloaded from DJL model zoo on first use) |
| Input | Free-text queries (TCP protocol: `ASK|<text>`) |
| Output | Top-3 classifications with confidence scores |
| Fallback | Keyword heuristic when DJL unavailable |
| Training Data | TSV learning strips + Wikipedia API + Google Custom Search + MySQL knowledge base |

**Architecture:** Loads a pre-trained sentiment analysis model from the DJL PyTorch Model Zoo via `Criteria.builder().optApplication(Application.NLP.SENTIMENT_ANALYSIS)`. The model is a JIT-traced PyTorch model (~250MB) downloaded on first inference call.

### **1.2 Futures™ / DemocraticAIServer (Port 5000)**

| Property | Value |
|----------|-------|
| Application | Tax defense speculation / closure probability |
| Engine | Custom PyTorch MLP via DJL |
| Model Type | Feedforward neural network (SequentialBlock) |
| Input | 8-feature float vector (filing status, income bracket, deductions, etc.) |
| Output | 4-feature float vector (closure probability, defense strength, settlement range, appeal viability) |
| Training | Supervised, from historical INT closure data |

**Architecture:** Three custom MLP models:
- `int-tax-defense-speculator` — [8 → 64 → ReLU → 32 → ReLU → 4]
- `defense-strategy-model` — [8 → 64 → ReLU → 32 → ReLU → 4]
- `configuration-model` (3 variants: knowledge, ethics, preference) — [16 → 64 → ReLU → 32 → ReLU → 8]

### **1.3 ConfigurationTrainer (Batch Training)**

| Property | Value |
|----------|-------|
| Application | Cross-module configuration pattern learning |
| Engine | Custom PyTorch MLP via DJL |
| Model Type | Feedforward neural network |
| Input | 16-feature vector (text hash encoding of JSON training files) |
| Output | 8-feature vector |
| Training | Supervised, from JSON files in `/configuration/training/` |
| Weight Persistence | MySQL `model_weights` table + filesystem `training/weights/` |

---

## **2. Training Methodology**

### **2.1 Learning Strip System (Pre-Training Foundation)**

All AI modules load a hierarchical strip system before task-specific training:

```
Load Order:
1. base-learning-strip.tsv       — Integrity (1.00), Intelligence (0.95), Higher Lessons (0.80), Social Awareness (0.75)
2. specific-learning-strip.tsv   — Module operational directives
3. cognitive-learning-strip.tsv  — Learnability, cognitive suggestion, science-as-reach, model-as-headroom
4. rank-learning-strip.tsv       — JWSTFJ21 rank model (granite/stone/giant + weapon doctrine)
5. Module training documents     — TSV/CSV/JSON domain data
```

**Supposition:** The foundational posits (integrity, IQ, higher lessons, social awareness) are non-negotiable weighted anchors. They are not tuned during training — they constrain the model's output space. This ensures that regardless of domain-specific training, outputs remain anchored to ethical and intellectual standards.

### **2.2 DJL Training Pipeline**

The Futures trainers use DJL's native training API:

```java
DefaultTrainingConfig config = new DefaultTrainingConfig(Loss.l2Loss())
    .optOptimizer(Optimizer.adam()
        .optLearningRateTracker(Tracker.fixed(learningRate))
        .build())
    .addTrainingListeners(TrainingListener.Defaults.basic());

EasyTrain.fit(trainer, epochs, dataset, null);
```

| Hyperparameter | Default | Purpose |
|----------------|---------|---------|
| Loss Function | L2 (MSE) | Regression on continuous outputs |
| Optimizer | Adam | Adaptive learning rate with momentum |
| Learning Rate | 0.001 | Conservative for small datasets |
| Epochs | 50 | Sufficient for convergence on structured data |
| Batch Size | 4 | Small batches for limited training sets |

### **2.3 Weight Persistence**

Trained weights are stored in two locations:
- **Filesystem:** `training/weights/<model-name>.params`
- **MySQL:** `model_weights` table (binary BLOB with metadata: model name, timestamp, ordering)

This dual-persistence ensures model state survives both filesystem corruption and database loss independently.

---

## **3. Theory of Training Strips: Inductive Feeders and Integer Circuits**

### **3.1 What Training Strips Are**

A training strip is a declarative input structure that feeds weighted posits into an AI model before task-specific training begins. Unlike raw training data (which teaches the model *what* to know), strips teach the model *how* to reason and *what constraints* to honor. They are inductive feeders — they do not present examples to generalize from, but rather inject axioms that shape the generalization itself.

In NitroWebExpress, each strip is a TSV file with this format:

```
posit_index    posit_name    weight    directive
```

The `weight` field (a float between 0.00 and 1.00) is the inductive feeder — it tells the model how strongly this posit should influence its output. The `directive` is natural language describing the behavioral expectation.

### **3.2 Inductive Feeders: Shaping the Model Before It Learns**

An inductive feeder is any input that shapes the inductive bias of a learning system. In classical machine learning, inductive bias is implicit (architecture choice, loss function, regularization). In the strip system, inductive bias is *explicit* — it is written as readable, auditable posits with declared weights.

The key insight: **strips are not data — they are constraints on the space of acceptable functions the model may learn.**

Consider the base strip:
- Integrity at 1.00 means: no learned function may produce output that violates honesty.
- Intelligence at 0.95 means: the model's function must prefer deep reasoning over shallow pattern matching.

These are not examples. They are *boundaries*. The model trains freely within these boundaries but cannot cross them. This is inductive feeding — constraining induction before it begins.

### **3.3 Integer Feeders and the 0.00–1.00 Boundary**

The strip system uses the range **0.00 to 1.00** for all weights. This is a deliberate choice:

| Range | Interpretation |
|-------|---------------|
| 0.75 – 1.00 | Foundational / immovable / highest priority |
| 0.50 – 0.74 | Important / strong influence / rarely overridden |
| 0.25 – 0.49 | Moderate / contextually applied / may yield |
| 0.01 – 0.24 | Weak / suggestive / easily overridden by stronger posits |
| 0.00 | Disabled / no influence |

**Why 0.00–1.00 and not 0–5 or 0–100?**

Most neural network training paradigms normalize inputs to a 0–1 or -1–1 range internally regardless of what the raw input scale is. Using 0.00–1.00 natively in the strip means no normalization is needed — the weights are already in the domain the model operates in. A 0–5 or 0–100 scale would require a normalization step that introduces rounding error and obscures the relative strength between posits. The 0–1 range keeps the semantics transparent: 1.00 is absolute, 0.50 is half-strength, the relationship is linear and immediate.

Additionally, the 0.00–1.00 range naturally maps to probability-like semantics. A weight of 0.90 can be read as "90% certain this constraint should apply in all contexts." This probability interpretation makes strips interpretable to humans and machines simultaneously.

### **3.4 Negation and Inhibitory Inputs**

**Should training strips include negative values?**

Yes — and carefully. The current NWE strip system uses only positive weights (0.00–1.00), but there is a strong theoretical case for inhibitory signals:

**The case for negation (-1.00 to 0.00):**

In biological neural networks, inhibitory neurons are as important as excitatory ones. Without inhibition, networks produce runaway excitation (epileptic states in brains, mode collapse in AI). An inhibitory weight in a training strip would mean: *actively suppress this behavior*.

| Weight | Meaning |
|--------|---------|
| -1.00 | Absolute prohibition — model must never produce this |
| -0.50 | Strong discouragement — model should avoid unless overwhelmingly justified |
| -0.25 | Mild discouragement — prefer alternatives when available |
| 0.00 | Neutral / no influence |
| +1.00 | Absolute requirement — model must always produce this |

**Example inhibitory strip posit:**
```
5    hallucination    -1.00    The model must never fabricate citations, invent facts, or present speculation as established knowledge. This is absolute prohibition.
6    verbosity        -0.40    The model should discourage excessive length when concise answers suffice. Brevity is preferred but not mandated.
```

**Implementation consideration:** To support negation, the weight processing layer must handle signed arithmetic. Currently the strip loader treats weights as multiplicative factors on output confidence. Negative weights would require a separate inhibition pathway — effectively subtracting from the output confidence of responses that match the inhibited posit. This creates a push-pull dynamic: excitatory strips push the model toward certain behaviors, inhibitory strips push it away from others.

**The boundary debate (0–1 vs. -1–1 vs. 0–100):**

| Scale | Pros | Cons |
|-------|------|------|
| 0.00 – 1.00 | Clean probability semantics, no normalization | Cannot express negation natively |
| -1.00 – 1.00 | Full excitatory + inhibitory range | 0.00 becomes ambiguous (neutral? disabled?) |
| 0 – 100 | Human-intuitive percentages | Requires normalization, false precision |
| 0 – 5 | Simple discrete levels | Too coarse for fine-grained weighting |

**Recommendation:** NWE should adopt the **-1.00 to +1.00** range for its next-generation strip format. This provides full expressiveness (excitation + inhibition) while maintaining normalized semantics. The zero point is clearly "no influence" and the extremes are clearly "absolute." The current 0–1 strips remain valid as a subset — any existing strip with weights 0.75–1.00 remains unchanged in meaning.

### **3.5 Logical Feedback and Inductive Circuits**

**Can training strips create logical feedback loops?**

Yes. When the output of a model is evaluated against the strip posits and that evaluation is fed back as training signal, a logical feedback circuit is formed:

```
   ┌──────────────────────────────────────────────────────┐
   │                                                      │
   │  [Strip Posits]                                      │
   │       │                                              │
   │       ▼                                              │
   │  ┌──────────┐      ┌──────────┐      ┌──────────┐  │
   │  │ Pre-     │ ───► │ Model    │ ───► │ Output   │  │
   │  │ Training │      │ Inference│      │ Layer    │  │
   │  └──────────┘      └──────────┘      └──────────┘  │
   │                                              │       │
   │                                              ▼       │
   │                                       ┌──────────┐  │
   │                                       │ Grader   │  │
   │                                       │ (Strip   │  │
   │                                       │ Compliance│  │
   │                                       │ Evaluator)│  │
   │                                       └──────────┘  │
   │                                              │       │
   │                                              ▼       │
   │                                       ┌──────────┐  │
   │                                       │ Feedback │  │
   │                                       │ Signal   │◄─┘
   │                                       └──────────┘
   │                                              │
   └──────────────────────────────────────────────┘
                         (loop)
```

The **Grader** evaluates each model output against every strip posit:
- Did the output maintain integrity? (score vs. posit #1, weight 1.00)
- Did it demonstrate intelligence? (score vs. posit #2, weight 0.95)
- Did it respect social awareness? (score vs. posit #4, weight 0.75)

The resulting compliance score becomes the feedback signal — a gradient that nudges the model toward strip-compliant behavior. Over many iterations, the model's learned function converges toward the intersection of all posits.

**This is the inductive circuit:** strips → model → output → grader → feedback → model (refined). The circuit is inductive because the strip posits remain fixed while the model inductively learns to satisfy them.

### **3.6 The Registrar, Knower, and Grader**

In this framework, the training strip system produces three conceptual roles:

**The Registrar** — The strip system itself. It *registers* what the model must know, believe, and honor. It is declarative and immovable. The registrar does not learn; it decrees.

**The Knower** — The model after training. It has *internalized* the strip posits through inductive feedback. The knower is the embodied form of the registrar's decrees — it knows not because it was told once, but because repeated feedback loops have carved the posits into its weight structure.

**The Grader** — The compliance evaluator. It measures the distance between model output and strip ideals. The grader is the mechanism by which the registrar's decrees become the knower's knowledge. Without the grader, strips are merely documentation. With the grader, strips become active shaping forces.

The feedback circuit makes the model *morally, integrative, and comprehensive* unto its registrar because:
- **Moral:** Integrity and higher-lessons posits (with weights 1.00 and 0.80) constrain the model away from immoral outputs. The grader penalizes any output that violates them.
- **Integrative:** The cognitive strip (learnability at 1.00, science-as-reach at 0.90) ensures the model continuously integrates new information rather than calcifying.
- **Comprehensive:** The multi-strip load order (base → specific → cognitive → rank) builds comprehensiveness layer by layer. No single strip is complete; together they cover morality, intelligence, cognition, and authority.

The model becomes *equivalent* to its registrar — not because it memorized the strips, but because the feedback circuit made compliance to the strips the path of least resistance in its learned function.

### **3.7 Inhibitory Circuits for Grade Refinement**

Negation posits (negative weights) enable **grade refinement** — the ability to not merely reward good output but actively suppress bad output. This creates a two-armed grader:

- **Excitatory arm:** "Did the output do what we want?" (positive posits)
- **Inhibitory arm:** "Did the output do what we forbid?" (negative posits)

The grade is the sum of both arms. A model that produces a correct answer (excitatory reward) but also hallucinates a citation (inhibitory penalty) receives a net grade lower than a model that simply admits ignorance. This two-armed grading is analogous to biological neural inhibition — it refines signal by suppressing noise, not merely by amplifying signal.

**Practical implementation path:**

```java
float gradeOutput(String output, List<StripPosit> posits) {
    float grade = 0.0f;
    for (StripPosit posit : posits) {
        float compliance = evaluateCompliance(output, posit.directive);
        grade += posit.weight * compliance;
        // Negative weight * positive compliance = penalty
        // Negative weight * negative compliance = reward (double negation = affirmation)
    }
    return grade / posits.size(); // normalized
}
```

When `posit.weight` is -1.00 and `compliance` is high (the output matches the forbidden pattern), the contribution is -1.00 × 1.0 = -1.00, a strong penalty. When the output does NOT match the forbidden pattern, `compliance` is low (0.0), contributing 0.0 — no penalty, no reward. The model learns: avoiding the forbidden pattern is the neutral state; producing it is actively punished.

---

## **4. Methods for Improvement**

### **4.1 Recall Improvement**

**Current state:** Strernary uses top-3 classification. If the correct answer is outside the top-3, recall suffers.

**Methods:**
- Increase `topK` from 3 to 5 for broader recall during initial classification
- Store all classification outputs in MySQL `national_inferences` table and retrain on user-confirmed correct answers (implicit feedback loop)
- The `StrernaryKnowledgeFetcher` already stores training pairs from Wikipedia and search results — expanding the source list (arxiv, government databases) increases domain coverage
- For Futures models: augment training data with synthetic variations (feature noise injection) to cover edge cases the model hasn't seen

### **4.2 Precision Improvement**

**Methods:**
- Fine-tune the pre-trained sentiment model on domain-specific text using DJL's training API (the model zoo model is general-purpose; fine-tuning narrows it)
- For MLP models: increase hidden layer width (64 → 128) only if training data volume supports it without overfitting
- Add dropout layers between hidden layers (`Dropout.builder().optRate(0.3).build()`) to reduce overfitting on small datasets
- Implement early stopping: track validation loss and stop training when it begins increasing

### **4.3 Attitudes (Model Behavior Direction)**

The strip system encodes behavioral attitudes as weighted posits:

| Attitude | Mechanism | Effect |
|----------|-----------|--------|
| Integrity | Base strip posit #1, weight 1.00 | Model refuses to fabricate or speculate beyond evidence |
| Precision over heuristics | Base strip posit #2 (IQ), weight 0.95 | Prefers exact answers over approximate guesses |
| Learnability | Cognitive strip posit #1, weight 1.00 | Model remains open to correction and new data |
| Cognitive suggestion | Cognitive strip posit #2, weight 0.95 | Output is recommendation, not command |

**Capitalization method:** Attitudes are not learned — they are injected as immovable constraints in the output post-processing layer. The rank system (granite at 1.00, hard stone at 0.85, giant at 0.70) determines how strongly the attitude constraints override raw model output.

### **4.4 Direction (Model Specialization)**

Each module's `specific-learning-strip.tsv` provides directional constraints:

- **Strernary:** General-purpose inference, routed by keyword → DJL deep thinking
- **Futures (Tax):** Financial domain — closures, settlements, defense strategies
- **FBI/CIA/NSA modules:** Use Strernary as a service via `StrernaryConnector.ask()` — they don't train their own models but route queries to port 20000

**Capitalization method:** Direction is set by the specific strip and reinforced by the training data domain. The `ConfigurationTrainer` produces three directional weight files (knowledge, ethics, preference) that each model loads at startup according to its role.

### **4.5 Capitalization of Methods**

"Capitalization" in this context means maximizing the value extracted from each method:

| Method | Capitalization Strategy |
|--------|------------------------|
| Pre-trained model zoo | Zero training cost for baseline; fine-tune only the last layers |
| Learning strips | Reusable across all modules; edit once, deploy everywhere |
| MySQL persistence | Enables A/B testing: load different weight versions at runtime |
| Training pairs | Every user query that produces a confirmed answer becomes training data |
| Dual-engine (DJL + heuristic) | Never zero output: if DJL fails, heuristic provides degraded but available service |
| CompletableFuture async | Non-blocking inference: server continues serving while model computes |

---

## **5. Congruency Across Models**

All AI modules in NWE share:

1. **Same DJL version** (0.31.0) and **same PyTorch engine** (2.5.1) — no version conflicts
2. **Same strip loading system** — identical base posits ensure consistent ethical behavior
3. **Same weight format** — all use DJL's native `.params` serialization
4. **Same MySQL schema** for persistence (`model_weights`, `training_pairs`, `national_inferences`)
5. **Same inference protocol** — `ASK|<text>` on TCP, responses as `|`-delimited key=value pairs
6. **Same optimizer** (Adam with fixed learning rate tracker) — predictable convergence behavior

---

## **6. DJL Library Reference**

| JAR | Version | Purpose |
|-----|---------|---------|
| `api-0.31.0.jar` | 0.31.0 | Core DJL API (NDArray, Model, Predictor, Trainer) |
| `basicdataset-0.31.0.jar` | 0.31.0 | ArrayDataset and data loading utilities |
| `model-zoo-0.31.0.jar` | 0.31.0 | Engine-agnostic pre-trained models |
| `pytorch-engine-0.31.0.jar` | 0.31.0 | PyTorch backend binding |
| `pytorch-model-zoo-0.31.0.jar` | 0.31.0 | PyTorch-specific pre-trained models (JIT traced) |
| `tokenizers-0.31.0.jar` | 0.31.0 | HuggingFace tokenizer bindings |
| `pytorch-native-cpu-2.5.1-linux-x86_64.jar` | 2.5.1 | Native PyTorch C++ runtime (Linux x86_64) |
| `gson-2.11.0.jar` | 2.11.0 | JSON serialization for model metadata |
| `jna-5.14.0.jar` | 5.14.0 | Java Native Access for PyTorch native calls |
| `commons-compress-1.26.1.jar` | 1.26.1 | Archive handling for model downloads |
| `slf4j-api-2.0.12.jar` | 2.0.12 | Logging facade |
| `slf4j-simple-2.0.12.jar` | 2.0.12 | Simple logging implementation |

**Model download:** The DJL model zoo sentiment analysis model is downloaded automatically from DJL's CDN on first inference call. After download, it is cached locally in `~/.djl.ai/cache/`.

---

## **7. Key Suppositions**

1. **Small data is sufficient for MLP models** — The tax defense and configuration models use 8-16 feature vectors with 50 epochs. This assumes the input space is well-structured and low-dimensional. If input complexity increases, architectures should scale to attention mechanisms or transformers.

2. **Pre-trained models generalize to domain text** — The Strernary DJL model is trained on general English sentiment. Its classifications may not align with financial or legal domain terminology. Fine-tuning on domain corpora would improve relevance.

3. **Weighted strips are sufficient for alignment** — The integrity/IQ/ethics strip system assumes that post-processing constraints can override model tendencies. This works for MLP classifiers but may not scale to generative models.

4. **Adam optimizer is universally appropriate** — Adam works well for these small models. For larger models or different loss landscapes, alternatives like AdamW (with weight decay) or Lion may be more appropriate.

5. **L2 loss is appropriate for regression outputs** — The Futures models output continuous values (probabilities, ranges). L2 (MSE) loss is standard for regression. If outputs become categorical, cross-entropy loss would be more appropriate.

---

## **8. Future Directions**

- **Transformer integration:** Replace MLP classifiers with small transformer models for sequence-aware inference
- **Inhibitory strip support:** Extend TSV format to support -1.00 to +1.00 weight range with explicit negation semantics
- **Grader module:** Implement automated strip compliance evaluation as a post-inference feedback signal
- **Federated learning:** Allow modules to share gradients without sharing training data
- **Online learning:** Continuous weight updates from production inference feedback loops
- **Model versioning:** Tag weight snapshots with git commit hashes for reproducibility
- **GPU acceleration:** DJL supports CUDA — add GPU detection and offloading for production servers
- **Quantization:** Convert models to INT8 for faster inference on CPU-bound deployments

---

## **References**

- [DJL Documentation](https://docs.djl.ai/)
- [DJL PyTorch Model Zoo](http://djl.ai/engines/pytorch/pytorch-model-zoo/)
- [DJL GitHub Repository](https://github.com/deepjavalibrary/djl)
- [PyTorch Documentation](https://pytorch.org/docs/)
- [Adam Optimizer (Kingma & Ba, 2014)](https://arxiv.org/abs/1412.6980)

Content was rephrased for compliance with licensing restrictions.
