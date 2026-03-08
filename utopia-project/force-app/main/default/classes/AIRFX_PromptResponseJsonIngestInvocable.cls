public with sharing class AIRFX_PromptResponseJsonIngestInvocable {

    // ===== INPUT / OUTPUT WRAPPERS =====
    public class Request {
        @InvocableVariable(required=true)
        public String jsonString; // Entire JSON from the prompt
        @InvocableVariable(required=true)
        public String projectId; // GPS Project Id        
    }

    public class Result {
        @InvocableVariable
        public String status;           // "OK" or "ERROR"
        @InvocableVariable
        public Integer insertedCount;   // number of GPS_ResponseNew__c rows inserted
        @InvocableVariable
        public String message;          // error details or summary
    }

    // ===== INVOCABLE ENTRY POINT =====
    @InvocableMethod(
        label='Ingest Prompt JSON → GPS_ResponseNew__c'
        description='Parses prompt JSON (ignoring file_count) and inserts GPS_ResponseNew__c rows for each item under files[].items[].'
        category='AI / Prompt Builder'
    )
    public static List<Result> run(List<Request> requests) {
        List<Result> responses = new List<Result>();
        if (requests == null || requests.isEmpty()) {
            Result r = new Result();
            r.status = 'ERROR';
            r.insertedCount = 0;
            r.message = 'No requests provided.';
            responses.add(r);
            return responses;
        }

        // Process each request independently (bulk-safe)
        for (Request req : requests) {
            Result res = new Result();
            try {
                Integer inserted = ingestOne(req.jsonString, req.projectId);
                res.status = 'OK';
                res.insertedCount = inserted;
                res.message = 'Inserted ' + inserted + ' GPS_ResponseNew__c record(s).';
            } catch (Exception e) {
                res.status = 'ERROR';
                res.insertedCount = 0;
                res.message = e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }

    // ===== CORE INGEST (single request) =====
    private static Integer ingestOne(String jsonString,String projectId) {
        if (String.isBlank(jsonString)) {
            throw new AuraHandledException('jsonString is blank.');
        }
        if (String.isBlank(projectId)) {
            throw new AuraHandledException('projectId is blank.');
        }

        // Scrub Markdown ``` wrappers (Prompt Builder sometimes wraps JSON)
        // Remove ANY occurrence of backtick triples to avoid JSON parse failures.
        jsonString = jsonString.replaceAll('```json', '');
        jsonString = jsonString.replaceAll('```JSON', '');
        jsonString = jsonString.replaceAll('```', '');        

        Map<String,Object> root = (Map<String,Object>) JSON.deserializeUntyped(jsonString);
        if (root == null) {
            throw new AuraHandledException('Unable to parse JSON.');
        }

        // We IGNORE file_count by request.
        List<Object> files = (List<Object>) root.get('files');
        if (files == null || files.isEmpty()) {
            return 0;
        }

        List< GPS_ResponseNew__c > buffer = new List< GPS_ResponseNew__c >();
        for (Object fObj : files) {
            try {
                if (!(fObj instanceof Map<String,Object>)) continue;
                Map<String,Object> file = (Map<String,Object>) fObj;

                String fileName     = (String) file.get('fileName');
                String contentDocId = (String) file.get('contentDocumentId');
                List<Object> items  = (List<Object>) file.get('items');

                // If there is a file node but no items array, or the array is empty,
                // we skip this node and continue processing the rest.
                if (items == null || items.isEmpty()) {
                    continue;
                }

                for (Object iObj : items) {
                    if (!(iObj instanceof Map<String,Object>)) continue;
                    Map<String,Object> item = (Map<String,Object>) iObj;

                    GPS_ResponseNew__c row = new GPS_ResponseNew__c();
                    // Field API names are assumed to match these:
                    // File_Name__c, Content_Document_Id__c, Type__c, Item_Id__c, Section__c, Context__c
                    row.Document_Name__c                     = fileName;
                    row.ContentDocumentID__c                 = contentDocId;
                    row.Requirement_Type__c                  = (String) item.get('type');
                    row.Requirement_Number__c                = (String) item.get('itemId');
                    row.Document_Question_Classification__c  = (String) item.get('section');
                    row.Question__c                          = (String) item.get('question');
                    row.GPS_Projects__c                      = projectId;
                    buffer.add(row);
                }
            } catch (Exception e) {
                // If one file node is malformed, skip it but continue with the rest.
                System.debug(LoggingLevel.WARN,
                    'AIRFX_PromptResponseJsonIngestInvocable: skipping file node due to error: ' + e.getMessage()
                );
                continue;
            }
        }

        if (buffer.isEmpty()) return 0;

        // Partial success handling
        Database.SaveResult[] srs = Database.insert(buffer, /* allOrNone */ false);
        Integer ok = 0;
        List<String> errs = new List<String>();
        for (Integer i = 0; i < srs.size(); i++) {
            if (srs[i].isSuccess()) {
                ok++;
            } else {
                for (Database.Error e : srs[i].getErrors()) {
                    errs.add('Row ' + i + ': ' + e.getStatusCode() + ' - ' + e.getMessage());
                }
            }
        }
        if (!errs.isEmpty()) {
            // Surface errors while still allowing the successes
            throw new AuraHandledException(
                'Inserted ' + ok + ' record(s), but some rows failed: ' + String.join(errs, ' | ')
            );
        }
        return ok;
    }
}