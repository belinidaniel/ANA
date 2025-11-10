/**
 * @author Rui Salgado
 * @description COMM_OMS_DatabaseUtilTest class
 *
 * Modification Log
 * ----------------------------------------------------------------------------------------------
 * Developer        Date          Coverage(%)   Description
 * ----------------------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024    90            Original version
 **/
@isTest
private class COMM_OMS_DatabaseUtilTest {
    /**
     * @description Test method of DatabaseUtil.insertRecords
     */
    @isTest
    static void shouldInsertRecord() {
        COMM_OMS_TestDataInput.ContactInput contactInput = new COMM_OMS_TestDataInput.ContactInput();
        contactInput.lastName = COMM_OMS_Constants.TEST;

        Contact contactToInsert = COMM_OMS_TestDataFactory.createContact(contactInput);

        Test.startTest();
        COMM_OMS_DatabaseUtil.insertRecords(contactToInsert, false);
        COMM_OMS_DatabaseUtil.commitChanges();
        Test.stopTest();

        List<Contact> contacts = [SELECT Id FROM Contact WHERE LastName = :contactInput.lastName];
        List<COMM_OMS_Log__c> logs = [SELECT Id FROM COMM_OMS_Log__c];

        System.assert(logs.isEmpty(), 'Logs should not be created');
        System.assert(!contacts.isEmpty(), 'No contact record found');
    }

    /**
     * @description Test method of DatabaseUtil.insertRecords
     */
    @isTest
    static void shouldInsertRecords() {
        COMM_OMS_TestDataInput.ContactInput contactInput1 = new COMM_OMS_TestDataInput.ContactInput();
        contactInput1.lastName = COMM_OMS_Constants.TEST + '1';
        COMM_OMS_TestDataInput.ContactInput contactInput2 = new COMM_OMS_TestDataInput.ContactInput();
        contactInput2.lastName = COMM_OMS_Constants.TEST + '2';

        Contact[] contactsToInsert = new List<Contact>{
            COMM_OMS_TestDataFactory.createContact(contactInput1),
            COMM_OMS_TestDataFactory.createContact(contactInput2)
        };

        Test.startTest();
        COMM_OMS_DatabaseUtil.insertRecords(contactsToInsert, false);
        COMM_OMS_DatabaseUtil.commitChanges();
        Test.stopTest();

        List<Contact> contacts = [SELECT Id FROM Contact WHERE LastName = :contactInput1.lastName OR LastName = :contactInput2.lastName];
        List<COMM_OMS_Log__c> logs = [SELECT Id FROM COMM_OMS_Log__c];

        System.assert(logs.isEmpty(), 'Logs should not be created');
        System.assert(contactsToInsert.size() == contacts.size(), 'Contact record does not match');
    }

    /**
     * @description Test method of DatabaseUtil.updateRecords
     */
    @isTest
    static void shouldUpdateRecord() {
        COMM_OMS_TestDataInput.ContactInput contactInput = new COMM_OMS_TestDataInput.ContactInput();
        contactInput.lastName = COMM_OMS_Constants.TEST;

        Contact contact = COMM_OMS_TestDataFactory.createContact(contactInput);
        insert contact;

        contact.LastName = contactInput.lastName + '1';

        Test.startTest();
        COMM_OMS_DatabaseUtil.updateRecords(contact, false);
        COMM_OMS_DatabaseUtil.commitChanges();
        Test.stopTest();

        List<Contact> contacts = [SELECT Id FROM Contact WHERE LastName = :contact.LastName];
        List<COMM_OMS_Log__c> logs = [SELECT Id FROM COMM_OMS_Log__c];

        System.assert(logs.isEmpty(), 'Logs should not be created');
        System.assert(!contacts.isEmpty(), 'No contact record found');
    }

    /**
     * @description Test method of DatabaseUtil.updateRecords
     */
    @isTest
    static void shouldUpdateRecords() {
        COMM_OMS_TestDataInput.ContactInput contactInput = new COMM_OMS_TestDataInput.ContactInput();
        contactInput.lastName = COMM_OMS_Constants.TEST;

        Contact contact = COMM_OMS_TestDataFactory.createContact(contactInput);
        insert contact;

        contact.LastName = contactInput.lastName + '1';

        Test.startTest();
        COMM_OMS_DatabaseUtil.updateRecords(new List<Contact>{ contact }, false);
        COMM_OMS_DatabaseUtil.commitChanges();
        Test.stopTest();

        List<Contact> contacts = [SELECT Id FROM Contact WHERE LastName = :contact.LastName];
        List<COMM_OMS_Log__c> logs = [SELECT Id FROM COMM_OMS_Log__c];

        System.assert(logs.isEmpty(), 'Logs should not be created');
        System.assert(!contacts.isEmpty(), 'No contact record found');
    }

    /**
     * @description Test method of DatabaseUtil.upsertRecords
     */
    @isTest
    static void shouldUpsertRecord() {
        COMM_OMS_TestDataInput.ContactInput contactInput = new COMM_OMS_TestDataInput.ContactInput();
        contactInput.lastName = COMM_OMS_Constants.TEST;

        Contact contact = COMM_OMS_TestDataFactory.createContact(contactInput);
        insert contact;

        contact.LastName = contactInput.lastName + '1';

        Test.startTest();
        COMM_OMS_DatabaseUtil.upsertRecords(contact, false);
        COMM_OMS_DatabaseUtil.commitChanges();
        Test.stopTest();

        List<Contact> contacts = [SELECT Id FROM Contact WHERE LastName = :contact.LastName];
        List<COMM_OMS_Log__c> logs = [SELECT Id FROM COMM_OMS_Log__c];

        System.assert(logs.isEmpty(), 'Logs should not be created');
        System.assert(!contacts.isEmpty(), 'No contact record found');
    }

    /**
     * @description Test method of DatabaseUtil.upsertRecords
     */
    @isTest
    static void shouldUpsertRecords() {
        COMM_OMS_TestDataInput.ContactInput contactInput = new COMM_OMS_TestDataInput.ContactInput();
        contactInput.lastName = COMM_OMS_Constants.TEST;

        Contact contact = COMM_OMS_TestDataFactory.createContact(contactInput);
        insert contact;

        contact.LastName = contactInput.lastName + '1';

        Test.startTest();
        COMM_OMS_DatabaseUtil.upsertRecords(new List<Contact>{ contact }, false);
        COMM_OMS_DatabaseUtil.commitChanges();
        Test.stopTest();

        List<Contact> contacts = [SELECT Id FROM Contact WHERE LastName = :contact.LastName];
        List<COMM_OMS_Log__c> logs = [SELECT Id FROM COMM_OMS_Log__c];

        System.assert(logs.isEmpty(), 'Logs should not be created');
        System.assert(!contacts.isEmpty(), 'No contact record found');
    }

    /**
     * @description Test method of DatabaseUtil.deleteRecord
     */
    @isTest
    static void shouldDeleteRecord() {
        COMM_OMS_TestDataInput.ContactInput contactInput = new COMM_OMS_TestDataInput.ContactInput();
        contactInput.lastName = COMM_OMS_Constants.TEST;

        Contact contact = COMM_OMS_TestDataFactory.createContact(contactInput);
        insert contact;

        Test.startTest();
        COMM_OMS_DatabaseUtil.deleteRecords(contact.Id, false);
        COMM_OMS_DatabaseUtil.commitChanges();
        Test.stopTest();

        List<Contact> contacts = [SELECT Id FROM Contact WHERE LastName = :contactInput.lastName];
        List<COMM_OMS_Log__c> logs = [SELECT Id FROM COMM_OMS_Log__c];

        System.assert(logs.isEmpty(), 'Logs should not be created');
        System.assert(contacts.isEmpty(), 'Records are not deleted');
    }

    /**
     * @description Test method of DatabaseUtil.deleteRecords
     */
    @isTest
    static void shouldDeleteRecords() {
        COMM_OMS_TestDataInput.ContactInput contactInput = new COMM_OMS_TestDataInput.ContactInput();
        contactInput.lastName = COMM_OMS_Constants.TEST;

        Contact contact = COMM_OMS_TestDataFactory.createContact(contactInput);
        insert contact;

        Test.startTest();
        COMM_OMS_DatabaseUtil.deleteRecords(new List<String>{ contact.Id }, false);
        COMM_OMS_DatabaseUtil.commitChanges();
        Test.stopTest();

        List<Contact> contacts = [SELECT Id FROM Contact WHERE LastName = :contactInput.lastName];
        List<COMM_OMS_Log__c> logs = [SELECT Id FROM COMM_OMS_Log__c];

        System.assert(logs.isEmpty(), 'Logs should not be created');
        System.assert(contacts.isEmpty(), 'Records are not deleted');
    }

    /**
     * @description Test method of LogUtil.insertDatabaseErrors
     *   for Insert/Update
     */
    @isTest
    static void shouldInsertDatabaseErrorForInsert() {
        Contact contact = new Contact();

        Test.startTest();
        COMM_OMS_DatabaseUtil.insertRecords(contact, false);
        COMM_OMS_DatabaseUtil.commitChanges();
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
        COMM_OMS_TestDataInput.ContactInput contactInput = new COMM_OMS_TestDataInput.ContactInput();
        contactInput.lastName = COMM_OMS_Constants.TEST;

        Contact contact2 = new Contact();

        Contact[] contacts = new List<Contact>{ COMM_OMS_TestDataFactory.createContact(contactInput), contact2 };

        Test.startTest();
        COMM_OMS_DatabaseUtil.insertRecords(contacts, false);
        COMM_OMS_DatabaseUtil.commitChanges();
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
        COMM_OMS_TestDataInput.ContactInput contactInput = new COMM_OMS_TestDataInput.ContactInput();
        contactInput.lastName = COMM_OMS_Constants.TEST;

        Contact contactToUpdate = COMM_OMS_TestDataFactory.createContact(contactInput);
        insert contactToUpdate;

        contactToUpdate.LastName = '';

        Test.startTest();
        COMM_OMS_DatabaseUtil.upsertRecords(contactToUpdate, false);
        COMM_OMS_DatabaseUtil.commitChanges();
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
        COMM_OMS_TestDataInput.ContactInput contactInput = new COMM_OMS_TestDataInput.ContactInput();
        contactInput.lastName = COMM_OMS_Constants.TEST;

        Contact contactToUpdate = COMM_OMS_TestDataFactory.createContact(contactInput);
        insert contactToUpdate;

        contactToUpdate.LastName = '';

        Test.startTest();
        COMM_OMS_DatabaseUtil.upsertRecords(new List<Contact>{ contactToUpdate }, false);
        COMM_OMS_DatabaseUtil.commitChanges();
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
        COMM_OMS_TestDataInput.ContactInput contactInput = new COMM_OMS_TestDataInput.ContactInput();
        contactInput.lastName = COMM_OMS_Constants.TEST;
        Contact contact = COMM_OMS_TestDataFactory.createContact(contactInput);
        insert contact;
        delete contact;

        Test.startTest();
        COMM_OMS_DatabaseUtil.deleteRecords(contact.Id, false);
        COMM_OMS_DatabaseUtil.commitChanges();
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
        COMM_OMS_TestDataInput.ContactInput contactInput = new COMM_OMS_TestDataInput.ContactInput();
        contactInput.lastName = COMM_OMS_Constants.TEST;

        Contact contact = COMM_OMS_TestDataFactory.createContact(contactInput);
        insert contact;
        delete contact;

        Test.startTest();
        COMM_OMS_DatabaseUtil.deleteRecords(new List<String>{ contact.Id }, false);
        COMM_OMS_DatabaseUtil.commitChanges();
        Test.stopTest();

        List<COMM_OMS_Log__c> logs = [SELECT Id FROM COMM_OMS_Log__c];

        System.assert(!logs.isEmpty(), 'Error log could not found');
    }
}