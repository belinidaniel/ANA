/**
 * @author Daniel Lascas
 * @description COMM_TH_Capacity test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    08/02/2024      100            Original version
 **/
@isTest
private class COMM_TH_CapacityTest {
    @isTest
    static void insertTest() {
        COMM_Capacity__c capacityRecord = (COMM_Capacity__c) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_ValidFrom__c' => Datetime.now().addHours(1),
                'COMM_ValidTo__c' => Datetime.now().addDays(2),
                'COMM_Capacity__c' => 10,
                'COMM_IsDefaultCapacity__c' => true
            }
        )[0];

        Test.startTest();
        insert capacityRecord;
        Test.stopTest();

        Assert.isNotNull(capacityRecord.Id, 'capacity record was not inserted');
    }

    @isTest
    static void updateTest() {
        COMM_Capacity__c capacityRecord = (COMM_Capacity__c) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_ValidFrom__c' => Datetime.now().addHours(1),
                'COMM_ValidTo__c' => Datetime.now().addDays(2),
                'COMM_Capacity__c' => 10,
                'COMM_IsDefaultCapacity__c' => true
            }
        )[0];

        Test.startTest();
        capacityRecord.COMM_ValidTo__c = Datetime.now().addDays(2);
        update capacityRecord;
        Test.stopTest();

        COMM_Capacity__c actualRecord = [SELECT Id, COMM_ValidTo__c FROM COMM_Capacity__c WHERE Id = :capacityRecord.Id];

        Assert.areEqual(capacityRecord.COMM_ValidTo__c, actualRecord.COMM_ValidTo__c, 'capacity record was not updated');
    }

    @isTest
    static void deleteTest() {
        COMM_Capacity__c capacityRecord = (COMM_Capacity__c) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_ValidFrom__c' => Datetime.now().addHours(1),
                'COMM_ValidTo__c' => Datetime.now().addDays(2),
                'COMM_Capacity__c' => 10,
                'COMM_IsDefaultCapacity__c' => true
            }
        )[0];

        Test.startTest();
        delete capacityRecord;
        Test.stopTest();

        List<COMM_Capacity__c> actualRecordList = [SELECT Id FROM COMM_Capacity__c WHERE Id = :capacityRecord.Id];

        Assert.isTrue(actualRecordList.isEmpty(), 'capacity record was not deleted');
    }
}