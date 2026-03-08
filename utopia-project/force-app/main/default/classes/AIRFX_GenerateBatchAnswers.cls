/**
 * AIRFX_GenerateBatchAnswers
 * 
 * Agentforce action: generates grounded answers for ALL Yellow-flagged questions
 * on a GPS_Project__c. Delegates to AIRFX_GenerateAnswer per record via Queueable chain.
 *
 * Agent says "Answer all the yellow questions" → this action:
 *   1. Queries GPS_ResponseNew__c WHERE Security_Flag__c = 'Yellow'
 *   2. Kicks off a Queueable chain (each job processes one question)
 *   3. Returns immediately with count so agent can report progress
 *
 * Why Queueable: Each ConnectApi call takes ~14s wall clock. 88 questions synchronously = 20+ min.
 * Queueable chain processes 1 per job, each chains to next. Platform handles the queue.
 */
public with sharing class AIRFX_GenerateBatchAnswers {

    // ─── Invocable interface ───────────────────────────────────────────

    public class BatchRequest {
        @InvocableVariable(label='Project ID' description='GPS_Project__c record ID' required=true)
        public String projectId;

        @InvocableVariable(label='Framework' description='Optional compliance framework override (HECVAT, FedRAMP, etc.)')
        public String framework;
    }

    public class BatchResult {
        @InvocableVariable(label='Summary' description='Human-readable batch summary')
        public String summary;

        @InvocableVariable(label='Total Queued' description='Number of Yellow questions queued for answer generation')
        public Integer totalQueued;

        @InvocableVariable(label='Success' description='Whether batch was successfully started')
        public Boolean success;

        @InvocableVariable(label='Error Message' description='Error details if batch failed to start')
        public String errorMessage;

        @InvocableVariable(label='Job ID' description='AsyncApexJob ID for tracking progress')
        public String jobId;
    }

    @InvocableMethod(label='Utopia: Answer All Yellow Questions'
                     description='Generates grounded AI answers for all Yellow-flagged questions on a GPS Project. Runs asynchronously via Queueable chain.'
                     category='EYES / RFP Processing')
    public static List<BatchResult> generateBatchAnswers(List<BatchRequest> requests) {
        List<BatchResult> results = new List<BatchResult>();

        for (BatchRequest req : requests) {
            results.add(processBatch(req));
        }

        return results;
    }

    @TestVisible
    private static BatchResult processBatch(BatchRequest req) {
        BatchResult result = new BatchResult();

        try {
            // Validate project exists
            List<GPS_Project__c> projects = [
                SELECT Id, Name, Product_Type__c, Country__c
                FROM GPS_Project__c
                WHERE Id = :req.projectId
                LIMIT 1
            ];

            if (projects.isEmpty()) {
                result.success = false;
                result.errorMessage = 'Project not found: ' + req.projectId;
                result.totalQueued = 0;
                result.summary = '❌ Error: Project not found.';
                return result;
            }

            GPS_Project__c project = projects[0];

            // Query all Yellow-flagged questions on this project
            List<GPS_ResponseNew__c> yellowQuestions = [
                SELECT Id, Name, Question__c
                FROM GPS_ResponseNew__c
                WHERE GPS_Projects__c = :req.projectId
                  AND Security_Flag__c = 'Yellow'
                ORDER BY Name ASC
            ];

            if (yellowQuestions.isEmpty()) {
                result.success = true;
                result.totalQueued = 0;
                result.summary = '⚠️ No Yellow-flagged questions found on project ' + project.Name + '. '
                    + 'Either the project has not been triaged yet, or all questions are already flagged Red or Green.';
                return result;
            }

            // Collect record IDs for the Queueable chain
            List<Id> responseIds = new List<Id>();
            for (GPS_ResponseNew__c q : yellowQuestions) {
                responseIds.add(q.Id);
            }

            // Kick off the Queueable chain — first job processes record 0, then chains
            AnswerQueueable job = new AnswerQueueable(responseIds, 0);
            Id jobId = System.enqueueJob(job);

            result.success = true;
            result.totalQueued = responseIds.size();
            result.jobId = String.valueOf(jobId);
            result.summary = '🚀 Agentforce is generating answers for ' + responseIds.size()
                + ' Yellow-flagged questions on project ' + project.Name
                + ' (' + project.Product_Type__c + '). '
                + 'Answers are being generated asynchronously — each takes approximately 15 seconds. '
                + 'Total estimated time: ' + formatDuration(responseIds.size() * 15) + '. '
                + 'Answers will be written directly to the AI_Generated_Answer__c field on each record.';

        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
            result.totalQueued = 0;
            result.summary = '❌ Error starting batch: ' + e.getMessage();
        }

        return result;
    }

    // ─── Queueable chain ──────────────────────────────────────────────

    public class AnswerQueueable implements Queueable, Database.AllowsCallouts {

        private List<Id> responseIds;
        private Integer currentIndex;

        public AnswerQueueable(List<Id> responseIds, Integer currentIndex) {
            this.responseIds = responseIds;
            this.currentIndex = currentIndex;
        }

        public void execute(QueueableContext context) {
            if (currentIndex >= responseIds.size()) {
                return; // All done
            }

            Id currentId = responseIds[currentIndex];

            try {
                // Reuse the existing single-answer generator
                AIRFX_GenerateAnswer.AnswerRequest req = new AIRFX_GenerateAnswer.AnswerRequest();
                req.responseId = String.valueOf(currentId);

                List<AIRFX_GenerateAnswer.AnswerResult> results =
                    AIRFX_GenerateAnswer.generateAnswer(new List<AIRFX_GenerateAnswer.AnswerRequest>{ req });

                // Log result for debugging (visible in Apex Jobs)
                if (results != null && !results.isEmpty()) {
                    AIRFX_GenerateAnswer.AnswerResult ar = results[0];
                    System.debug('=== BATCH [' + (currentIndex + 1) + '/' + responseIds.size() + '] ===');
                    System.debug('Record: ' + currentId);
                    System.debug('Status: ' + ar.status);
                    System.debug('Sources: ' + ar.sourcesUsed);
                }

            } catch (Exception e) {
                System.debug('=== BATCH ERROR [' + (currentIndex + 1) + '/' + responseIds.size() + '] ===');
                System.debug('Record: ' + currentId);
                System.debug('Error: ' + e.getMessage());
                // Continue to next — don't let one failure kill the chain
            }

            // Chain to next record
            Integer nextIndex = currentIndex + 1;
            if (nextIndex < responseIds.size()) {
                if (!Test.isRunningTest()) {
                    System.enqueueJob(new AnswerQueueable(responseIds, nextIndex));
                }
            }
        }
    }

    // ─── Helpers ──────────────────────────────────────────────────────

    @TestVisible
    private static String formatDuration(Integer totalSeconds) {
        if (totalSeconds < 60) {
            return totalSeconds + ' seconds';
        }
        Integer minutes = totalSeconds / 60;
        Integer seconds = Math.mod(totalSeconds, 60);
        if (seconds == 0) {
            return minutes + ' minutes';
        }
        return minutes + ' minutes ' + seconds + ' seconds';
    }
}