public with sharing class AIRFX_RfpQuestionClassifierService {

    private static final String TEMPLATE_NAME = 'RFP_Question_Classifier';

    public class ClassificationResult {
        public String securityScope;
        public String primaryDomain;
        public String countryOrRegion;
        public Decimal confidence;
        public String rawResponse;
    }

    public static ClassificationResult classify(String question, String product, String country) {
        ClassificationResult result = new ClassificationResult();

        if (String.isBlank(question)) {
            result.securityScope = 'AMBIGUOUS';
            result.primaryDomain = 'other';
            result.countryOrRegion = null;
            result.confidence = 0;
            result.rawResponse = null;
            return result;
        }

        try {
            String raw = callPromptTemplate(question, product, country);
            result.rawResponse = raw;

            String cleaned = sanitizeJson(raw);

            Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(cleaned);

            result.securityScope = parsed.containsKey('security_scope')
                ? String.valueOf(parsed.get('security_scope'))
                : 'AMBIGUOUS';

            result.primaryDomain = parsed.containsKey('primary_domain')
                ? String.valueOf(parsed.get('primary_domain'))
                : 'other';

            Object cor = parsed.get('country_or_region');
            result.countryOrRegion = cor == null ? null : String.valueOf(cor);

            Object conf = parsed.get('confidence');
            if (conf != null) {
                try {
                    result.confidence = Decimal.valueOf(String.valueOf(conf));
                } catch (Exception e) {
                    result.confidence = 0;
                }
            } else {
                result.confidence = 0;
            }

            if (String.isBlank(result.securityScope)) {
                result.securityScope = 'AMBIGUOUS';
            }
            if (String.isBlank(result.primaryDomain)) {
                result.primaryDomain = 'other';
            }

            return result;

        } catch (Exception e) {
            result.securityScope = 'AMBIGUOUS';
            result.primaryDomain = 'other';
            result.countryOrRegion = null;
            result.confidence = 0;
            result.rawResponse = 'CLASSIFIER_ERROR: ' + e.getMessage() + ' | RAW=' + result.rawResponse;
            return result;
        }
    }

    private static String callPromptTemplate(String question, String product, String country) {
        ConnectApi.EinsteinPromptTemplateGenerationsInput input =
            new ConnectApi.EinsteinPromptTemplateGenerationsInput();

        input.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        input.additionalConfig.applicationName = 'PromptTemplateGenerationsInvocable';
        input.isPreview = false;

        Map<String, ConnectApi.WrappedValue> params =
            new Map<String, ConnectApi.WrappedValue>();

        ConnectApi.WrappedValue questionVal = new ConnectApi.WrappedValue();
        questionVal.value = question;
        params.put('Input:question', questionVal);

        if (String.isNotBlank(product)) {
            ConnectApi.WrappedValue productVal = new ConnectApi.WrappedValue();
            productVal.value = product;
            params.put('Input:product', productVal);
        }

        if (String.isNotBlank(country)) {
            ConnectApi.WrappedValue countryVal = new ConnectApi.WrappedValue();
            countryVal.value = country;
            params.put('Input:country', countryVal);
        }

        input.inputParams = params;

        ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output =
            ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(TEMPLATE_NAME, input);

        if (output == null || output.generations == null || output.generations.isEmpty()) {
            throw new AuraHandledException('No generations returned from classifier prompt template.');
        }

        return output.generations[0].text;
    }

    @TestVisible
    private static String sanitizeJson(String raw) {
        if (String.isBlank(raw)) {
            return '{}';
        }

        String cleaned = raw;

        // Replace non-breaking spaces and trim junk
        cleaned = cleaned.replace('\u00A0', ' ');
        cleaned = cleaned.replace('\n', ' ');
        cleaned = cleaned.replace('\r', ' ');
        cleaned = cleaned.trim();

        // Strip markdown fences if present
        cleaned = cleaned.replace('```json', '');
        cleaned = cleaned.replace('```', '');
        cleaned = cleaned.trim();

        // Extract only the JSON object if extra text exists
        Integer firstBrace = cleaned.indexOf('{');
        Integer lastBrace = cleaned.lastIndexOf('}');
        if (firstBrace >= 0 && lastBrace > firstBrace) {
            cleaned = cleaned.substring(firstBrace, lastBrace + 1);
        }

        return cleaned.trim();
    }
}