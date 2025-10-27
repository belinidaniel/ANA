/**
 * @author           Daniel Lascas
 * @description      COMM_TW_Case_AirportUpdate test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    11/07/2024      100            ECOMM-1602: Original version
 **/
@isTest
private class COMM_TW_Case_AirportUpdateTest {
    @isTest
    static void updateFieldTest() {
        //Scenario:	Case's Airport was Updated.
        //Expected: Airport Text Field is updated

        //Generate mocked Case
        Case oldCase = (Case) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Case',
            new Map<String, Object>{ 'Id' => fflib_IdGenerator.generate(Case.sObjectType), 'COMM_Airport__c' => 'LIS' }
        )[0];

        //Mocked Update where Airport is changed
        Case newCase = oldCase.clone(true);
        newCase.COMM_Airport__c = 'LIS;OPO';

        Map<Id, Case> oldCaseMap = new Map<Id, Case>{ oldCase.Id => oldCase };
        List<Case> newCaseList = new List<Case>{ newCase };

        Test.startTest();
        COMM_TW_Case_AirportUpdate worker = new COMM_TW_Case_AirportUpdate();
        worker.execute(newCaseList, oldCaseMap);
        Test.stopTest();

        Assert.areEqual(
            newCase.COMM_Airport__c,
            newCase.COMM_AirportTextList__c,
            'expected text airport field to be updated with multi-picklist airport fields value'
        );
    }
}