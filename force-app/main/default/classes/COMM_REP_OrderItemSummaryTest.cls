/**
 * @author Rui Salgado
 * @description COMM_REP_OrderItemSummaryTest class
 *
 * Modification Log
 * ----------------------------------------------------------------------------------------------
 * Developer        Date          Coverage(%)   Description
 * ----------------------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024    100           Original version
 * Diogo Gonçalves  01/04/2024    100           ECOMM-481: Added testGetForGiftCard
 * Diogo Gonçalves  20/06/2024    100           ECOMM-1420: Added testGetForVoucherPDF
 * Daniel Reto      07/10/2024    100           Query with missing fields - testGetForGiftCard
 * Daniel Reto      07/10/2024    100           ECOMM-327
 **/
@isTest
private class COMM_REP_OrderItemSummaryTest {
    private static COMM_IREP_OrderItemSummary orderItemSummaryRep = new COMM_REP_OrderItemSummary();

    @testSetup
    static void setup() {
        Id orderId = COMM_OMS_TestDataFactory.createOrderAndRelated();
    }

    @isTest
    static void shouldGetForCPMS() {
        List<Id> ids = new List<ID>();
        List<OrderItemSummary> listOIS = [SELECT Id FROM OrderItemSummary];
        for (OrderItemSummary ois : listOIS) {
            ids.add(ois.Id);
        }
        Test.startTest();
        List<OrderItemSummary> orderItemSummaries = orderItemSummaryRep.getForCPMS(ids);
        Test.stopTest();
        Assert.areEqual(ids.size(), orderItemSummaries.size(), 'Number of order item summaries should be ' + ids.size());
        Assert.isTrue(orderItemSummaries.size() > 0, 'Number of order item summaries should be greater than 0');
    }

    @isTest
    static void testGetOrderItemSummariesById() {
        List<OrderItemSummary> orderItemSummaries = [
            SELECT
                Id,
                Product2.Family,
                Product2.COMM_Airport__c,
                COMM_ReservationStart__c,
                Product2.Description,
                OrderSummary.OrderNumber,
                OrderSummary.Account.Name,
                Quantity
            FROM OrderItemSummary
            WITH USER_MODE
        ];
        List<String> ids = new List<String>();
        for (OrderItemSummary ois : orderItemSummaries) {
            ids.add(ois.Id);
        }
        Test.startTest();
        List<OrderItemSummary> retrievedOrderItemSummaries = new COMM_REP_OrderItemSummary().getOrderItemSummariesById(ids);
        Test.stopTest();
        Assert.areEqual(orderItemSummaries.size(), retrievedOrderItemSummaries.size(), 'The returned data does not match the test data');
    }

    @isTest
    static void testGetForGiftCard() {
        List<OrderItemSummary> orderItemSummaries = new List<OrderItemSummary>();
        OrderItemSummary orderItemSummary = [
            SELECT
                Id,
                Product2.Family,
                Product2.COMM_Airport__c,
                COMM_ReservationStart__c,
                COMM_TimeZoneByAirport__c,
                TotalAmtWithTax,
                OrderDeliveryGroupSummary.EmailAddress,
                Product2.Description,
                OrderSummaryId,
                OrderSummary.OrderNumber,
                OrderSummary.Account.Name,
                Quantity
            FROM OrderItemSummary
            WITH USER_MODE
            LIMIT 1
        ];
        orderItemSummaries.add(orderItemSummary);
        Test.startTest();
        List<OrderItemSummary> retrievedOrderItemSummaries = new COMM_REP_OrderItemSummary().getForGiftCard(new List<String>{ orderItemSummary.Id });
        Test.stopTest();
        Assert.areEqual(orderItemSummaries, retrievedOrderItemSummaries, 'The returned data does not match the test data');
    }

    @isTest
    static void testGetForVoucherPDF() {
        OrderSummary os = [SELECT Id FROM OrderSummary LIMIT 1];
        List<String> orderItemSummaryIdList = new List<String>();
        List<OrderItemSummary> orderItemSummaries = [
            SELECT
                Id,
                OrderSummaryId,
                Product2.Name,
                Type,
                COMM_ReservationStart__c,
                COMM_ReservationName__c,
                COMM_QRCodeImage__c,
                Product2.Family,
                COMM_ReservationEnd__c,
                COMM_LicensePlate__c
            FROM OrderItemSummary
            WHERE OrderSummaryId = :os.Id AND Status != :COMM_DO_OrderItemSummary.RETURNED_STATUS
            WITH USER_MODE
        ];
        for (OrderItemSummary ois : orderItemSummaries) {
            ois.COMM_QRCode__c = ois.Id;
            orderItemSummaryIdList.add(ois.id);
        }
        update orderItemSummaries;
        Test.startTest();
        List<OrderItemSummary> retrievedFullOrderItemSummaries = new COMM_REP_OrderItemSummary().getForVoucherPDF(new List<String>{ os.Id }, null);
        List<OrderItemSummary> retrievedListOrderItemSummaries = new COMM_REP_OrderItemSummary()
            .getForVoucherPDF(new List<String>{ os.Id }, orderItemSummaryIdList);
        Test.stopTest();
        Assert.areEqual(
            orderItemSummaries.size(),
            retrievedFullOrderItemSummaries.size(),
            'Expected all Order Items returned passing just the OrderSummaryID.'
        );
        Assert.areEqual(
            orderItemSummaries.size(),
            retrievedListOrderItemSummaries.size(),
            'Expected all Order Items returned passing the list of OrderItemSummaryIDs.'
        );
    }

    @isTest
    static void testGetOrderItemSummariesByOrderSummaryId() {
        List<OrderSummary> listOS = [SELECT Id FROM OrderSummary LIMIT 1];
        List<Id> expectedIds = new List<ID>();
        List<OrderItemSummary> listOiS = [SELECT Id FROM OrderItemSummary WHERE OrderSummaryID =: listOS[0].Id];
        for (OrderItemSummary ois : listOiS) {
            expectedIds.add(ois.Id);
        }
        Test.startTest();
        List<OrderItemSummary> orderItemSummaries = orderItemSummaryRep.getOrderItemSummariesByOrderSummaryId(listOS[0].Id);
        Test.stopTest();
        Assert.areEqual(expectedIds.size(), orderItemSummaries.size(), 'Number of order item summaries should be ' + expectedIds.size());
        Assert.isTrue(orderItemSummaries.size() > 0, 'Number of order item summaries should be greater than 0');
    }
}