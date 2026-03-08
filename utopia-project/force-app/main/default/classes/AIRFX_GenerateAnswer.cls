/**
 * AIRFX_GenerateAnswer
 * 
 * Agentforce action that generates a grounded RFP answer for a single question.
 * Takes a GPS_ResponseNew__c ID, resolves all template inputs automatically,
 * calls the DataCloud_RFP_Answer Prompt Builder template via ConnectApi,
 * writes the answer back to the record, and returns the answer text.
 * 
 * This wraps the proven ConnectApi call so the agent has a single clean action
 * instead of needing to figure out template inputs.
 * 
 * @author Robert Smith
 * @date 2026-02-26
 */
public with sharing class AIRFX_GenerateAnswer {

    public class AnswerRequest {
        @InvocableVariable(label='Response Record ID' 
                          description='The GPS_ResponseNew__c record to generate an answer for'
                          required=true)
        public String responseId;
        
        @InvocableVariable(label='Framework'
                          description='Compliance framework context (e.g. HECVAT, FedRAMP). Optional — defaults to HECVAT.'
                          required=false)
        public String framework;

        @InvocableVariable(label='CMDT Capability Context'
                          description='Plain-English capability summary from CMDT. Auto-populated by AIRFX engine if available.'
                          required=false)
        public String CMDTCapabilityContext;
    }
    
    public class AnswerResult {
        @InvocableVariable(label='Generated Answer' 
                          description='The AI-generated answer grounded in retrieved sources')
        public String answer;
        
        @InvocableVariable(label='Status' 
                          description='SUCCESS or ERROR')
        public String status;
        
        @InvocableVariable(label='Error Message' 
                          description='Error details if generation failed')
        public String errorMessage;
        
        @InvocableVariable(label='Sources Used' 
                          description='Which content lanes contributed to the answer')
        public String sourcesUsed;
    }
    
    private static final String TEMPLATE_NAME = 'DataCloud_RFP_Answer';
    
    @InvocableMethod(label='Generate RFP Answer' 
                     description='Generates a grounded AI answer for a single RFP question using triple-source retrieval. Pass a GPS_ResponseNew__c record ID.')
    public static List<AnswerResult> generateAnswer(List<AnswerRequest> requests) {
        List<AnswerResult> results = new List<AnswerResult>();
        
        for (AnswerRequest req : requests) {
            results.add(processRequest(req));
        }
        
        return results;
    }
    
    private static AnswerResult processRequest(AnswerRequest req) {
        AnswerResult result = new AnswerResult();
        
        try {
            // 1. Query the response record + parent project context
            GPS_ResponseNew__c response = [
                SELECT Id, Question__c, GPS_Projects__c,
                       GPS_Projects__r.Product_Type__c,
                       GPS_Projects__r.Country__c
                FROM GPS_ResponseNew__c
                WHERE Id = :req.responseId
                LIMIT 1
            ];
            
            if (String.isBlank(response.Question__c)) {
                result.status = 'ERROR';
                result.errorMessage = 'No question text found on record ' + req.responseId;
                return result;
            }
            
            // 2. Resolve section name via ContentRouter
            String framework = String.isNotBlank(req.framework) ? req.framework : 'HECVAT';
            String sectionName = resolveSectionName(response, framework);
            
            // 2b. Build CMDT context if not provided
            String cmdtContext = req.CMDTCapabilityContext;
            if (String.isBlank(cmdtContext)) {
                String country = response.GPS_Projects__r != null ? response.GPS_Projects__r.Country__c : '';
                String product = response.GPS_Projects__r != null ? response.GPS_Projects__r.Product_Type__c : '';
                cmdtContext = AIRFX_ResponseFlagInvocable.buildCMDTCapabilityContext(country, product);
            }

            // 3. Call ConnectApi to generate answer via Prompt Builder
            String generatedAnswer = callPromptTemplate(response.Question__c, sectionName, cmdtContext);
            
            // 4. Write answer back to the record
            GPS_ResponseNew__c toUpdate = new GPS_ResponseNew__c(
                Id = response.Id,
                AI_Generated_Answer__c = generatedAnswer
            );
            update toUpdate;
            
            // 5. Build result
            result.answer = generatedAnswer;
            result.status = 'SUCCESS';
            result.sourcesUsed = buildSourcesSummary(response, framework);
            
        } catch (QueryException qe) {
            result.status = 'ERROR';
            result.errorMessage = 'Record not found: ' + req.responseId;
        } catch (ConnectApi.ConnectApiException cae) {
            result.status = 'ERROR';
            result.errorMessage = 'Template generation failed: ' + cae.getMessage();
        } catch (Exception e) {
            result.status = 'ERROR';
            result.errorMessage = e.getTypeName() + ': ' + e.getMessage();
        }
        
        return result;
    }
    
    /**
     * Resolve the best section name for Knowledge retriever pre-filtering.
     * Uses ContentRouter which internally calls SectionMapper.
     */
    private static String resolveSectionName(GPS_ResponseNew__c response, String framework) {
        try {
            AIRFX_ContentRouter.RoutingRequest routeReq = new AIRFX_ContentRouter.RoutingRequest();
            routeReq.projectId = response.GPS_Projects__c;
            routeReq.framework = framework;
            
            List<AIRFX_ContentRouter.RoutingResult> routeResults = 
                AIRFX_ContentRouter.route(new List<AIRFX_ContentRouter.RoutingRequest>{ routeReq });
            
            if (!routeResults.isEmpty() && String.isNotBlank(routeResults[0].sectionName)) {
                // Return first section from semicolon-delimited list
                String sections = routeResults[0].sectionName;
                if (sections.contains(';')) {
                    return sections.split(';')[0].trim();
                }
                return sections.trim();
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'SectionMapper resolution failed, using default: ' + e.getMessage());
        }
        
        // Sensible default — largest section, covers most security/compliance questions
        return 'Section: Infrastructure and Security';
    }
    
    /**
     * Call ConnectApi to generate an answer via the DataCloud_RFP_Answer template.
     * Proven working from deployed Apex (Feb 26 evening).
     */
    private static String callPromptTemplate(String questionText, String sectionName, String cmdtContext) {
        ConnectApi.EinsteinPromptTemplateGenerationsInput input =
            new ConnectApi.EinsteinPromptTemplateGenerationsInput();

        input.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        input.additionalConfig.applicationName = 'PromptTemplateGenerationsInvocable';
        input.isPreview = false;

        Map<String, ConnectApi.WrappedValue> params =
            new Map<String, ConnectApi.WrappedValue>();

        // Question input
        ConnectApi.WrappedValue questionVal = new ConnectApi.WrappedValue();
        questionVal.value = questionText;
        params.put('Input:Question', questionVal);

        // Section name for Knowledge retriever pre-filter
        ConnectApi.WrappedValue sectionVal = new ConnectApi.WrappedValue();
        sectionVal.value = sectionName;
        params.put('Input:PS_Section_Name', sectionVal);

        // CMDT capability context for grounding
        ConnectApi.WrappedValue cmdtVal = new ConnectApi.WrappedValue();
        cmdtVal.value = String.isNotBlank(cmdtContext) ? cmdtContext : '';
        params.put('Input:CMDTCapabilityContext', cmdtVal);

        input.inputParams = params;
        
        ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output = 
            ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(TEMPLATE_NAME, input);
        
        return output.generations[0].text;
    }
    
    /**
     * Build a human-readable summary of which content lanes were used.
     */
    private static String buildSourcesSummary(GPS_ResponseNew__c response, String framework) {
        try {
            AIRFX_ContentRouter.RoutingRequest routeReq = new AIRFX_ContentRouter.RoutingRequest();
            routeReq.projectId = response.GPS_Projects__c;
            routeReq.framework = framework;
            
            List<AIRFX_ContentRouter.RoutingResult> routeResults = 
                AIRFX_ContentRouter.route(new List<AIRFX_ContentRouter.RoutingRequest>{ routeReq });
            
            if (!routeResults.isEmpty()) {
                AIRFX_ContentRouter.RoutingResult r = routeResults[0];
                List<String> lanes = new List<String>();
                if (r.useStructured) lanes.add('HECVAT (' + r.sourceConfigFilter + ')');
                if (r.useUnstructured) lanes.add('Security Documentation');
                return String.join(lanes, ', ');
            }
        } catch (Exception e) {
            // Non-critical, just return generic
        }
        return 'Knowledge Articles, HECVAT, Security Documentation';
    }
}