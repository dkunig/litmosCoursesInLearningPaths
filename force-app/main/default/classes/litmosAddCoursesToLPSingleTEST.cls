@isTest
public class litmosAddCoursesToLPSingleTEST {
	@testSetup
    static void setup() {
        insert new Litmos__Configuration__c(
        	Litmos__Api_Key__c ='apikey',
            Litmos__Api_End_Point__c = 'myendpoint',
            Litmos__Sync_Active__c = true
        );
        insert new Litmos__LearningPath__c(
        	Name = 'Test Learning Path',
            Litmos_Full_Id__c = 'LPFULLID'
        );
        insert new Litmos__Program__c(
        	Name = 'Test Program',
            Litmos_Full_Id__c = 'PROGRAMFULLID'
        );
    }
    @isTest
    static void testAddCourses() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('litmosCourseInLP');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        litmosAddCoursesToLearningPathsSingle.addCoursesToPaths();
        Test.stopTest();
        System.assertEquals(1, [SELECT count() FROM Litmos__LearningPathProgram__c]);
    }
}