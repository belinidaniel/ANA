/**
 * @author Daniel Reto
 * @description COMM_TH_OrderItem test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      23/08/2024      100            ECOMM-1945: Timezones
 **/
@isTest
private class COMM_TH_OrderItemTest {
    @isTest
    static void insertTest() {

        Test.startTest();
        Id orderId = COMM_OMS_TestDataFactory.createSimpleOrder();
        Test.stopTest();

        Assert.isNotNull(orderId, 'order item record was not inserted');
    }

    @isTest
    static void updateTest() {
        Id orderId = COMM_OMS_TestDataFactory.createSimpleOrder();
        
        OrderItem orderItemRecord = [SELECT Id, COMM_ReservationStart__c, COMM_ReservationEnd__c FROM OrderItem WHERE Product2.COMM_Airport__c = 'LIS' Order By Id Limit 1];

        Test.startTest();
        orderItemRecord.COMM_ReservationStartStr__c = '2024-08-01 16:00:27';
        orderItemRecord.COMM_ReservationEndStr__c = '2024-08-02 16:00:27';
        update orderItemRecord;
        Test.stopTest();

        OrderItem actualRecord = [SELECT Id, COMM_ReservationStart__c, COMM_ReservationEnd__c FROM OrderItem WHERE Id = :orderItemRecord.Id];

        Assert.areNotEqual(orderItemRecord.COMM_ReservationStart__c, actualRecord.COMM_ReservationStart__c, 'order item record was not updated');
        Assert.areNotEqual(orderItemRecord.COMM_ReservationEnd__c, actualRecord.COMM_ReservationEnd__c, 'order item record was not updated');
    }
}