/**
 * @author Daniel Lascas
 * @description COMM_TH_Subscription test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    11/07/2024      100            ECOMM-1602: Original version
 **/
@isTest
private class COMM_TH_SubscriptionTest {
    @isTest
    static void insertTest() {
        COMM_Subscription__c subRecord = (COMM_Subscription__c) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_Subscription__c',
            new Map<String, Object>{
                'RecordTypeId' => COMM_GEN_Utility.getRecordTypeIdByDevName(COMM_Subscription__c.sObjectType, COMM_DO_Subscription.RECORDTYPE_PARTNER)
            }
        )[0];

        Test.startTest();
        insert subRecord;
        Test.stopTest();

        Assert.isNotNull(subRecord.Id, 'subscription record was not inserted');
    }

    @isTest
    static void updateTest() {
        COMM_Subscription__c subRecord = (COMM_Subscription__c) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Subscription__c',
            new Map<String, Object>{
                'RecordTypeId' => COMM_GEN_Utility.getRecordTypeIdByDevName(COMM_Subscription__c.sObjectType, COMM_DO_Subscription.RECORDTYPE_PARTNER)
            }
        )[0];

        Test.startTest();
        subRecord.COMM_FirstName__c = 'Test';
        update subRecord;
        Test.stopTest();

        COMM_Subscription__c actualRecord = [SELECT Id, COMM_FirstName__c FROM COMM_Subscription__c WHERE Id = :subRecord.Id];

        Assert.areEqual(subRecord.COMM_FirstName__c, actualRecord.COMM_FirstName__c, 'subscription record was not updated');
    }
}