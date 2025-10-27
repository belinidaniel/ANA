/**
 * @author Daniel Reto
 * @description Class to test COMM_SL_WS_CancelResellerOrder.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date        Coverage             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      04/11/2024  88                  Original version
 **/
@isTest
private class COMM_SL_WS_CancelResellerOrderTest {
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
    static void testDoPostInvalidResellerIdInput() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/reseller/orders/cancellations/v1/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(
            '{"resellerId":"","orderId":"orderId","orderItems":["OLI00000001"]}'
        );
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        COMM_WS_CancelResellerOrder.doPost();
        Test.stopTest();

        Assert.areEqual(400, res.statusCode, 'Response status code should be 400');
        Assert.areEqual(res.responseBody.toString(), '{"message":"' + COMM_CommerceAPI_Constants.ERROR_MESSAGE_MAP.get(COMM_CommerceAPI_Constants.BLANK_RESSELER) + '","errorCode":"' + COMM_CommerceAPI_Constants.BLANK_RESSELER + '"}', 'Wrong error message returned');
    }

    @isTest
    static void testDoPostInvalidOrderIdInput() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/reseller/orders/cancellations/v1/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(
            '{"resellerId":"resellerId","orderId":"","orderItems":["OLI00000001"]}'
        );
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        COMM_WS_CancelResellerOrder.doPost();
        Test.stopTest();

        Assert.areEqual(400, res.statusCode, 'Response status code should be 400');
        Assert.areEqual(res.responseBody.toString(), '{"message":"' + COMM_CommerceAPI_Constants.ERROR_MESSAGE_MAP.get(COMM_CommerceAPI_Constants.BLANK_ORDER_ID) + '","errorCode":"' + COMM_CommerceAPI_Constants.BLANK_ORDER_ID + '"}', 'Wrong error message returned');
    }

    @isTest
    static void testDoPostInvalidOrderItemsInput() {
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
        Assert.areEqual(res.responseBody.toString(), '{"message":"' + COMM_CommerceAPI_Constants.ERROR_MESSAGE_MAP.get(COMM_CommerceAPI_Constants.NO_ORDER_ITEMS) + '","errorCode":"' + COMM_CommerceAPI_Constants.NO_ORDER_ITEMS + '"}', 'Wrong error message returned');
    }

    @isTest
    static void testDoPostInvalidOrderItemMissingInput() {
        OrderItemSummary orderItemSummaryRecordQuery = [SELECT Id, OrderSummary.OriginalOrderId, OrderSummary.AccountId FROM OrderItemSummary LIMIT 1][0];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/reseller/orders/cancellations/v1/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(
            '{"resellerId":"resellerId","orderId":"resellerId-' + orderItemSummaryRecordQuery.OrderSummary.OriginalOrderId + '","orderItems":["OLI00000001", "OLI00000002"]}'
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

        Assert.areEqual(400, res.statusCode, 'Response status code should be 400');
        Assert.areEqual(res.responseBody.toString(), '{"message":"' + COMM_CommerceAPI_Constants.ERROR_MESSAGE_MAP.get(COMM_CommerceAPI_Constants.INVALID_ORDER_ITEMS) + 'OLI00000002 ","errorCode":"' + COMM_CommerceAPI_Constants.INVALID_ORDER_ITEMS + '"}', 'Wrong error message returned');
    }

    @isTest
    static void testDoPostInvalidErrorInput() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/reseller/orders/cancellations/v1/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(
            '{"resellerId":"resellerId","orderId":"orderId","orderItems":["OLI00000001"]}'
        );
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        COMM_WS_CancelResellerOrder.doPost();
        Test.stopTest();

        Assert.areEqual(400, res.statusCode, 'Response status code should be 400');
        Assert.areEqual(res.responseBody.toString(), '{"message":"' + COMM_CommerceAPI_Constants.ERROR_MESSAGE_MAP.get(COMM_CommerceAPI_Constants.BAD_ORDER_SUMMARY_ID) + '","errorCode":"' + COMM_CommerceAPI_Constants.BAD_ORDER_SUMMARY_ID + '"}', 'Wrong error message returned');
    }
}