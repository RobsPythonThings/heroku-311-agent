// =========================================================================
// AIRFX Confidence Score — End-to-End Validation Script
// Creates temporary response records under existing projects, runs engine, logs results.
// =========================================================================

List<String> questions = new List<String>{
    'Can Salesforce provide dedicated hardware for our deployment?',
    'Does Salesforce support patch management processes?',
    'What is your approach to supplier diversity programs?',
    'Is Salesforce ISMAP certified for Japanese government?'
};
List<String> expectedFlags = new List<String>{'Red', 'Yellow', 'Green', 'Green'};

// Use existing projects: P-6396 (US), P-6399 (JP)
Id projUS = 'a1S7x000006jPzhEAE';
Id projJP = 'a1S7x000006l4kfEAA';
List<Id> projIds = new List<Id>{ projUS, projUS, projUS, projJP };

Savepoint sp = Database.setSavepoint();

try {
    // Create response records under existing projects
    List<GPS_ResponseNew__c> testResponses = new List<GPS_ResponseNew__c>();
    for (Integer i = 0; i < questions.size(); i++) {
        GPS_ResponseNew__c resp = new GPS_ResponseNew__c(
            Question__c = questions[i],
            GPS_Projects__c = projIds[i]
        );
        testResponses.add(resp);
    }
    insert testResponses;

    // Run the engine
    List<AIRFX_ResponseFlagInvocable.FlagRequest> requests = new List<AIRFX_ResponseFlagInvocable.FlagRequest>();
    for (GPS_ResponseNew__c resp : testResponses) {
        AIRFX_ResponseFlagInvocable.FlagRequest req = new AIRFX_ResponseFlagInvocable.FlagRequest();
        req.responseId = resp.Id;
        requests.add(req);
    }

    List<AIRFX_ResponseFlagInvocable.FlagResult> results =
        AIRFX_ResponseFlagInvocable.flagResponses(requests);

    // Query updated records with dynamic SOQL
    Set<Id> respIds = new Set<Id>();
    for (GPS_ResponseNew__c r : testResponses) { respIds.add(r.Id); }
    String soql = 'SELECT Id, Question__c, Security_Flag__c, Response_Flag_Reason__c, '
        + 'Question_Classification__c FROM GPS_ResponseNew__c WHERE Id IN :respIds';

    // Try including Confidence_Score__c
    Boolean hasConfField = false;
    try {
        List<SObject> test = Database.query(
            'SELECT Id, Confidence_Score__c FROM GPS_ResponseNew__c WHERE Id IN :respIds'
        );
        hasConfField = true;
        soql = 'SELECT Id, Question__c, Security_Flag__c, Response_Flag_Reason__c, '
            + 'Confidence_Score__c, Question_Classification__c FROM GPS_ResponseNew__c WHERE Id IN :respIds';
    } catch (Exception e) {
        System.debug('Confidence_Score__c not available in runtime: ' + e.getMessage());
    }

    Map<Id, GPS_ResponseNew__c> updatedRecords = new Map<Id, GPS_ResponseNew__c>(
        (List<GPS_ResponseNew__c>) Database.query(soql)
    );

    System.debug('');
    System.debug('=== AIRFX CONFIDENCE SCORE E2E TEST RESULTS ===');
    System.debug('');

    for (Integer i = 0; i < results.size(); i++) {
        AIRFX_ResponseFlagInvocable.FlagResult fr = results[i];
        GPS_ResponseNew__c rec = updatedRecords.get(fr.responseId);

        String cmdtCtxLen = (fr.CMDTCapabilityContext != null)
            ? String.valueOf(fr.CMDTCapabilityContext.length()) : '0';

        Object dbScore = null;
        if (hasConfField) {
            try { dbScore = rec.get('Confidence_Score__c'); } catch (Exception e) {}
        }

        System.debug('--- Q' + (i + 1) + ' ---');
        System.debug('Question:         ' + questions[i]);
        System.debug('Expected Flag:    ' + expectedFlags[i]);
        System.debug('Actual Flag:      ' + fr.flag);
        System.debug('Rule ID:          ' + fr.ruleId);
        System.debug('Confidence Score: ' + fr.confidenceScore);
        System.debug('DB Conf Score:    ' + dbScore);
        System.debug('CMDT Ctx Length:  ' + cmdtCtxLen);
        System.debug('Reason:           ' + fr.reason);
        System.debug('Success:          ' + fr.success);

        String status = (fr.flag == expectedFlags[i]) ? 'PASS' : 'FAIL';
        System.debug('Flag Match:       ' + status);
        System.debug('');
    }

    System.debug('=== END E2E TEST ===');

} finally {
    Database.rollback(sp);
    System.debug('Rolled back all test records.');
}
