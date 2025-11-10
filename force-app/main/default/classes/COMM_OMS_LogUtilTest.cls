/**
 * @author Rui Salgado
 * @description COMM_OMS_LogUtilTest class
 *
 * Modification Log
 * ----------------------------------------------------------------------------------------------
 * Developer        Date          Coverage(%)   Description
 * ----------------------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024    100            Original version
 **/
@isTest
private class COMM_OMS_LogUtilTest {
    /**
     * @description Test method of LogUtil.createErrorLog
     */
    @isTest
    static void shouldLogErrorWithAttachId() {
        String category = 'Unit Test';
        String message = 'Unit test error';

        COMM_OMS_TestDataInput.ContactInput contactInput = new COMM_OMS_TestDataInput.ContactInput();
        contactInput.lastName = COMM_OMS_Constants.TEST;

        Contact contactToInsert = COMM_OMS_TestDataFactory.createContact(contactInput);
        insert contactToInsert;

        String attachId = contactToInsert.Id;

        Test.startTest();
        COMM_OMS_Log__c insertedLog = COMM_OMS_LogUtil.createErrorLog(attachId, category, message);
        COMM_OMS_DatabaseUtil.commitChanges();
        Test.stopTest();

        COMM_OMS_Log__c log = [SELECT AttachedToId__c, Category__c, Message__c, IsError__c FROM COMM_OMS_Log__c WHERE Id = :insertedLog.Id];

        System.assert(log.AttachedToId__c.equals(attachId), 'Attached to Id does not match');
        System.assert(log.Category__c.equalsIgnoreCase(category), 'Category of the log does not match');
        System.assert(log.Message__c.equalsIgnoreCase(message), 'Message of the log does not match');
        System.assert(log.IsError__c, 'IsError should be checked/true');
    }

    /**
     * @description Test method of LogUtil.createErrorLog
     */
    @isTest
    static void shouldLogError() {
        String category = 'Unit Test';
        String message = 'Unit test error';

        Test.startTest();
        COMM_OMS_Log__c insertedLog = COMM_OMS_LogUtil.createErrorLog(category, message);
        COMM_OMS_DatabaseUtil.commitChanges();
        Test.stopTest();

        COMM_OMS_Log__c log = [SELECT AttachedToId__c, Category__c, Message__c, IsError__c FROM COMM_OMS_Log__c WHERE Id = :insertedLog.Id];

        System.assert(log.Category__c.equalsIgnoreCase(category), 'Category of the log does not match');
        System.assert(log.Message__c.equalsIgnoreCase(message), 'Message of the log does not match');
        System.assert(log.IsError__c, 'IsError should be checked/true');
    }

    /**
     * @description Test method of LogUtil.createInfoLog
     */
    @isTest
    static void shouldLogInfoWithAttachId() {
        String category = 'Unit Test';
        String message = 'Unit test error';

        COMM_OMS_TestDataInput.ContactInput contactInput = new COMM_OMS_TestDataInput.ContactInput();
        contactInput.lastName = COMM_OMS_Constants.TEST;

        Contact contactToInsert = COMM_OMS_TestDataFactory.createContact(contactInput);
        insert contactToInsert;

        String attachId = contactToInsert.Id;

        Test.startTest();
        COMM_OMS_Log__c insertedLog = COMM_OMS_LogUtil.createInfoLog(attachId, category, message);
        COMM_OMS_DatabaseUtil.commitChanges();
        Test.stopTest();

        COMM_OMS_Log__c log = [SELECT AttachedToId__c, Category__c, Message__c, IsError__c FROM COMM_OMS_Log__c WHERE Id = :insertedLog.Id];

        System.assert(log.AttachedToId__c.equals(attachId), 'Attached to Id does not match');
        System.assert(log.Category__c.equalsIgnoreCase(category), 'Category of the log does not match');
        System.assert(log.Message__c.equalsIgnoreCase(message), 'Message of the log does not match');
        System.assert(!log.IsError__c, 'IsError should be unchecked/false');
    }

    /**
     * @description Test method of LogUtil.createInfoLog
     */
    @isTest
    static void shouldLogInfo() {
        String category = 'Unit Test';
        String message = 'Unit test error';

        Test.startTest();
        COMM_OMS_Log__c insertedLog = COMM_OMS_LogUtil.createInfoLog(category, message);
        COMM_OMS_DatabaseUtil.commitChanges();
        Test.stopTest();

        COMM_OMS_Log__c log = [SELECT AttachedToId__c, Category__c, Message__c, IsError__c FROM COMM_OMS_Log__c WHERE Id = :insertedLog.Id];

        System.assert(log.Category__c.equalsIgnoreCase(category), 'Category of the log does not match');
        System.assert(log.Message__c.equalsIgnoreCase(message), 'Message of the log does not match');
        System.assert(!log.IsError__c, 'IsError should be unchecked/false');
    }

    /**
     * @description Test method of LogUtil.createEmailErrors
     */
    @isTest
    static void shouldCreateEmailErrors() {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSubject('Subject');

        Test.startTest();
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail }, false);
        COMM_OMS_LogUtil.createEmailErrors(results);
        COMM_OMS_DatabaseUtil.commitChanges();
        Test.stopTest();

        List<COMM_OMS_Log__c> logs = [SELECT Id FROM COMM_OMS_Log__c];

        System.assert(!logs.isEmpty(), 'Error log could not found');
    }

    /**
     * @description Test method of LogUtil.createConnectApiErrors
     *   for ConnectApi error
     */
    @isTest
    static void shouldInsertConnectApiError() {
        ConnectApi.OrderSummaryOutputRepresentation output = COMM_OMS_TestDataFactory.createConnectApiError();

        Test.startTest();
        COMM_OMS_LogUtil.createConnectApiErrors(output);
        COMM_OMS_DatabaseUtil.commitChanges();
        Test.stopTest();

        List<COMM_OMS_Log__c> logs = [SELECT Id FROM COMM_OMS_Log__c];

        System.assert(!logs.isEmpty(), 'Error log could not found');
    }
}