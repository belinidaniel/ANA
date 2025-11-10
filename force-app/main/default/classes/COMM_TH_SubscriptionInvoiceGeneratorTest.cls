/**
 * @author Daniel Lascas
 * @description COMM_TH_SubscriptionInvoiceGenerator test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    01/04/2024      100            ECOMM-194: Original version
 **/
@isTest
private class COMM_TH_SubscriptionInvoiceGeneratorTest {
    @isTest
    static void insertTest() {
        COMM_SubscriptionInvoiceGenerator__e pEvent = (COMM_SubscriptionInvoiceGenerator__e) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_SubscriptionInvoiceGenerator__e',
            new Map<String, Object>{ 'COMM_CaseId__c' => fflib_IDGenerator.generate(Case.SObjectType) }
        )[0];

        Test.startTest();
        Database.SaveResult result = EventBus.publish(pEvent);
        Test.stopTest();

        Assert.isTrue(result.isSuccess(), 'platform event was not published successfully');
    }
}