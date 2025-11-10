/**
 * @author Daniel Lascas
 * @description COMM_TW_Case_VerifyLanguage test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    25/03/2024      100            Original version
 **/
@isTest
private class COMM_TW_Case_VerifyLanguageTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IDO_LanguageMapping LANGUAGE_MAPPING_DO = (COMM_DO_LanguageMapping) MOCKS.mock(COMM_DO_LanguageMapping.class);

    @isTest
    static void commerceLanguageConvertionTest() {
        //Scenario: Case was created from Case with a value that isn't used in Salesforce
        //Expected: Value is converted to value used in Salesforce.
        List<Case> caseList = (List<Case>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Case',
            new Map<String, Object>{ 'COMM_Language__c' => 'en_PT' }
        );

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(LANGUAGE_MAPPING_DO.getSalesforceLanguage(fflib_Match.anyString())).thenReturn('en_US');
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_TW_Case_VerifyLanguage worker = new COMM_TW_Case_VerifyLanguage();
        worker = new COMM_TW_Case_VerifyLanguage(LANGUAGE_MAPPING_DO);
        worker.execute(caseList);
        Test.stopTest();

        Assert.areEqual('en_US', caseList[0].COMM_Language__c, 'expected language to change');
    }
}