/**
 * @author Diogo Gonçalves
 * @description Class to test COMM_WS_ResellerOrder.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date        Coverage             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  02/10/2024  73                  Original version
 * Daniel Reto      04/11/2024  95                  ECOMM-327
 **/
@isTest
private class COMM_WS_ResellerOrderTest {
    @TestSetup
    static void makeData() {
        COMM_OMS_TestDataFactory.createOrderAndRelated();
    }

    @isTest
    static void testDoPostInvalidInputError400() {
        COMM_SL_WS_Pricing pricingCalculationInstance = new COMM_SL_WS_Pricing();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/order/reseller/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(
            '{"resellerId":"","orderId":"orderId","orderItems":[{"orderLineId":"orderLineId","bundleProductId":"","bundleLineId":"1","productId":"001","startDate":"2024-08-19T09:01:01Z","endDate":"2024-08-20T09:01:01Z","passengerName":"passengerName"},{"orderLineId":"orderLineId","bundleProductId":"","bundleLineId":"2","productId":"002","startDate":"2024-08-19T09:01:01Z","endDate":"2024-08-20T09:01:01Z","passengerName":"passengerName"}]}'
        );
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        COMM_WS_ResellerOrder.doPost();
        Test.stopTest();

        Assert.areEqual(400, res.statusCode, 'Response status code should be 400');
        Assert.areEqual(
            '{"message":"resellerId is mandatory","errorCode":"ANA-COMMAPI00003"}',
            res.responseBody.toString(),
            'Response should match expected'
        );
    }

    @isTest
    static void testDoPostInvalidInputError500() {
        COMM_SL_WS_Pricing pricingCalculationInstance = new COMM_SL_WS_Pricing();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/order/reseller/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(
            '{resellerId":"resellerId","orderId":"orderId","orderItems":[{"orderLineId":"orderLineId","bundleProductId":"","bundleLineId":"1","productId":"001","startDate":"2024-08-19T09:01:01Z","endDate":"2024-08-20T09:01:01Z","passengerName":"passengerName"},{"orderLineId":"orderLineId","bundleProductId":"","bundleLineId":"2","productId":"002","startDate":"2024-08-19T09:01:01Z","endDate":"2024-08-20T09:01:01Z","passengerName":"passengerName"}]}'
        );
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        COMM_WS_ResellerOrder.doPost();
        Test.stopTest();

        Assert.areEqual(500, res.statusCode, 'Response status code should be 500');
        Assert.areEqual(
            '{"message":"Unexpected character (\'r\' (code 114)): was expecting double-quote to start field name at [line:1, column:3]","errorCode":"ANA-OCI00000"}',
            res.responseBody.toString(),
            'Response should match expected'
        );
    }
}