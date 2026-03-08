// =========================================================================
// AIRFX: Audit RED records — confirm each matches a Hard_No__mdt keyword
// =========================================================================

// Get all Hard_No keywords
List<Hard_No__mdt> hardNos = [
    SELECT Label__c, Reason__c
    FROM Hard_No__mdt
    WHERE Active__c = true
];

Set<String> hardNoLabels = new Set<String>();
for (Hard_No__mdt hn : hardNos) {
    hardNoLabels.add(hn.Label__c.toLowerCase());
}
System.debug('Hard_No__mdt labels: ' + hardNoLabels);

// Query all RED records
List<GPS_ResponseNew__c> redRecords = [
    SELECT Id, Question__c, Security_Flag__c, Response_Flag_Reason__c,
           GPS_Projects__c, GPS_Projects__r.Name
    FROM GPS_ResponseNew__c
    WHERE Security_Flag__c = 'Red'
    LIMIT 200
];

System.debug('Found ' + redRecords.size() + ' Red records.');

Integer matchedCount = 0;
Integer suspiciousCount = 0;

System.debug('');
System.debug('=== RED RECORD AUDIT ===');
System.debug('');

for (GPS_ResponseNew__c rec : redRecords) {
    String question = rec.Question__c != null ? rec.Question__c.toLowerCase() : '';
    String reason = rec.Response_Flag_Reason__c != null ? rec.Response_Flag_Reason__c.toLowerCase() : '';

    Boolean matchesHardNo = false;
    String matchedLabel = '';
    for (String label : hardNoLabels) {
        if (question.contains(label) || reason.contains(label)) {
            matchesHardNo = true;
            matchedLabel = label;
            break;
        }
    }

    if (matchesHardNo) {
        matchedCount++;
    } else {
        suspiciousCount++;
        System.debug('SUSPICIOUS RED: ' + rec.Id);
        System.debug('  Project:  ' + (rec.GPS_Projects__r != null ? rec.GPS_Projects__r.Name : 'N/A'));
        System.debug('  Question: ' + rec.Question__c);
        System.debug('  Reason:   ' + rec.Response_Flag_Reason__c);
        System.debug('');
    }
}

System.debug('=== AUDIT SUMMARY ===');
System.debug('Total Red records: ' + redRecords.size());
System.debug('Matched Hard_No: ' + matchedCount);
System.debug('Suspicious (no Hard_No match): ' + suspiciousCount);
System.debug('=== END AUDIT ===');
