/**
 * @author Daniel Lascas
 * @description COMM_REP_SubscriptionInvoice test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    03/05/2024      100            ECOMM-194: Original version
 **/
@isTest
private class COMM_REP_SubscriptionInvoiceTest {
    private final static COMM_REP_SubscriptionInvoice INVOICE_REP = new COMM_REP_SubscriptionInvoice();

    @TestSetup
    static void makeData() {
        List<COMM_Subscription__c> subscriptionRecordList = (List<COMM_Subscription__c>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Subscription__c',
            new Map<String, Object>{
                'RecordTypeId' => Schema.SObjectType.COMM_Subscription__c.getRecordTypeInfosByDeveloperName()
                    .get(COMM_DO_Subscription.RECORDTYPE_PARTNER)
                    .RecordTypeId
            }
        );

        //Insert a test Subscription Invoice Record
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_SubscriptionInvoice__c',
            new Map<String, Object>{ 'COMM_Subscripton__c' => subscriptionRecordList[0].Id }
        );
    }

    @isTest
    static void getSubInvoiceByIdsTest() {
        List<COMM_SubscriptionInvoice__c> expectedList = [SELECT Id FROM COMM_SubscriptionInvoice__c LIMIT 1];

        Test.startTest();
        List<COMM_SubscriptionInvoice__c> actualList = INVOICE_REP.getSubInvoiceByIds(new Set<Id>{ expectedList[0].Id });
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'obtained record does not match expected');
    }
}