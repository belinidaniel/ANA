/**
 * @author           Daniel Reto
 * @description      COMM_WS_CancelOrders test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      03/07/2024      100            Original version
 **/
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
@isTest
private class COMM_WS_CancelOrdersTest {
    @TestSetup
    static void makeData() {
        Id orderId = COMM_OMS_TestDataFactory.createOrderAndRelated();
    }

    @IsTest
    static void cancelOrderSuccessResponseTest() {
        String apexRestRequestBodyMock =
            '{' +
            '        \"accountId\": \"\",' +
            '        \"email\": \"test.test@ana.pt.invalid\",' +
            '        \"orderNumber\": \"STU-100174\",' +
            '        \"orderSummaryId\": \"\",' +
            '        \"partial\": false,' +
            '        \"orderProductSummaryIds\": [\"123\", \"456\", \"789\"]' +
            '}';

        // Build Request ApexRest
        String sfdcBaseURL = URL.getOrgDomainURL().toExternalForm();
        String endpoint = sfdcBaseURL + '/services/apexrest/orders/cancel';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = endpoint; //Request URL
        req.httpMethod = 'POST'; //HTTP Request Type
        req.requestBody = Blob.valueof(apexRestRequestBodyMock);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        COMM_WS_CancelOrders.cancelOrder();
        Test.stopTest();

        // Asserts - Expecting a success response
        Assert.areEqual(200, RestContext.response.statusCode, 'Expected a 200 HTTP status code.');
    }

    @IsTest
    static void searchGuestOrdersWrongDatesTest() {
        String apexRestRequestBodyMock =
            '{' +
            '        \"accountId\": \"\"\",' +
            '        \"email\": \"\",' +
            '        \"orderNumber\": \"STU-100174\",' +
            '        \"orderSummaryId\": \"\",' +
            '        \"partial\": false,' +
            '        \"orderProductSummaryIds\": [\"123\", \"456\", \"789\"]' +
            '}';

        // Build Request ApexRest
        String sfdcBaseURL = URL.getOrgDomainURL().toExternalForm();
        String endpoint = sfdcBaseURL + '/services/apexrest/orders/cancel';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = endpoint; //Request URL
        req.httpMethod = 'POST'; //HTTP Request Type
        req.requestBody = Blob.valueof(apexRestRequestBodyMock);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        COMM_WS_CancelOrders.cancelOrder();
        Test.stopTest();

        // Asserts - Expecting a failure response
        Assert.areEqual(500, RestContext.response.statusCode, 'Expected a 500 HTTP status code due to invalid input.');
    }
}