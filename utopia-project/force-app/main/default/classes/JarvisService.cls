/**
 * @author      : Northbound Consulting (JCDJ)
 * @description : Service class to call Jarvis API.
 * @date        : 2025-01-17
 */
public with sharing class JarvisService {

    private static final String JARVIS_CONVERSATION_FIRST_ITEM = 'You are authoring a proposal as a response to an RFP/RFI. You are representing Salesforce.If the question is in a requirement or a statement format, find evidence to support the requirement or the statement. Otherwise, answer the question directly. Return only the response. Do not ask follow up questions or instructions. Do not thank the user. Do not answer this question in first person. Do not summarize the question in the response. Do not include any disclaimers. do not return "powered by Jarvis SME"';

    private static JarvisConfig config;
    static {
        // load Jarvis configuration
        config = new JarvisConfig();
    }


    // #region PUBLIC METHODS

    /**
     * @author      : JCDJ
     * @date        : 2025-01-21
     * @description : Makes a callout to the Javis API to get a response for the question provided. This is called from LWC.
     */
    @Auraenabled(cacheable=false)
    public static String getJarvisResponse(String jsonParams) {
        JarvisParams params = new JarvisParams((Map<String,Object>)JSON.deserializeUntyped(jsonParams));
        return getJarvisResponse(params);
    }

    /**
     * @author      : JCDJ
     * @date        : 2025-01-17
     * @description : Makes a callout to the Javis API to get a response for the conversation provided.
     */
    public static String getJarvisResponse(JarvisParams params) {

        // System.debug('getJarvisResponse.params = '+JSON.serializePretty(params));

        // build request
        HttpRequest request = buildJarvisRequest(config);
        request.setBody(buildPayload(config, params));
        // make callout
        System.debug(request.getBody());
        Http http = new Http();
        HttpResponse response = http.send(request);

        /*
        System.debug('getJarvisResponse.response.status = '+response.getStatus());
        System.debug('getJarvisResponse.response.statusCode = '+response.getStatusCode());
        System.debug('getJarvisResponse.response.body = '+response.getBody());
        */

        // check response
        Integer responseStatusCode = response.getStatusCode();
        if (responseStatusCode != 200) { return null; }
        String responseBody = response.getBody();
        if (String.isBlank(responseBody)) { return null; }

        // chunked response is received as json elements separated by \n and we have to pick the one with status = success
        List<String> responseBodyParts = responseBody.split('\n');
        if (responseBodyParts == null || responseBodyParts.isEmpty()) { return null; }
        for (String bodyPart : responseBodyParts) {
            JarvisResponse jarvisResp = (JarvisResponse)JSON.deserialize(bodyPart, JarvisResponse.class);
            if (jarvisResp.status == 'success') { return cleanResponse(jarvisResp.data.response, config.tokensToRemove); }
        }
        return null;
    }

    // #endregion

    // #region PRIVATE METHODS

    /**
     * @author      : JCDJ
     * @date        : 2025-01-17
     */
    private static HttpRequest buildJarvisRequest(JarvisConfig config) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(config.endpoint);
        request.setMethod('POST');
        request.setTimeout(120000);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('client_id', config.client_id);
        request.setHeader('client_secret', config.client_secret);
        request.setHeader('x-api-key', config.apiKey);
        return request;
    }

    /**
     * @author      : JCDJ
     * @date        : 2025-01-17
     * @change      : 2025-01-27 | JCDJ | If no sources are specified, add knowledge by default.
     */
    private static String buildPayload(JarvisConfig jarvisConfig, JarvisParams params) {
        JarvisRequestPayload payload = new JarvisRequestPayload();
        if (params.conversation != null && !params.conversation.isEmpty()) { payload.conversation = buildPayloadConversation(params.conversation); }
        if (params.sources != null && !params.sources.isEmpty()) { payload.sources = params.sources; }
        if (payload.sources.isEmpty()) { payload.sources.add('knowledge'); }
        if (params.maxResponseLength != null) { payload.maxResponseLength = params.maxResponseLength; }
        if (payload.maxResponseLength == null && jarvisConfig.maxResponseLength != null) { payload.maxResponseLength = jarvisConfig.maxResponseLength; }
        payload.genModel = String.isNotBlank(params.genModel) ?  params.genModel : jarvisConfig.genModel;
        return JSON.serialize(payload, true);
    }

    /**
     * @author      : JCDJ
     * @date        : 2025-01-23
     */
    private static List<ConversationItem> buildPayloadConversation(List<Object> conversationItems) {
        List<ConversationItem> conversation = new List<ConversationItem>();
        for (Object item : conversationItems) {
            String itemString = JSON.serialize(item);
            Map<String,Object> itemMap = (Map<String,Object>)JSON.deserializeUntyped(itemString);
            if (itemMap.containsKey('user')) { conversation.add((UserConversationItem)JSON.deserialize(itemString, UserConversationItem.class)); }
            if (itemMap.containsKey('jarvis_sme')) { conversation.add((JarvisConversationItem)JSON.deserialize(itemString, JarvisConversationItem.class)); }
        }
        return conversation;
    }

    /**
     * @author      : JCDJ
     * @date        : 2025-01-21
     * @change      : 2025-01-27 | JCDJ | Trim response before replacing tokens.
     */
    private static String cleanResponse(String response, List<String> tokensToRemove) {
        if (String.isBlank(response)) { return response; }
        if (tokensToRemove == null || tokensToRemove.isEmpty()) { return response.trim(); }
        response = response.trim();
        for (String token : tokensToRemove) {
            response = response.remove(token);
        }
        return response;
    }

    // #endregion

    // #region CLASSES

    /**
     * @author      : JCDJ
     * @date        : 2025-01-21
     */
    public abstract class ConversationItem {
    }

    /**
     * @author      : JCDJ
     * @date        : 2025-01-21
     */
    public class UserConversationItem extends ConversationItem {
        public String user;

        public UserConversationItem(String question) {
            this.user = question;
        }
    }

    /**
     * @author      : JCDJ
     * @date        : 2025-01-21
     */
    public class JarvisConversationItem extends ConversationItem {
        public String jarvis_sme;

        public JarvisConversationItem(String response) {
            this.jarvis_sme = response;
        }
    }

    /**
     * @author      : JCDJ
     * @date        : 2025-01-17
     */
    private class JarvisRequestPayload {
        public List<ConversationItem> conversation;
        public List<String> sources;
        public Integer maxResponseLength;
        public String genModel;

        public JarvisRequestPayload() {
            this.conversation = new List<ConversationItem>();
            this.sources = new List<String>();
        }
    }

    /**
     * @author      : JCDJ
     * @date        : 2025-01-17
     * @change      : 2025-01-27 | JCDJ | Split tokens by \\r\n instead of only \n.
     */
    private class JarvisConfig {
        public String apiKey;
        public String endpoint;
        public String client_id;
        public String client_secret;
        public Integer maxResponseLength;
        public String genModel;
        public List<String> tokensToRemove;

        public JarvisConfig() {
            String jarvisConfigJson = JarvisSMEUtil.getJarvisConfig();
            Map<String,Object> jarvisConfigMap = (Map<String, Object>)JSON.deserializeUntyped(jarvisConfigJson);
            this.apiKey = (String)jarvisConfigMap.get('api_key__c');
            this.client_id = (String)jarvisConfigMap.get('client_id__c');
            this.client_secret = (String)jarvisConfigMap.get('client_secret__c');
            this.endpoint = 'callout:jarvis_sme';
            this.maxResponseLength = (Integer)jarvisConfigMap.get('max_response_length__c');
            Map<String,Object> jarvisApiLlmGatewaysMap = (Map<String,Object>)jarvisConfigMap.get('Jarvis_API_LLM_Gateways__r');
            List<Object> jarvisApiLlmGateways = (List<Object>)jarvisApiLlmGatewaysMap.get('records');
            Map<String,Object> jarvisApiLlmGateway = (Map<String,Object>)jarvisApiLlmGateways[0];
            this.genModel = (String)jarvisApiLlmGateway.get('Value__c');
            String tokensToRemove = (String)jarvisConfigMap.get('Response_Removal_Tokens__c');
            this.tokensToRemove = String.isNotBlank(tokensToRemove) ? tokensToRemove.split('\\r\n') : new List<String>();
        }
    }

    /**
     * @author      : JCDJ
     * @date        : 2025-01-17
     */
    private class JarvisResponse {
        public String status;
        public String message;
        public ResponseData data;
    }

    /**
     * @author      : JCDJ
     * @date        : 2025-01-17
     */
    private class ResponseData {
        public String response;
    }

    /**
     * @author      : JCDJ
     * @date        : 2025-01-23
     * @change      : 2025-04-16 | JCDJ | W-000662 | Use of Integer.valueOf instead of implicit casting.
     */
    public class JarvisParams {
        public List<Object> conversation;
        public List<String> sources;
        public String genModel;
        public Integer maxResponseLength;

        public JarvisParams() {
            this.conversation = new List<Object>();
            this.sources = new List<String>();
        }

        public JarvisParams(Map<String,Object> paramsMap) {
            this.conversation = (List<Object>)paramsMap.get('conversation');
            this.genModel = (String)paramsMap.get('genModel');
            this.maxResponseLength = paramsMap.get('maxResponseLength') == null ? null : Integer.valueOf(paramsMap.get('maxResponseLength'));
            this.sources = new List<String>();
            List<Object> sources = paramsMap.get('sources') != null ? (List<Object>)paramsMap.get('sources') : new List<Object>();
            for (Object source : sources) {
                this.sources.add(String.valueOf(source));
            }
        }
    }

    // #endregion
}