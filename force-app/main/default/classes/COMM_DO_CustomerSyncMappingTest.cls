/**
 * @author Daniel Lascas
 * @description COMM_DO_CustomerSyncMapping test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    17/06/2024      100            Original version
 **/
@isTest
private class COMM_DO_CustomerSyncMappingTest {
    @isTest
    static void mappingTest() {
        //Scenario: Mapping is called to prepare JSON sent to Customer using OCAPI
        //Expected: Map with mapped data according to metadata

        //Generate Mocked Account Record
        Account testAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(Account.sObjectType), 'COMM_IndividualStaff__c' => true }
        )[0];

        Map<String, Object> testMap = new Map<String, Object>();

        Test.startTest();
        COMM_DO_CustomerSyncMapping worker = new COMM_DO_CustomerSyncMapping();
        Set<String> mappedFieldSet = worker.getCoreFieldList('Account', true);
        worker.mapJsonFromSObject(testAccount, testMap, true);
        Test.stopTest();

        //Verify Result
        Assert.isFalse(mappedFieldSet.isEmpty(), 'expected a set with values');
        Assert.isFalse(testMap.isEmpty(), 'expected a resulting map with values');
    }
}