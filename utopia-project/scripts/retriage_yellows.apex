// =========================================================================
// AIRFX: Re-triage stale YELLOW records that the improved engine might now flag GREEN
// =========================================================================

// Query Yellow records with existing answers
List<GPS_ResponseNew__c> yellowRecords = [
    SELECT Id, Question__c, Security_Flag__c, Response_Flag_Reason__c,
           GPS_Projects__c, GPS_Projects__r.Product_Type__c, GPS_Projects__r.Country__c
    FROM GPS_ResponseNew__c
    WHERE Security_Flag__c = 'Yellow'
    LIMIT 50
];

System.debug('Found ' + yellowRecords.size() + ' Yellow records with answers.');

if (yellowRecords.isEmpty()) {
    System.debug('No Yellow records found. Exiting.');
    return;
}

// Run the engine on each one individually to compare
List<AIRFX_ResponseFlagInvocable.FlagRequest> requests = new List<AIRFX_ResponseFlagInvocable.FlagRequest>();
for (GPS_ResponseNew__c rec : yellowRecords) {
    AIRFX_ResponseFlagInvocable.FlagRequest req = new AIRFX_ResponseFlagInvocable.FlagRequest();
    req.responseId = rec.Id;
    requests.add(req);
}

List<AIRFX_ResponseFlagInvocable.FlagResult> results =
    AIRFX_ResponseFlagInvocable.flagResponses(requests);

// Track changes
Integer upgradedCount = 0;
Integer unchangedCount = 0;

System.debug('');
System.debug('=== YELLOW RE-TRIAGE RESULTS ===');
System.debug('');

for (Integer i = 0; i < results.size(); i++) {
    AIRFX_ResponseFlagInvocable.FlagResult fr = results[i];
    GPS_ResponseNew__c orig = yellowRecords[i];

    String oldFlag = 'Yellow';
    String newFlag = fr.flag;

    if (newFlag == 'Green') {
        upgradedCount++;
        System.debug('UPGRADED: ' + fr.responseId);
        System.debug('  Question:   ' + orig.Question__c);
        System.debug('  Old Flag:   Yellow');
        System.debug('  New Flag:   Green');
        System.debug('  Rule ID:    ' + fr.ruleId);
        System.debug('  Confidence: ' + fr.confidenceScore);
        System.debug('  Reason:     ' + fr.reason);
        System.debug('');
    } else {
        unchangedCount++;
    }
}

System.debug('=== SUMMARY ===');
System.debug('Total Yellow records checked: ' + yellowRecords.size());
System.debug('Upgraded to Green: ' + upgradedCount);
System.debug('Remained Yellow: ' + unchangedCount);
System.debug('=== END RE-TRIAGE ===');
