/**
 * AIRFX_CheckAnswerProgress
 * 
 * Agentforce action: checks how many Yellow-flagged questions have answers generated.
 * Lightweight read-only query — no DML, no callouts.
 */
public with sharing class AIRFX_CheckAnswerProgress {

    public class StatusRequest {
        @InvocableVariable(label='Project ID' description='GPS_Project__c record ID' required=true)
        public String projectId;
    }

    public class StatusResult {
        @InvocableVariable(label='Summary' description='Human-readable progress summary')
        public String summary;

        @InvocableVariable(label='Total Yellow' description='Total Yellow-flagged questions')
        public Integer totalYellow;

        @InvocableVariable(label='Answered' description='Yellow questions with answers generated')
        public Integer answered;

        @InvocableVariable(label='Remaining' description='Yellow questions still awaiting answers')
        public Integer remaining;

        @InvocableVariable(label='Estimated Minutes Left' description='Approximate minutes to completion')
        public Integer estimatedMinutesLeft;

        @InvocableVariable(label='Success' description='Whether the check completed successfully')
        public Boolean success;

        @InvocableVariable(label='Error Message' description='Error details if check failed')
        public String errorMessage;
    }

    @InvocableMethod(label='Utopia: Check Answer Progress'
                     description='Checks how many Yellow-flagged questions on a project have AI-generated answers. Read-only, no side effects.'
                     category='EYES / RFP Processing')
    public static List<StatusResult> checkProgress(List<StatusRequest> requests) {
        List<StatusResult> results = new List<StatusResult>();
        for (StatusRequest req : requests) {
            results.add(check(req));
        }
        return results;
    }

    private static StatusResult check(StatusRequest req) {
        StatusResult result = new StatusResult();

        try {
            List<GPS_Project__c> projects = [
                SELECT Id, Name FROM GPS_Project__c WHERE Id = :req.projectId LIMIT 1
            ];

            if (projects.isEmpty()) {
                result.success = false;
                result.errorMessage = 'Project not found: ' + req.projectId;
                return result;
            }

            String projectName = projects[0].Name;
            Integer totalYellow = 0;
            Integer answered = 0;

            for (GPS_ResponseNew__c r : [
                SELECT AI_Generated_Answer__c
                FROM GPS_ResponseNew__c
                WHERE GPS_Projects__c = :req.projectId
                  AND Security_Flag__c = 'Yellow'
            ]) {
                totalYellow++;
                if (r.AI_Generated_Answer__c != null) {
                    answered++;
                }
            }

            Integer remaining = totalYellow - answered;
            Integer estMinutes = (Integer)Math.ceil(remaining * 15.0 / 60.0);

            result.success = true;
            result.totalYellow = totalYellow;
            result.answered = answered;
            result.remaining = remaining;
            result.estimatedMinutesLeft = remaining > 0 ? estMinutes : 0;

            if (totalYellow == 0) {
                result.summary = '⚠️ No Yellow-flagged questions on project ' + projectName + '. Has the project been triaged?';
            } else if (remaining == 0) {
                result.summary = '🚀✅ Agentforce has answered all ' + answered + ' Yellow questions on project ' + projectName + '. Ready for review.';
            } else {
                result.summary = '🚀 Agentforce has answered ' + answered + ' of ' + totalYellow + ' Yellow questions answered on project ' + projectName + '. '
                    + remaining + ' remaining — approximately ' + estMinutes + ' minutes left.';
            }

        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
        }

        return result;
    }
}