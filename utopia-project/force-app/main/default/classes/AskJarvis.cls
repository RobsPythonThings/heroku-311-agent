public with sharing class AskJarvis {

    @InvocableMethod(label='ask' description='Ask Jarvis a question and get a response.' category='Jarvis')
    public static List<String> ask(List<String> questions) {

        String response = '';
        List<String> responses = new List<String>();

        if (questions.size() < 1) {

            Logger.error('ask() question count is less than 1');
            responses.add('Could not understand the question');
            return responses;
        }

        try {
            JarvisService.JarvisParams params = new JarvisService.JarvisParams();
            for (String question : questions) {
                params.conversation.add(new JarvisService.UserConversationItem(question));
            }
            response = JarvisService.getJarvisResponse(params);

            Logger.info('Ask Jarvis, question:\n' + questions[0] + '\n response:\n' + response);
            if (response == null) {
                response = '';
                Logger.error('Empty response received from Jarvis.');
                // Continue processing job even though Jarvis returned empty response
            }

        }
        catch (Exception e) {
            Logger.error('Ask Jarvis Error ' + e.getMessage());
            Logger.saveLog();
            throw e;
        }

        // Convert markdown to html by calling a prompt
        if (response.length() > 0) {
            try {
                // Jarvis returns Markdown but Salesforce Knowledge needs HTML.  Convert the markdown to HTML
                response = convertMarkdownToHTML(response);

            }
            catch (Exception e) {
                Logger.error('Error converting markdown to hmtl ' + e.getMessage());
                Logger.saveLog();
                throw e;
            }
        }

        responses.add(response);
        Logger.saveLog();
        return responses;

    }

    public static String convertMarkdownToHTML(String markdown) {

        final String promptTemplateName = 'PromptTemplateGenerationsInvocable';
        Logger.info('Converting ' + markdown + ' to html via ' + promptTemplateName + ' prompt');

        ConnectApi.EinsteinPromptTemplateGenerationsInput promptGenerationsInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
        promptGenerationsInput.isPreview = false;

        // Build input map
        Map<String,ConnectApi.WrappedValue> valueMap = new Map<String,ConnectApi.WrappedValue>();

        ConnectApi.WrappedValue markdownWrappedValue = new ConnectApi.WrappedValue();
        markdownWrappedValue.value = markdown;

        valueMap.put('Input:Markdown', markdownWrappedValue);

        promptGenerationsInput.inputParams = valueMap;

        // Set additional configuration values
        promptGenerationsInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        promptGenerationsInput.additionalConfig.applicationName = promptTemplateName;

        try {
            // Call the service using the prompt template ID
            String convertedHtml;
            if(!Test.isRunningTest()){
                ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generationsOutput = ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('ConvertMarkdownToHTML', promptGenerationsInput);
                convertedHtml = generationsOutput.generations[0].text;
            }else{
                convertedHtml = '<h1>Heading</h1>';
            }

            // Google LLM adds Markdown for html tag for some unknown reason.  Remove this
            convertedHtml = convertedHtml.replace('```html','');
                convertedHtml = convertedHtml.replace('<em>Disclaimer</em>: <em>Generative AI can produce inaccurate or harmful responses. Review the output for accuracy and safety. You assume responsibility for how the outcomes of Einstein are applied to your organization.</em>','');
				convertedHtml = convertedHtml.replace('<em>Disclaimer</em>: <em>Generative AI may produce inaccurate or harmful responses. Review the output for accuracy and safety. You assume responsibility for how the outcomes of Einstein are applied to your organization.</em>','');            
				convertedHtml = convertedHtml.replace('<em>Disclaimer: Generative AI can produce inaccurate or harmful responses. Review the output for accuracy and safety. You assume responsibility for how the outcomes of Einstein are applied to your organization.</em>','');                        
                convertedHtml = convertedHtml.replace('*Disclaimer*: *Generative AI can produce inaccurate or harmful responses. Review the output for accuracy and safety. You assume responsibility for how the outcomes of Einstein are applied to your organization.*','');            
                convertedHtml = convertedHtml.replace('*Disclaimer*: *Generative AI may produce inaccurate or harmful responses. Review the output for accuracy and safety. You assume responsibility for how the outcomes of Einstein are applied to your organization.*','');            
                convertedHtml = convertedHtml.replace('\\*Disclaimer\\*: \\*Generative AI can produce inaccurate or harmful responses. Review the output for accuracy and safety. You assume responsibility for how the outcomes of Einstein are applied to your organization.\\*','');            
                convertedHtml = convertedHtml.replace('\\*Disclaimer\\*: \\*Generative AI may produce inaccurate or harmful responses. Review the output for accuracy and safety. You assume responsibility for how the outcomes of Einstein are applied to your organization.\\*','');                        
                convertedHtml = convertedHtml.replace('<em>Disclaimer</em>: <em>Generative AI can produce inaccurate or harmful responses.</em></p><p><em>Review the output for accuracy and safety.</em></p><p><em>You assume responsibility for how the outcomes of Einstein are applied to your organization.</em>','');                        
                convertedHtml = convertedHtml.replace('<em>Disclaimer</em>: <em>Generative AI may produce inaccurate or harmful responses.</em></p><p><em>Review the output for accuracy and safety.</em></p><p><em>You assume responsibility for how the outcomes of Einstein are applied to your organization.</em>','');                        
            	convertedHtml = convertedHtml.replace('\\*Powered by Jarvis SME\\*',''); 
            	convertedHtml = convertedHtml.replace('<em>Powered by Jarvis SME</em>','');
                convertedHtml = convertedHtml.replace('*Powered by Jarvis SME*',''); 
            	convertedHtml = convertedHtml.replace('*Powered by Jarvis SME*',''); 
            convertedHtml = convertedHtml.replace('```','');

            Logger.info('Converted HTML response: ' + convertedHtml);
            Logger.saveLog();

            return convertedHtml;
        }
        catch (Exception e) {
            Logger.error('Could not convert ' + markdown + ' to HTML.  ' + e.getMessage());
            Logger.saveLog();
            throw e;
        }
    }
}