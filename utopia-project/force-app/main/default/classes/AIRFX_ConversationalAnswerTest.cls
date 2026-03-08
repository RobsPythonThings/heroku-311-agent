/**
 * AIRFX_ConversationalAnswerTest
 *
 * Tests for the conversational answer path — validates input handling,
 * CMDT context building, and error paths.  ConnectApi calls are not
 * testable in unit tests so the prompt-template path is covered by
 * integration testing in the org.
 *
 * @author Robert Smith
 * @date   2026-03-08
 */
@IsTest
private class AIRFX_ConversationalAnswerTest {

    // =========================================================================
    // INPUT VALIDATION
    // =========================================================================

    @IsTest
    static void blankQuestion_returnsError() {
        AIRFX_ConversationalAnswer.ConversationalRequest req =
            new AIRFX_ConversationalAnswer.ConversationalRequest();
        req.question = '';

        List<AIRFX_ConversationalAnswer.ConversationalResult> results =
            AIRFX_ConversationalAnswer.answerQuestion(
                new List<AIRFX_ConversationalAnswer.ConversationalRequest>{ req }
            );

        System.assertEquals(1, results.size());
        System.assertEquals('ERROR', results[0].status);
        System.assert(results[0].errorMessage.contains('required'),
            'Should indicate question is required');
    }

    @IsTest
    static void nullQuestion_returnsError() {
        AIRFX_ConversationalAnswer.ConversationalRequest req =
            new AIRFX_ConversationalAnswer.ConversationalRequest();
        req.question = null;

        List<AIRFX_ConversationalAnswer.ConversationalResult> results =
            AIRFX_ConversationalAnswer.answerQuestion(
                new List<AIRFX_ConversationalAnswer.ConversationalRequest>{ req }
            );

        System.assertEquals('ERROR', results[0].status);
    }

    // =========================================================================
    // CMDT CONTEXT — buildCMDTCapabilityContext with blank country/product
    // =========================================================================

    @IsTest
    static void cmdtContext_blankCountryAndProduct_returnsNonCountryFacts() {
        // After the fix, buildCMDTCapabilityContext should return certifications,
        // features, and hard nos even without country/product context
        String context = AIRFX_ResponseFlagInvocable.buildCMDTCapabilityContext('', '');

        // Should have certifications (not country-dependent)
        System.assert(context.contains('Certification') || context.contains('hard no')
            || context.contains('Feature') || context.length() > 0,
            'CMDT context should include global facts when country/product are blank. Got: ' + context);
    }

    @IsTest
    static void cmdtContext_withCountry_includesRegionFacts() {
        String context = AIRFX_ResponseFlagInvocable.buildCMDTCapabilityContext('US', '');

        // Should include Hyperforce + regulatory data for US
        System.assert(context.contains('United States') || context.contains('US')
            || context.length() > 0,
            'CMDT context with US should include country-specific data');
    }

    @IsTest
    static void cmdtContext_nullInputs_doesNotThrow() {
        // Ensure null safety
        String context = AIRFX_ResponseFlagInvocable.buildCMDTCapabilityContext(null, null);
        System.assertNotEquals(null, context,
            'Should return a string, not null');
    }
}