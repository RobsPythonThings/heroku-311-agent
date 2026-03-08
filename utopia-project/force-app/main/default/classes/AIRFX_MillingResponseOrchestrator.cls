public with sharing class AIRFX_MillingResponseOrchestrator {

    /**
     * For a single question: tries each engine in order until success or all fail.
     */
    public static AIRFX_QuestionResponseModels.ResponseItem answerOne(
        AIRFX_QuestionResponseModels.QuestionInput input,
        List<AIRFX_IResponseEngine> engines
    ) {
        if (engines == null || engines.isEmpty()) {
            throw new AuraHandledException('No engines provided.');
        }

        AIRFX_QuestionResponseModels.ResponseItem last = null;
        for (AIRFX_IResponseEngine eng : engines) {
            AIRFX_QuestionResponseModels.ResponseItem attempt = eng.process(input);
            if (attempt != null && attempt.success == true) {
                return attempt; // stop on first success
            }
            last = attempt;
        }
        // None succeeded; return the last attempt (has final error)
        return last == null ? new AIRFX_QuestionResponseModels.ResponseItem() : last;
    }

    /**
     * For multiple questions: "milling operation" over engines.
     * We keep track of unresolved items, pass them to next engine, etc.
     */
    public static AIRFX_QuestionResponseModels.ResponseBatch answerMany(
        List<AIRFX_QuestionResponseModels.QuestionInput> inputs,
        List<AIRFX_IResponseEngine> engines
    ) {
        if (engines == null || engines.isEmpty()) {
            throw new AuraHandledException('No engines provided.');
        }
        if (inputs == null) inputs = new List<AIRFX_QuestionResponseModels.QuestionInput>();

        // Map by index to keep ordering stable
        Map<Integer, AIRFX_QuestionResponseModels.ResponseItem> results = new Map<Integer, AIRFX_QuestionResponseModels.ResponseItem>();

        // Initialize as unresolved placeholders
        for (Integer i = 0; i < inputs.size(); i++) {
            results.put(i, null);
        }

        // A moving set of unresolved indices
        Set<Integer> unresolved = new Set<Integer>();
        for (Integer i = 0; i < inputs.size(); i++) { unresolved.add(i); }

        for (AIRFX_IResponseEngine eng : engines) {
            if (unresolved.isEmpty()) break;

            // Build a mini-batch for the current engine
            List<AIRFX_QuestionResponseModels.QuestionInput> batch = new List<AIRFX_QuestionResponseModels.QuestionInput>();
            List<Integer> indexOrder = new List<Integer>();
            for (Integer idx : unresolved) {
                batch.add(inputs[idx]);
                indexOrder.add(idx);
            }

            // Let engine process in batch (or loop its single-processor)
            AIRFX_QuestionResponseModels.ResponseBatch attemptBatch = eng.processBatch(batch);

            // Merge results
            Integer j = 0;
            for (AIRFX_QuestionResponseModels.ResponseItem got : attemptBatch.items) {
                Integer originalIdx = indexOrder[j++];
                if (got != null && got.success == true) {
                    results.put(originalIdx, got);
                } else {
                    // Keep only if we don't already have a success.
                    if (results.get(originalIdx) == null) {
                        results.put(originalIdx, got);
                    }
                }
            }

            // Recompute unresolved set
            Set<Integer> nextUnresolved = new Set<Integer>();
            for (Integer idx : unresolved) {
                AIRFX_QuestionResponseModels.ResponseItem ri = results.get(idx);
                if (ri == null || ri.success != true) {
                    nextUnresolved.add(idx);
                }
            }
            unresolved = nextUnresolved;
        }

        // Build final batch
        AIRFX_QuestionResponseModels.ResponseBatch finalBatch = new AIRFX_QuestionResponseModels.ResponseBatch();
        for (Integer i = 0; i < inputs.size(); i++) {
            finalBatch.items.add(results.get(i));
        }
        finalBatch.finalizeStatus();
        return finalBatch;
    }

    // Convenience overloads with a default engine order:
    public static AIRFX_QuestionResponseModels.ResponseItem answerOneDefault(AIRFX_QuestionResponseModels.QuestionInput input) {
        return answerOne(input, defaultEngines());
    }
    public static AIRFX_QuestionResponseModels.ResponseBatch answerManyDefault(List<AIRFX_QuestionResponseModels.QuestionInput> inputs) {
        return answerMany(inputs, defaultEngines());
    }
    public static List<AIRFX_IResponseEngine> defaultEngines() {
        // Order matters: put fast/cheap first, heavyweight last
        return new List<AIRFX_IResponseEngine>{
            //new AIRFX_TestingUtils(),
            new AIRFX_JarvisResponseEngine()
            //new AIRFX_AgentforceKnowledgeEngine()
        };
    }
}