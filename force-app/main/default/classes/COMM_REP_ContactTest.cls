/**
 * @author           Daniel Lascas
 * @description      COMM_REP_Contact test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    09/07/2024      100            ECOMM-370: Original version
 **/
@isTest
private class COMM_REP_ContactTest {
    private static final COMM_REP_Contact CONTACT_REP = new COMM_REP_Contact();

    @TestSetup
    static void makeData() {
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Contact',
            new Map<String, Object>{ 'FirstName' => 'Test', 'LastName' => 'Tester', 'Email' => 'test@tester.invalid' }
        );
    }

    @isTest
    static void getContactWithRequestFieldsByIdsTest() {
        List<Contact> expectedList = [SELECT Id FROM Contact LIMIT 1];
        Test.startTest();
        List<Contact> actualList = CONTACT_REP.getContactWithRequestFieldsByIds(new Set<Id>{ expectedList[0].Id });
        Test.stopTest();
        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'contact does not match expected');
    }
}