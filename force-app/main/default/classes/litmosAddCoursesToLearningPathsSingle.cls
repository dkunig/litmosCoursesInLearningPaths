public class litmosAddCoursesToLearningPathsSingle {
	//single-use class to add courses to learning paths
	Litmos__Configuration__c config = [SELECT Litmos__Api_Key__c,Litmos__Api_End_Point__c FROM Litmos__Configuration__c WHERE Litmos__Sync_Active__c = true];
    public static void addCoursesToPaths() {
        Map<String, Litmos__Program__c> programs = new Map<String,Litmos__Program__c>();
        Map<Litmos__LearningPath__c,List<String>> mapPathCourseLitmosId = new Map<Litmos__LearningPath__c, List<String>>();
        
        String apikey = 'c86a5a1f-4057-411a-99cd-e180ecfe9bee';
        String endpoint = 'https://api.litmos.com/v1.svc/learningpaths/';
        String endcap = '/courses?source=sourceapp&format=json';
        for(Litmos__LearningPath__c path : [SELECT Id,Litmos_Full_Id__c FROM Litmos__LearningPath__c WHERE Litmos_Full_Id__c != null]) {
            HttpResponse response = litmosConnection.getLitmosExternalService(endpoint + path.Litmos_Full_Id__c + endcap, apikey);
            List<String> programIds = new List<String>();
			if(response.getStatusCode() == 200) {
                List<Object> results = (List<Object>)JSON.deserializeUntyped(response.getBody());
                for(Object o : results) {
                    Map<String,Object> obj = (Map<String,Object>) o;
                    programs.put(String.valueOf(obj.get('Id')),new Litmos__Program__c(
                        Belongs_to_Learning_Path__c = true,
                    	Litmos_Full_Id__c = String.valueOf(obj.get('Id'))));
                    programIds.add(String.valueOf(obj.get('Id')));
                }
            }
            if(programIds.size() > 0) {
				mapPathCourseLitmosId.put(path, programIds);
            }
        }
        
        //get courses with Litmos Full Ids in programs keyset
        List<Litmos__Program__c> programsToMatch = [SELECT Id,Litmos_Full_Id__c FROM Litmos__Program__c WHERE Litmos_Full_Id__c IN :programs.keySet()];
        //add to map
        Map<String,Id> programMap = new Map<String,Id>();
        for(Litmos__Program__c program : programsToMatch) {
            programMap.put(program.Litmos_Full_Id__c, program.Id);
        }
        
        //loop through map of paths and courses and create new litmos__learningpathprogram__c records
        List<Litmos__LearningPathProgram__c> pathPrograms = new List<Litmos__LearningPathProgram__c>();
        for(Litmos__LearningPath__c path : mapPathCourseLitmosId.keySet()) {
            for(String progId : mapPathCourseLitmosId.get(path)) {
                pathPrograms.add(new Litmos__LearningPathProgram__c(
                	Litmos__LearningPathId__c = path.Id,
                    Litmos__ProgramId__c = programMap.get(progId),
                    Litmos__LitmosId__c = path.Litmos_Full_Id__c + ' - ' + progId 
                ));
            }
        }
        
        //insert new learningpathprograms and sync logs
        Set<Id> successes = new Set<Id>();
        List<String> errors = new List<String>();
        List<Database.SaveResult> results = Database.insert(pathPrograms, false);
        for(Database.SaveResult sr : results) {
            if(sr.isSuccess()){
                successes.add(sr.getId());
            } else {
                errors.add(String.valueOf(sr.getErrors()));
            }
        }
        if(successes.size() > 0) {
            litmosSyncLogs.logPathCourseSuccess([SELECT Id,Litmos__LearningPathId__c,Litmos__ProgramId__c FROM Litmos__LearningPathProgram__c WHERE Id IN : successes]);
        }
        if(errors.size() > 0) {
            litmosSyncLogs.logPathCourseError(errors);
        }
        Database.upsert(programs.values(),Litmos__Program__c.Litmos_Full_Id__c,true);
    }
}