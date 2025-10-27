/**
 * @author Daniel Reto
 * @description COMM_TW_Case_FillContactFromSuppliedName test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      22/07/2024      100            Original version
 **/
@isTest
private class COMM_TW_Case_FillContactFromSupNameTest {

    @isTest
    static void commerceLanguageConvertionTest() {
        //Scenario: Case was created without Contact Name, but with a SuppliedName (Affiliate records)
        //Expected: Value is converted to value used in Salesforce.
        List<Case> caseList = (List<Case>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Case',
            new Map<String, Object>{
                'SuppliedName' => fflib_IDGenerator.generate(Contact.SObjectType),
                'RecordTypeId' => Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('COMM_AffiliateRequest').RecordTypeId
            }
        );

        Test.startTest();
        COMM_TW_Case_FillContactFromSuppliedName worker = new COMM_TW_Case_FillContactFromSuppliedName();
        worker.execute(caseList);
        Test.stopTest();

        Assert.areEqual(caseList[0].SuppliedName, caseList[0].ContactId, 'expected language to change');
    }
}