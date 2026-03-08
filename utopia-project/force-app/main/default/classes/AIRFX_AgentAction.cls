public with sharing class AIRFX_AgentAction {

    public class TriageRequest {
        @InvocableVariable(label='Project ID' required=true description='GPS_Project__c record ID or project name like P-0014')
        public String projectId;
        @InvocableVariable(label='Framework' required=false description='Compliance framework: FedRAMP, HECVAT, CMMC, StateRAMP')
        public String framework;
    }

    public class TriageResult {
        @InvocableVariable(label='Summary') public String summary;
        public Boolean success; // internal only, not exposed to agent
        @InvocableVariable(label='Error Message') public String errorMessage;
    }

    @InvocableMethod(label='Utopia: Triage and Route Project'
                     description='Flags all RFP questions (Red/Yellow/Green) and resolves content routing based on deal context.'
                     category='EYES / RFP Processing')
    public static List<TriageResult> triageProject(List<TriageRequest> requests) {
        List<TriageResult> results = new List<TriageResult>();
        if (requests == null || requests.isEmpty()) {
            TriageResult empty = new TriageResult();
            empty.success = false;
            empty.errorMessage = 'No requests provided.';
            results.add(empty);
            return results;
        }
        for (TriageRequest req : requests) {
            results.add(processOne(req));
        }
        return results;
    }

    @TestVisible
    private static TriageResult processOne(TriageRequest req) {
        TriageResult result = new TriageResult();

        // ── Resolve project name or ID ──
        Id resolvedId;
        if (String.isNotBlank(req.projectId)) {
            try {
                resolvedId = Id.valueOf(req.projectId.trim());
            } catch (Exception e) {
                String search = req.projectId.trim().startsWith('P-')
                    ? req.projectId.trim()
                    : 'P-' + req.projectId.trim();
                List<GPS_Project__c> matches = [
                    SELECT Id FROM GPS_Project__c WHERE Name = :search LIMIT 1
                ];
                if (!matches.isEmpty()) { resolvedId = matches[0].Id; }
            }
        }
        if (resolvedId == null) {
            result.success = false;
            result.errorMessage = 'Could not find project. Provide a valid Salesforce ID or project name like P-0014.';
            return result;
        }

        try {
            // ── Get project context ──
            GPS_Project__c project = [
                SELECT Id, Name, Product_Type__c, Country__c
                FROM GPS_Project__c WHERE Id = :resolvedId LIMIT 1
            ];

            // ── Flag all questions ──
            AIRFX_ResponseFlagInvocable.FlagRequest flagReq = new AIRFX_ResponseFlagInvocable.FlagRequest();
            flagReq.projectId = resolvedId;
            AIRFX_ResponseFlagInvocable.flagResponses(
                new List<AIRFX_ResponseFlagInvocable.FlagRequest>{ flagReq }
            );

            // ── Route content sources ──
            AIRFX_ContentRouter.RoutingRequest routeReq = new AIRFX_ContentRouter.RoutingRequest();
            routeReq.projectId = resolvedId;
            routeReq.framework = req.framework;
            List<AIRFX_ContentRouter.RoutingResult> routeResults =
                AIRFX_ContentRouter.route(
                    new List<AIRFX_ContentRouter.RoutingRequest>{ routeReq }
                );

            // ── Count flags ──
            Map<String, Integer> flagCounts = countFlags(resolvedId);
            Integer redCount   = flagCounts.containsKey('Red')    ? flagCounts.get('Red')    : 0;
            Integer greenCount = flagCounts.containsKey('Green')  ? flagCounts.get('Green')  : 0;
            Integer yellowCount= flagCounts.containsKey('Yellow') ? flagCounts.get('Yellow') : 0;
            Integer unflagged  = flagCounts.containsKey(null)     ? flagCounts.get(null)     : 0;
            Integer total = 0;
            for (Integer ct : flagCounts.values()) { total += ct; }

            // ── Get routing info ──
            String matchedConfigs = '';
            String sourceFilter = '';
            List<String> lanes = new List<String>();
            if (!routeResults.isEmpty()) {
                AIRFX_ContentRouter.RoutingResult routing = routeResults[0];
                matchedConfigs = routing.matchedConfigs != null ? routing.matchedConfigs : '';
                sourceFilter = routing.sourceConfigFilter != null ? routing.sourceConfigFilter : '';
                if (routing.useStructured == true)   lanes.add('HECVAT Assessments');
                if (routing.useUnstructured == true)  lanes.add('Whitepapers');
            }

            // ── Build formatted summary ──
            result.summary = buildSummary(
                project, total, redCount, greenCount, yellowCount, unflagged,
                lanes, matchedConfigs, sourceFilter, resolvedId
            );
            result.success = true;

        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Triage failed: ' + e.getMessage();
        }
        return result;
    }

    @TestVisible
    private static Map<String, Integer> countFlags(Id projectId) {
        Map<String, Integer> counts = new Map<String, Integer>();
        for (AggregateResult ar : [
            SELECT Security_Flag__c flag, COUNT(Id) ct
            FROM GPS_ResponseNew__c
            WHERE GPS_Projects__c = :projectId
            GROUP BY Security_Flag__c
        ]) {
            counts.put((String) ar.get('flag'), (Integer) ar.get('ct'));
        }
        return counts;
    }

    @TestVisible
    private static String buildSummary(
        GPS_Project__c project, Integer total, Integer redCount, Integer greenCount,
        Integer yellowCount, Integer unflagged, List<String> lanes,
        String matchedConfigs, String sourceFilter, Id projectId
    ) {
        List<String> lines = new List<String>();

        // Header with project context
        String productDisplay = project.Product_Type__c != null
            ? project.Product_Type__c.replace(';', ' / ')
            : 'Unknown';
        String countryDisplay = project.Country__c != null ? project.Country__c : '—';

        if (total == 0) {
            lines.add('📊 Project ' + project.Name + ' (' + productDisplay + ' / ' + countryDisplay + ') — No questions loaded yet. Upload RFP requirements before triaging.');
            return String.join(lines, '\n');
        }

        lines.add('The project has been triaged. Let me know if you\'d like to generate answers for the Yellow questions.');
        lines.add('📊 Project ' + project.Name + ' (' + productDisplay + ' / ' + countryDisplay + ') — ' + total + ' questions triaged');
        lines.add('');

        // Flag breakdown — counts only, details on request
        lines.add('🔴 Red (cannot meet): ' + redCount);
        lines.add('🟢 Green (auto-verified): ' + greenCount);
        lines.add('🟡 Yellow (security — need AI answers): ' + yellowCount);
        if (unflagged > 0) {
            lines.add('Unflagged: ' + unflagged);
        }

        // Content sources
        if (!lanes.isEmpty()) {
            lines.add('');
            lines.add('📡 Content sources: ' + String.join(lanes, ', '));
            if (String.isNotBlank(sourceFilter)) {
                lines.add('HECVAT filter: ' + sourceFilter.replace('_', ' '));
            }
        }

        lines.add('');
        lines.add('I can explain any flag, answer Yellow questions, or pull supporting citations — just ask.');

        return String.join(lines, '\n');
    }
}