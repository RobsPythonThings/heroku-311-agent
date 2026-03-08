public with sharing class AIRFX_JarvisResponseEngine extends AIRFX_ResponseEngineBase {

    public override String getName() { return 'Jarvis'; }

    public override AIRFX_QuestionResponseModels.ResponseItem process(AIRFX_QuestionResponseModels.QuestionInput input) {
        AIRFX_QuestionResponseModels.ResponseItem ri = newItem(input);

        if (input == null || String.isBlank(input.question)) {
            return fail(ri, getName(), 'Question is blank.');
        }

        try {
            // Build effective system prompt
            String systemInstruction;
            if (input.promptOverride != null && String.isNotBlank(input.promptOverride)) {
                // Use the user-edited prompt as-is
                systemInstruction = input.promptOverride;
                if (input.products != null) {
                    //systemInstruction += ' Respond to the question with a focus on these products : ' + input.products;
                }
            } else {
                systemInstruction = 'You are authoring a proposal as a response to an RFP/RFI as a Salesforce representative. If the question is in a requirement or a statement format, find evidence to support the requirement or the statement. Otherwise, answer the question directly. Do not include any disclaimers. Do not return "*Powered by Jarvis SME*"';
                // Fallback default instructions
                /*systemInstruction =
                    'You are authoring a proposal as a response to an RFP/RFI. You are representing Salesforce.' +
                    'If the question is in a requirement or a statement format, find evidence to support the requirement or the statement. ' +
                    'Otherwise, answer the question directly. ' +
                    'Return only the response. Do not ask follow up questions or instructions. ' +
                    'Do not thank the user. Do not include any citations. Do not answer this question in first person. ' +
                    'Do not summarize the question in the response. DO not inclide anu disclaimers. do not return "powered by Jarvis SME"';*/
                if (input.products != null) {
                    //systemInstruction += ' Respond to the question with a focus on these products : ' + input.products;
                }
            }

            // Optionally include category context (this previously went into p.sources)
            if (String.isNotBlank(input.category)) {
                systemInstruction += ' Category: ' + input.category;
            }

            System.debug('systemInstruction: ' + systemInstruction);

            // Combine system instruction and user question into a single question string.
            // AskJarvis only accepts a list of questions (no separate system role),
            // so we embed the instructions into the question text.
            String effectiveQuestion = systemInstruction + ' Question: ' + input.question;
            System.debug('***************');
            System.debug(effectiveQuestion);

            // AskJarvis expects a List<String>; send a single composed question.
            List<String> responses = AskJarvis.ask(new List<String>{ effectiveQuestion });

            String answer;
            if (responses != null && !responses.isEmpty()) {
                answer = responses[0];
            } else {
                answer = null;
            }

            if (String.isBlank(answer)) {
                return fail(ri, getName(), 'No response returned by Jarvis.');
            }

            // AskJarvis.ask already converts Markdown to HTML, so just return the answer.
            return succeed(ri, getName(), answer);

        } catch (Exception e) {
            // Preserve original-style error messaging
            return fail(ri, getName(), 'Jarvis exception: ' + e.getMessage());
        }
    }
}