@IsTest
private class AIRFX_KnowledgeHtmlStripBatchTest {

    // ─── stripHtml Unit Tests ───────────────────────────────────────────

    @IsTest
    static void testStripHtml_basicTags() {
        String input = '<p>Hello <strong>world</strong></p>';
        String result = AIRFX_KnowledgeHtmlStripBatch.stripHtml(input);
        System.assert(result.contains('Hello'), 'Should preserve text');
        System.assert(result.contains('world'), 'Should preserve bold text');
        System.assert(!result.contains('<'), 'Should strip all tags');
    }

    @IsTest
    static void testStripHtml_styleBlock() {
        String input = '<style>.foo { color: red; }\n.bar { font-size: 12px; }</style><p>Content</p>';
        String result = AIRFX_KnowledgeHtmlStripBatch.stripHtml(input);
        System.assert(!result.contains('color'), 'Should remove CSS');
        System.assert(!result.contains('font-size'), 'Should remove CSS properties');
        System.assert(result.contains('Content'), 'Should preserve content after style block');
    }

    @IsTest
    static void testStripHtml_multilineStyle() {
        String input = '<style type="text/css">\n  body {\n    margin: 0;\n  }\n</style>\n<div>After style</div>';
        String result = AIRFX_KnowledgeHtmlStripBatch.stripHtml(input);
        System.assert(!result.contains('margin'), 'Should strip multiline style');
        System.assert(result.contains('After style'), 'Should keep content');
    }

    @IsTest
    static void testStripHtml_scriptBlock() {
        String input = '<script>alert("xss")</script><p>Safe content</p>';
        String result = AIRFX_KnowledgeHtmlStripBatch.stripHtml(input);
        System.assert(!result.contains('alert'), 'Should remove script');
        System.assert(result.contains('Safe content'), 'Should preserve content');
    }

    @IsTest
    static void testStripHtml_htmlEntities() {
        String input = '<p>A &amp; B &lt; C &gt; D &quot;E&quot; F&#39;s</p>';
        String result = AIRFX_KnowledgeHtmlStripBatch.stripHtml(input);
        System.assert(result.contains('A & B'), 'Should decode &amp;');
        System.assert(result.contains('< C'), 'Should decode &lt;');
        System.assert(result.contains('> D'), 'Should decode &gt;');
        System.assert(result.contains('"E"'), 'Should decode &quot;');
        System.assert(result.contains('F\'s'), 'Should decode &#39;');
    }

    @IsTest
    static void testStripHtml_nbspHandling() {
        String input = '<p>Word&nbsp;word&nbsp;&nbsp;word</p>';
        String result = AIRFX_KnowledgeHtmlStripBatch.stripHtml(input);
        System.assert(result.contains('Word word word'), 'Should convert nbsp to space and collapse');
    }

    @IsTest
    static void testStripHtml_blockElements() {
        String input = '<h1>Title</h1><p>Paragraph 1</p><p>Paragraph 2</p>';
        String result = AIRFX_KnowledgeHtmlStripBatch.stripHtml(input);
        System.assert(result.contains('Title'), 'Should preserve h1 text');
        System.assert(result.contains('Paragraph 1'), 'Should preserve p text');
        System.assert(result.contains('\n'), 'Should have newlines between blocks');
    }

    @IsTest
    static void testStripHtml_listElements() {
        String input = '<ul><li>Item 1</li><li>Item 2</li><li>Item 3</li></ul>';
        String result = AIRFX_KnowledgeHtmlStripBatch.stripHtml(input);
        System.assert(result.contains('Item 1'), 'Should preserve list item text');
        System.assert(result.contains('Item 2'), 'Should preserve list item text');
        System.assert(result.contains('Item 3'), 'Should preserve list item text');
    }

    @IsTest
    static void testStripHtml_tableElements() {
        String input = '<table><tr><td>Cell 1</td><td>Cell 2</td></tr><tr><td>Cell 3</td><td>Cell 4</td></tr></table>';
        String result = AIRFX_KnowledgeHtmlStripBatch.stripHtml(input);
        System.assert(result.contains('Cell 1'), 'Should preserve table text');
        System.assert(result.contains('Cell 4'), 'Should preserve all cells');
    }

    @IsTest
    static void testStripHtml_htmlComments() {
        String input = '<!-- This is a comment --><p>Visible</p><!-- Another comment -->';
        String result = AIRFX_KnowledgeHtmlStripBatch.stripHtml(input);
        System.assert(!result.contains('comment'), 'Should remove HTML comments');
        System.assert(result.contains('Visible'), 'Should preserve visible content');
    }

    @IsTest
    static void testStripHtml_whitespaceNormalization() {
        String input = '<p>Too    many     spaces</p>\n\n\n\n\n<p>After gaps</p>';
        String result = AIRFX_KnowledgeHtmlStripBatch.stripHtml(input);
        System.assert(!result.contains('    '), 'Should collapse multiple spaces');
        System.assert(!result.contains('\n\n\n'), 'Should limit consecutive newlines');
    }

    @IsTest
    static void testStripHtml_brTags() {
        String input = 'Line 1<br>Line 2<br/>Line 3<br />Line 4';
        String result = AIRFX_KnowledgeHtmlStripBatch.stripHtml(input);
        System.assert(result.contains('Line 1'), 'Should preserve text around br');
        System.assert(result.contains('Line 4'), 'Should handle self-closing br');
    }

    @IsTest
    static void testStripHtml_specialEntities() {
        String input = '<p>&mdash; &ndash; &bull; &hellip; &trade; &reg; &copy;</p>';
        String result = AIRFX_KnowledgeHtmlStripBatch.stripHtml(input);
        System.assert(result.contains('—'), 'Should decode mdash');
        System.assert(result.contains('–'), 'Should decode ndash');
        System.assert(result.contains('•'), 'Should decode bull');
        System.assert(result.contains('...'), 'Should decode hellip');
        System.assert(result.contains('™'), 'Should decode trade');
    }

    @IsTest
    static void testStripHtml_nullInput() {
        System.assertEquals('', AIRFX_KnowledgeHtmlStripBatch.stripHtml(null), 'Null should return empty string');
    }

    @IsTest
    static void testStripHtml_emptyInput() {
        System.assertEquals('', AIRFX_KnowledgeHtmlStripBatch.stripHtml(''), 'Empty should return empty string');
    }

    @IsTest
    static void testStripHtml_blankInput() {
        System.assertEquals('', AIRFX_KnowledgeHtmlStripBatch.stripHtml('   \n  '), 'Blank should return empty string');
    }

    @IsTest
    static void testStripHtml_plainTextPassthrough() {
        String input = 'Just plain text with no HTML at all.';
        String result = AIRFX_KnowledgeHtmlStripBatch.stripHtml(input);
        System.assertEquals(input, result, 'Plain text should pass through unchanged');
    }

    @IsTest
    static void testStripHtml_nestedTags() {
        String input = '<div><p><span class="highlight"><strong><em>Deep</em></strong></span></p></div>';
        String result = AIRFX_KnowledgeHtmlStripBatch.stripHtml(input);
        System.assert(result.contains('Deep'), 'Should extract deeply nested text');
        System.assert(!result.contains('class'), 'Should remove attributes');
    }

    @IsTest
    static void testStripHtml_realWorldKnowledgePattern() {
        // Simulates typical Knowledge__kav Answer__c content
        String input = '<style>\n'
            + '.slds-table { border-collapse: collapse; }\n'
            + '.slds-table td { padding: 8px; }\n'
            + '</style>\n'
            + '<div class="slds-rich-text-editor__output">\n'
            + '<h2>Encryption at Rest</h2>\n'
            + '<p>Salesforce provides encryption at rest through Shield Platform Encryption. '
            + 'All data stored in the Salesforce platform is encrypted using AES-256 encryption.</p>\n'
            + '<ul>\n'
            + '<li>Tenant-level key management</li>\n'
            + '<li>BYOK (Bring Your Own Key) support</li>\n'
            + '<li>Key rotation without downtime</li>\n'
            + '</ul>\n'
            + '<p>For more information, see the <a href="https://trust.salesforce.com">Trust site</a>.</p>\n'
            + '</div>';

        String result = AIRFX_KnowledgeHtmlStripBatch.stripHtml(input);

        System.assert(!result.contains('slds-table'), 'Should strip CSS');
        System.assert(!result.contains('border-collapse'), 'Should strip CSS properties');
        System.assert(!result.contains('class='), 'Should strip attributes');
        System.assert(!result.contains('<'), 'Should have no tags');
        System.assert(result.contains('Encryption at Rest'), 'Should preserve heading text');
        System.assert(result.contains('AES-256'), 'Should preserve technical content');
        System.assert(result.contains('BYOK'), 'Should preserve list content');
        System.assert(result.contains('Trust site'), 'Should preserve link text');
    }

    @IsTest
    static void testStripHtml_numericEntities() {
        String input = '<p>Special: &#169; and &#x00A9;</p>';
        String result = AIRFX_KnowledgeHtmlStripBatch.stripHtml(input);
        System.assert(!result.contains('&#'), 'Should handle numeric entities');
        System.assert(result.contains('Special:'), 'Should preserve surrounding text');
    }

    // ─── Constructor Tests ──────────────────────────────────────────────

    @IsTest
    static void testDefaultConstructor() {
        AIRFX_KnowledgeHtmlStripBatch batch = new AIRFX_KnowledgeHtmlStripBatch();
        System.assertNotEquals(null, batch, 'Default constructor should work');
    }

    @IsTest
    static void testForceReprocessConstructor() {
        AIRFX_KnowledgeHtmlStripBatch batch = new AIRFX_KnowledgeHtmlStripBatch(true);
        System.assertNotEquals(null, batch, 'Force reprocess constructor should work');
    }

    // ─── Batch Execution Test ───────────────────────────────────────────
    // Note: Knowledge__kav creation in test context requires specific org config.
    // This test validates the batch framework runs without error.

    @IsTest
    static void testBatchExecution() {
        Test.startTest();
        AIRFX_KnowledgeHtmlStripBatch batch = new AIRFX_KnowledgeHtmlStripBatch();
        Id batchId = Database.executeBatch(batch, 50);
        Test.stopTest();

        System.assertNotEquals(null, batchId, 'Batch should start successfully');
    }

    @IsTest
    static void testBatchExecution_forceReprocess() {
        Test.startTest();
        AIRFX_KnowledgeHtmlStripBatch batch = new AIRFX_KnowledgeHtmlStripBatch(true);
        Id batchId = Database.executeBatch(batch, 50);
        Test.stopTest();

        System.assertNotEquals(null, batchId, 'Force reprocess batch should start');
    }
}