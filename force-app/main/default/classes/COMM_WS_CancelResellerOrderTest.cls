/**
 * @author Daniel Reto
 * @description Class to test COMM_WS_CancelResellerOrder.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date        Coverage             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      04/11/2024  100                  Original version
 **/
@isTest
private class COMM_WS_CancelResellerOrderTest {
    @TestSetup
    static void makeData() {
        COMM_OMS_TestDataFactory.createOrderAndRelated();
    }

    @isTest
    static void testDoPostValidInput() {
        OrderItemSummary orderItemSummaryRecordQuery = [SELECT Id, OrderSummary.OriginalOrderId, OrderSummary.AccountId FROM OrderItemSummary LIMIT 1][0];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/reseller/orders/cancellations/v1/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(
            '{"resellerId":"resellerId","orderId":"resellerId-' + orderItemSummaryRecordQuery.OrderSummary.OriginalOrderId + '","orderItems":["OLI00000001"]}'
        );
        RestContext.request = req;
        RestContext.response = res;
        OrderItemSummary orderItemSummaryRecord = new OrderItemSummary(
            Id = orderItemSummaryRecordQuery.Id,
            COMM_OrderItemReferenceNumber__c = 'OLI00000001'
        );
        update orderItemSummaryRecord;
        Account accountRecord = new Account(
            Id = orderItemSummaryRecordQuery.OrderSummary.AccountId,
            COMM_ResellerId__c = 'resellerId'
        );
        update accountRecord;

        Test.startTest();
        COMM_WS_CancelResellerOrder.doPost();
        Test.stopTest();

        Assert.areEqual(200, res.statusCode, 'Response status code should be 200');
    }

    @isTest
    static void testDoPostInvalidInput() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/reseller/orders/cancellations/v1/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(
            '{"resellerId":"resellerId","orderId":"orderId","orderItems":[]}'
        );
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        COMM_WS_CancelResellerOrder.doPost();
        Test.stopTest();

        Assert.areEqual(400, res.statusCode, 'Response status code should be 400');
    }

    @isTest
    static void testDoPostInvalidErrorInput() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/reseller/orders/cancellations/v1/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(
            '{"resellerId":"resellerId","orderId":"orderId","orderItems":[]]}'
        );
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        COMM_WS_CancelResellerOrder.doPost();
        Test.stopTest();

        Assert.areEqual(400, res.statusCode, 'Response status code should be 400');
    }
}