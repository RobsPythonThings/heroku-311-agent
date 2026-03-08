/**
 * AIRFX_ConversationalAnswer
 *
 * Agentforce action for standalone conversational questions — no project or
 * record context required.  Queries all 6 CMDTs for grounding facts, calls
 * the DataCloud_RFP_Answer prompt template with ADL + HECVAT retrievers,
 * and returns a sourced answer directly to the agent.
 *
 * This prevents the "Record not found" error that occurs when the agent
 * tries to route a conversational question through the record-based
 * AIRFX_GenerateAnswer path.
 *
 * @author Robert Smith
 * @date   2026-03-08
 */
public with sharing class AIRFX_ConversationalAnswer {

    public class ConversationalRequest {
        @InvocableVariable(label='Question'
                          description='The standalone question to answer — no project context needed'
                          required=true)
        public String question;

        @InvocableVariable(label='Country Code'
                          description='Optional 2-letter country code for region-specific context (e.g. US, DE, AU)'
                          required=false)
        public String countryCode;

        @InvocableVariable(label='Product'
                          description='Optional product context (e.g. Sales Cloud, B2B Commerce)'
                          required=false)
        public String product;
    }

    public class ConversationalResult {
        @InvocableVariable(label='Answer'
                          description='The AI-generated answer grounded in CMDT + retrieved sources')
        public String answer;

        @InvocableVariable(label='Status'
                          description='SUCCESS or ERROR')
        public String status;

        @InvocableVariable(label='Error Message'
                          description='Error details if generation failed')
        public String errorMessage;

        @InvocableVariable(label='Sources Used'
                          description='Which sources contributed to the answer')
        public String sourcesUsed;
    }

    private static final String TEMPLATE_NAME = 'DataCloud_RFP_Answer';

    @InvocableMethod(label='Answer Conversational Question'
                     description='Answers a standalone security/compliance question using CMDT context and ADL retrieval. No project or record context required.')
    public static List<ConversationalResult> answerQuestion(List<ConversationalRequest> requests) {
        List<ConversationalResult> results = new List<ConversationalResult>();
        for (ConversationalRequest req : requests) {
            results.add(processRequest(req));
        }
        return results;
    }

    private static ConversationalResult processRequest(ConversationalRequest req) {
        ConversationalResult result = new ConversationalResult();

        if (String.isBlank(req.question)) {
            result.status = 'ERROR';
            result.errorMessage = 'Question text is required.';
            return result;
        }

        try {
            // 1. Build CMDT capability context (works with or without country/product)
            String country = String.isNotBlank(req.countryCode) ? req.countryCode : '';
            String product = String.isNotBlank(req.product) ? req.product : '';
            String cmdtContext = AIRFX_ResponseFlagInvocable.buildCMDTCapabilityContext(country, product);

            // 2. Default section for broad retrieval
            String sectionName = 'Section: Infrastructure and Security';

            // 3. Call the prompt template — same proven path as AIRFX_GenerateAnswer
            String generatedAnswer = callPromptTemplate(req.question, sectionName, cmdtContext);

            result.answer = generatedAnswer;
            result.status = 'SUCCESS';
            result.sourcesUsed = 'CMDT (certifications, features, hard nos, regulatory frameworks), ADL (HECVAT, SPARC, compliance docs)';

        } catch (ConnectApi.ConnectApiException cae) {
            result.status = 'ERROR';
            result.errorMessage = 'Answer generation failed: ' + cae.getMessage();
        } catch (Exception e) {
            result.status = 'ERROR';
            result.errorMessage = e.getTypeName() + ': ' + e.getMessage();
        }

        return result;
    }

    private static String callPromptTemplate(String questionText, String sectionName, String cmdtContext) {
        ConnectApi.EinsteinPromptTemplateGenerationsInput input =
            new ConnectApi.EinsteinPromptTemplateGenerationsInput();

        input.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        input.additionalConfig.applicationName = 'PromptTemplateGenerationsInvocable';
        input.isPreview = false;

        Map<String, ConnectApi.WrappedValue> params =
            new Map<String, ConnectApi.WrappedValue>();

        ConnectApi.WrappedValue questionVal = new ConnectApi.WrappedValue();
        questionVal.value = questionText;
        params.put('Input:Question', questionVal);

        ConnectApi.WrappedValue sectionVal = new ConnectApi.WrappedValue();
        sectionVal.value = sectionName;
        params.put('Input:PS_Section_Name', sectionVal);

        ConnectApi.WrappedValue cmdtVal = new ConnectApi.WrappedValue();
        cmdtVal.value = String.isNotBlank(cmdtContext) ? cmdtContext : '';
        params.put('Input:CMDTCapabilityContext', cmdtVal);

        input.inputParams = params;

        ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output =
            ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(TEMPLATE_NAME, input);

        return output.generations[0].text;
    }
}
