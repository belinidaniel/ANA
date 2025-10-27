/**
 * @author Daniel Lascas
 * @description COMM_TH_Contact test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    09/07/2024      100            ECOMM-1637: Original version
 **/
@isTest
private class COMM_TH_ContactTest {
    @isTest
    static void insertTest() {
        Contact contactRecord = (Contact) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Contact',
            new Map<String, Object>{ 'Description' => 'TestContact', 'FirstName' => 'test', 'LastName' => 'client' }
        )[0];

        Test.startTest();
        insert contactRecord;
        Test.stopTest();

        Assert.isNotNull(contactRecord.Id, 'contact record was not inserted');
    }

    @isTest
    static void updateTest() {
        Contact contactRecord = (Contact) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Contact',
            new Map<String, Object>{ 'Description' => 'TestContact', 'FirstName' => 'test', 'LastName' => 'client' }
        )[0];

        Test.startTest();
        contactRecord.Description = 'TestContact2';
        update contactRecord;
        Test.stopTest();

        Contact actualRecord = [SELECT Id, Description FROM Contact WHERE Id = :contactRecord.Id];

        Assert.areEqual(contactRecord.Description, actualRecord.Description, 'contact record was not updated');
    }
}