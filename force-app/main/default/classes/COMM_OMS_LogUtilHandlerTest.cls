/**
 * @author Rui Salgado
 * @description COMM_OMS_LogUtilHandlerTest class
 *
 * Modification Log
 * ----------------------------------------------------------------------------------------------
 * Developer        Date          Coverage(%)   Description
 * ----------------------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024    100            Original version
 **/
@isTest
private class COMM_OMS_LogUtilHandlerTest {
    /**
     * @description Test method of LogUtil.createEmailErrors
     */
    @isTest
    static void shouldCreateEmailErrors() {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSubject('Subject');

        Test.startTest();
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail }, false);
        for (Messaging.SendEmailResult result : results) {
            if (!result.isSuccess()) {
                COMM_OMS_LogUtilHandler.createEmailErrorsAsLogs(result.getErrors());
            }
        }
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
        if (!output.success) {
            COMM_OMS_LogUtilHandler.createConnectApiErrorsAsLogs(output.errors);
        }
        COMM_OMS_DatabaseUtil.commitChanges();
        Test.stopTest();

        List<COMM_OMS_Log__c> logs = [SELECT Id FROM COMM_OMS_Log__c];

        System.assert(!logs.isEmpty(), 'Error log could not found');
    }
}