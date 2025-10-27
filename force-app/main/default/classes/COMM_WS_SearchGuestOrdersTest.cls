/**
 * @author           Daniel Reto
 * @description      COMM_WS_SearchGuestOrders test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      25/06/2024      100            Original version
 **/
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
@isTest
private class COMM_WS_SearchGuestOrdersTest {
    @TestSetup
    static void makeData() {
        Id orderId = COMM_OMS_TestDataFactory.createOrderAndRelated();
    }

    @IsTest
    static void searchGuestOrdersSuccessResponseTest() {
        String apexRestRequestBodyMock =
            '{' +
            '        \"email\": \"test.test@ana.pt.invalid\",' +
            '        \"zipCode\": \"13014\",' +
            '        \"page\": 0,' +
            '        \"pageSize\": 10,' +
            '        \"orderStartDate\": \"2024-06-05\",' +
            '        \"orderEndDate\": \"2024-06-05\",' +
            '        \"reservationStartDate\": null,' +
            '        \"reservationEndDate\": null,' +
            '        \"orderNumber\": \"STU-100174\",' +
            '        \"licensePlate\": null,' +
            '        \"productTypes\": [\"PARKING\", \"FASTTRACK\", \"LOUNGE\", \"SUBSCRIPTION\"],' +
            '        \"airports\": [\"LIS\", \"OPO\", \"FNC\", \"FAO\", \"PDL\"],' +
            '        \"status\": [3]' +
            '}';

        // Build Request ApexRest
        String sfdcBaseURL = URL.getOrgDomainURL().toExternalForm();
        String endpoint = sfdcBaseURL + '/services/apexrest/orders/guest';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = endpoint; //Request URL
        req.httpMethod = 'POST'; //HTTP Request Type
        req.requestBody = Blob.valueof(apexRestRequestBodyMock);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        COMM_WS_SearchGuestOrders.searchCustomerOrders();
        Test.stopTest();

        // Asserts - Expecting a success response
        Assert.areEqual(200, RestContext.response.statusCode, 'Expected a 200 HTTP status code.');
    }

    @IsTest
    static void searchGuestOrdersWrongDatesTest() {
        String apexRestRequestBodyMock =
            '{' +
            '        \"email\": \"test.test@ana.pt.invalid\",' +
            '        \"zipCode\": \"13014\",' +
            '        \"page\": 0,' +
            '        \"pageSize\": 10,' +
            '        \"orderStartDate\": \"2024-06-05\",' +
            '        \"orderEndDate\": \"2024-06-05\",' +
            '        \"reservationStartDate\": \"2024-06-05\",' +
            '        \"reservationEndDate\": null,' +
            '        \"orderNumber\": \"STU-100174\",' +
            '        \"licensePlate\": null,' +
            '        \"productTypes\": [\"PARKING\", \"FASTTRACK\", \"LOUNGE\", \"SUBSCRIPTION\"],' +
            '        \"airports\": [\"LIS\", \"OPO\", \"FNC\", \"FAO\", \"PDL\"],' +
            '        \"status\": [3]' +
            '}';

        // Build Request ApexRest
        String sfdcBaseURL = URL.getOrgDomainURL().toExternalForm();
        String endpoint = sfdcBaseURL + '/services/apexrest/orders/guest';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = endpoint; //Request URL
        req.httpMethod = 'POST'; //HTTP Request Type
        req.requestBody = Blob.valueof(apexRestRequestBodyMock);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        COMM_WS_SearchGuestOrders.searchCustomerOrders();
        Test.stopTest();

        // Asserts - Expecting a failure response
        Assert.areEqual(500, RestContext.response.statusCode, 'Expected a 500 HTTP status code due to invalid input.');
    }
}