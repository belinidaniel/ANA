/**
 * @author Rui Salgado
 * @description COMM_OMS_DatabaseUtilHandlerTest class
 *
 * Modification Log
 * ----------------------------------------------------------------------------------------------
 * Developer        Date          Coverage(%)   Description
 * ----------------------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024    100           Original version
 **/
@isTest
private class COMM_OMS_DatabaseUtilHandlerTest {
    /**
     * @description Test method of LogUtil.insertDatabaseErrors
     *   for Insert/Update
     */
    @isTest
    static void shouldInsertDatabaseErrorForInsert() {
        Contact contact = new Contact();
        boolean allOrNone = false;

        Test.startTest();
        Database.SaveResult result = Database.insert(contact, allOrNone);
        COMM_OMS_DatabaseUtilHandler.createDatabaseErrors(result);
        COMM_OMS_LogUtil.insertLogs();
        Test.stopTest();

        List<COMM_OMS_Log__c> logs = [SELECT Id FROM COMM_OMS_Log__c];

        System.assert(!logs.isEmpty(), 'Error log could not found');
    }

    /**
     * @description Test method of LogUtil.insertDatabaseErrors
     *   for List Insert/Update
     */
    @isTest
    static void shoulInsertDatabaseErrorsForInsert() {
        boolean allOrNone = false;
        COMM_OMS_TestDataInput.ContactInput contactInput = new COMM_OMS_TestDataInput.ContactInput();
        contactInput.lastName = COMM_OMS_Constants.TEST;

        Contact contact2 = new Contact();

        Contact[] contacts = new List<Contact>{ COMM_OMS_TestDataFactory.createContact(contactInput), contact2 };

        Test.startTest();
        Database.SaveResult[] result = Database.insert(contacts, allOrNone);
        COMM_OMS_DatabaseUtilHandler.createDatabaseErrors(result);
        COMM_OMS_LogUtil.insertLogs();
        Test.stopTest();

        List<COMM_OMS_Log__c> logs = [SELECT Id FROM COMM_OMS_Log__c];

        System.assert(!logs.isEmpty(), 'Error log could not found');
    }

    /**
     * @description Test method of LogUtil.insertDatabaseErrors
     *   for Upsert
     */
    @isTest
    static void shouldInsertDatabaseErrorForUpsert() {
        boolean allOrNone = false;
        COMM_OMS_TestDataInput.ContactInput contactInput = new COMM_OMS_TestDataInput.ContactInput();
        contactInput.lastName = COMM_OMS_Constants.TEST;

        Contact contactToUpdate = COMM_OMS_TestDataFactory.createContact(contactInput);
        insert contactToUpdate;

        contactToUpdate.LastName = '';

        Test.startTest();
        Database.UpsertResult result = Database.upsert(contactToUpdate, allOrNone);
        COMM_OMS_DatabaseUtilHandler.createDatabaseErrors(result);
        COMM_OMS_LogUtil.insertLogs();
        Test.stopTest();

        List<COMM_OMS_Log__c> logs = [SELECT Id FROM COMM_OMS_Log__c];

        System.assert(!logs.isEmpty(), 'Error log could not found');
    }

    /**
     * @description Test method of LogUtil.insertDatabaseErrors
     *   for List Upsert
     */
    @isTest
    static void shouldInsertDatabaseErrorsForUpsert() {
        boolean allOrNone = false;
        COMM_OMS_TestDataInput.ContactInput contactInput = new COMM_OMS_TestDataInput.ContactInput();
        contactInput.lastName = COMM_OMS_Constants.TEST;

        Contact contactToUpdate = COMM_OMS_TestDataFactory.createContact(contactInput);
        insert contactToUpdate;

        contactToUpdate.LastName = '';

        Test.startTest();
        Database.UpsertResult[] result = Database.upsert(new List<Contact>{ contactToUpdate }, allOrNone);
        COMM_OMS_DatabaseUtilHandler.createDatabaseErrors(result);
        COMM_OMS_LogUtil.insertLogs();
        Test.stopTest();

        List<COMM_OMS_Log__c> logs = [SELECT Id FROM COMM_OMS_Log__c];

        System.assert(!logs.isEmpty(), 'Error log could not found');
    }

    /**
     * @description Test method of LogUtil.insertDatabaseErrors
     *   for Delete
     */
    @isTest
    static void shouldInsertDatabaseErrorForDelete() {
        boolean allOrNone = false;
        COMM_OMS_TestDataInput.ContactInput contactInput = new COMM_OMS_TestDataInput.ContactInput();
        contactInput.lastName = COMM_OMS_Constants.TEST;
        Contact contact = COMM_OMS_TestDataFactory.createContact(contactInput);
        insert contact;
        delete contact;

        Test.startTest();
        Database.DeleteResult result = Database.delete(contact.Id, allOrNone);
        COMM_OMS_DatabaseUtilHandler.createDatabaseErrors(result);
        COMM_OMS_LogUtil.insertLogs();
        Test.stopTest();

        List<COMM_OMS_Log__c> logs = [SELECT Id FROM COMM_OMS_Log__c];

        System.assert(!logs.isEmpty(), 'Error log could not found');
    }

    /**
     * @description Test method of LogUtil.insertDatabaseErrors
     *   for List Delete
     */
    @isTest
    static void shouldInsertDatabaseErrorsForDelete() {
        boolean allOrNone = false;
        COMM_OMS_TestDataInput.ContactInput contactInput = new COMM_OMS_TestDataInput.ContactInput();
        contactInput.lastName = COMM_OMS_Constants.TEST;

        Contact contact = COMM_OMS_TestDataFactory.createContact(contactInput);
        insert contact;
        delete contact;

        Test.startTest();
        Database.DeleteResult[] result = Database.delete(new List<String>{ contact.Id }, allOrNone);
        COMM_OMS_DatabaseUtilHandler.createDatabaseErrors(result);
        COMM_OMS_LogUtil.insertLogs();
        Test.stopTest();

        List<COMM_OMS_Log__c> logs = [SELECT Id FROM COMM_OMS_Log__c];

        System.assert(!logs.isEmpty(), 'Error log could not found');
    }
}