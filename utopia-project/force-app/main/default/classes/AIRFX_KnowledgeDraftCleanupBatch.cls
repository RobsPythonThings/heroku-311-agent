public class AIRFX_KnowledgeDraftCleanupBatch implements Database.Batchable<SObject>, Database.Stateful {
    private Integer totalUpdated = 0;
    private Integer totalSkipped = 0;
    private Integer totalErrors = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Answer__c, Answer_Plain_Text__c FROM Knowledge__kav WHERE PublishStatus = \'Draft\''
        );
    }

    public void execute(Database.BatchableContext bc, List<Knowledge__kav> scope) {
        List<SObject> toUpdate = new List<SObject>();
        for (Knowledge__kav draft : scope) {
            if (String.isBlank(draft.Answer__c)) { totalSkipped++; continue; }
            String plain = AIRFX_KnowledgeHtmlStripBatch.stripHtml(draft.Answer__c);
            if (String.isBlank(plain)) { totalSkipped++; continue; }
            if (plain == draft.Answer_Plain_Text__c) { totalSkipped++; continue; }
            SObject d = new Knowledge__kav(Id = draft.Id);
            d.put('Answer_Plain_Text__c', plain);
            toUpdate.add(d);
        }
        if (!toUpdate.isEmpty()) {
            List<Database.SaveResult> results = Database.update(toUpdate, false);
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) { totalUpdated++; }
                else { totalErrors++; System.debug('ERROR: ' + sr.getErrors()[0].getMessage()); }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('=== Draft Cleanup Complete ===');
        System.debug('Updated: ' + totalUpdated + ' | Skipped: ' + totalSkipped + ' | Errors: ' + totalErrors);
    }
}