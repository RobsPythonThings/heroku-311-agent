/**
 * AIRFX_KnowledgeHtmlStripBatch
 * 
 * Strips HTML/CSS from Answer__c on Knowledge__kav and writes clean text
 * to Answer_Plain_Text__c for Data Cloud embedding.
 * 
 * Usage (Anonymous Apex):
 *   // Default — process all articles with Answer__c populated
 *   Database.executeBatch(new AIRFX_KnowledgeHtmlStripBatch(), 10);
 * 
 *   // Force re-process all (even if Answer_Plain_Text__c already populated)
 *   Database.executeBatch(new AIRFX_KnowledgeHtmlStripBatch(true), 10);
 * 
 * Uses KbManagement draft/update/publish cycle to edit published articles
 * without requiring "Allow users to edit published articles" setting.
 * 
 * Batch size 10 recommended — 3 DML ops per record (draft + update + publish).
 */
public class AIRFX_KnowledgeHtmlStripBatch implements Database.Batchable<SObject>, Database.Stateful {

    private Boolean forceReprocess;
    private Integer totalProcessed = 0;
    private Integer totalSkipped = 0;
    private Integer totalErrors = 0;
    private List<String> errorMessages = new List<String>();

    public AIRFX_KnowledgeHtmlStripBatch() {
        this(false);
    }

    public AIRFX_KnowledgeHtmlStripBatch(Boolean forceReprocess) {
        this.forceReprocess = forceReprocess;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // NOTE: Answer__c is LongTextArea — cannot filter in SOQL WHERE clause.
        // Null-check happens in execute() instead.
        String query = 'SELECT Id, KnowledgeArticleId, Answer__c, Answer_Plain_Text__c, PublishStatus '
                     + 'FROM Knowledge__kav '
                     + 'WHERE PublishStatus = \'Online\'';

        if (!forceReprocess) {
        }

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Knowledge__kav> scope) {
        List<Knowledge__kav> toUpdate = new List<Knowledge__kav>();

        for (Knowledge__kav article : scope) {
            try {
                // Answer__c is LongTextArea — can't filter in SOQL, check here
                if (String.isBlank(article.Answer__c)) {
                    totalSkipped++;
                    continue;
                }

                String plainText = stripHtml(article.Answer__c);

                // Skip if nothing meaningful after stripping
                if (String.isBlank(plainText)) {
                    totalSkipped++;
                    continue;
                }

                // Skip if unchanged (for re-process runs)
                if (!forceReprocess && plainText == article.Answer_Plain_Text__c) {
                    totalSkipped++;
                    continue;
                }

                article.Answer_Plain_Text__c = plainText;
                toUpdate.add(article);
            } catch (Exception e) {
                totalErrors++;
                errorMessages.add('Article ' + article.Id + ': ' + e.getMessage());
            }
        }

        // KbManagement: draft → update → republish (no UI setting required)
        for (Knowledge__kav article : toUpdate) {
            try {
                // 1. Create draft from published article (false = don't unpublish)
                String draftId = KbManagement.PublishingService.editOnlineArticle(
                    article.KnowledgeArticleId, false
                );
                // 2. Update the draft
                Knowledge__kav draft = new Knowledge__kav(
                    Id = draftId,
                    Answer_Plain_Text__c = article.Answer_Plain_Text__c
                );
                update draft;
                // 3. Republish
                KbManagement.PublishingService.publishArticle(
                    article.KnowledgeArticleId, true
                );
                totalProcessed++;
            } catch (Exception e) {
                totalErrors++;
                errorMessages.add('KbMgmt ' + article.Id + ': ' + e.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('=== AIRFX_KnowledgeHtmlStripBatch Complete ===');
        System.debug('Processed: ' + totalProcessed);
        System.debug('Skipped:   ' + totalSkipped);
        System.debug('Errors:    ' + totalErrors);
        if (!errorMessages.isEmpty()) {
            System.debug('Error details:');
            for (String msg : errorMessages) {
                System.debug('  → ' + msg);
            }
        }
    }

    // ─── HTML Stripping Logic ───────────────────────────────────────────

    /**
     * Strips HTML tags, CSS, scripts, and entities from rich text.
     * Preserves paragraph structure via newlines.
     */
    public static String stripHtml(String html) {
        if (String.isBlank(html)) {
            return '';
        }

        String result = html;

        // 1. Remove <style> blocks (including content across newlines)
        result = result.replaceAll('(?is)<style[^>]*>.*?</style>', '');

        // 2. Remove <script> blocks
        result = result.replaceAll('(?is)<script[^>]*>.*?</script>', '');

        // 3. Remove HTML comments
        result = result.replaceAll('(?s)<!--.*?-->', '');

        // 4. Convert block-level elements to newlines for readability
        result = result.replaceAll('(?i)<br\\s*/?>', '\n');
        result = result.replaceAll('(?i)</(p|div|li|tr|h[1-6]|blockquote|dd|dt)>', '\n');
        result = result.replaceAll('(?i)<(p|div|li|tr|h[1-6]|blockquote|dd|dt)[^>]*>', '\n');

        // 5. Remove <ul>, <ol>, <table>, <thead>, <tbody> wrappers (keep content)
        result = result.replaceAll('(?i)</?(?:ul|ol|table|thead|tbody|tfoot|th|td|caption|colgroup|col|dl)[^>]*>', '');

        // 6. Strip all remaining HTML tags
        result = result.replaceAll('<[^>]+>', '');

        // 7. Decode common HTML entities
        result = result.replace('&amp;', '&');
        result = result.replace('&lt;', '<');
        result = result.replace('&gt;', '>');
        result = result.replace('&quot;', '"');
        result = result.replace('&#39;', '\'');
        result = result.replace('&apos;', '\'');
        result = result.replace('&nbsp;', ' ');
        result = result.replace('&mdash;', '—');
        result = result.replace('&ndash;', '–');
        result = result.replace('&bull;', '•');
        result = result.replace('&hellip;', '...');
        result = result.replace('&trade;', '™');
        result = result.replace('&reg;', '®');
        result = result.replace('&copy;', '©');

        // 8. Decode numeric entities (&#123; and &#x1A;)
        result = result.replaceAll('&#(\\d+);', '');    // decimal — drop rather than risk bad chars
        result = result.replaceAll('&#x([0-9a-fA-F]+);', '');  // hex — same

        // 9. Normalize whitespace
        result = result.replaceAll('[ \\t]+', ' ');           // collapse horizontal space
        result = result.replaceAll(' ?\\n ?', '\n');           // trim space around newlines
        result = result.replaceAll('\\n{3,}', '\n\n');         // max 1 blank line
        result = result.trim();

        return result;
    }
}