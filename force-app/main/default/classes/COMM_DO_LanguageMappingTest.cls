/**
 * @author Daniel Lascas
 * @description COMM_DO_LanguageMapping test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    25/03/2024      100            Original version
 **/
@isTest
private class COMM_DO_LanguageMappingTest {
    private static final COMM_DO_LanguageMapping MAPPING_DO = new COMM_DO_LanguageMapping();
    @isTest
    static void getExistingMappingTest() {
        //Retrieve first setting to use for testing
        COMM_LanguageMapping__mdt expectedSetting = COMM_LanguageMapping__mdt.getAll().values()[0];
        Test.startTest();
        String mappedValue = MAPPING_DO.getSalesforceLanguage(expectedSetting.COMM_ValueInCommerce__c);
        Test.stopTest();
        Assert.areEqual(expectedSetting.COMM_ValueInSalesforce__c, mappedValue, 'mapped value does not match expected');
    }

    @isTest
    static void getNonExistingMappingTest() {
        //Test for when Metadata Record doesn't exist
        Test.startTest();
        String mappedValue = MAPPING_DO.getSalesforceLanguage('noMap');
        Test.stopTest();
        Assert.areEqual('noMap', mappedValue, 'mapped value does not match expected');
    }
}