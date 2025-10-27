/**
 * @author           Daniel Reto
 * @description      COMM_WS_GetOrderDetails test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      27/06/2024      100            Original version
 **/
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
@isTest
private class COMM_WS_GetOrderDetailsTest {
    @TestSetup
    static void makeData() {
        Id orderId = COMM_OMS_TestDataFactory.createOrderAndRelated();
    }

    @IsTest
    static void getOrderDetailsSuccessResponseTest() {
        
        OrderSummary orderSummaryRecord = [SELECT Id, OrderNumber FROM orderSummary][0];

        // Build Request ApexRest
        String sfdcBaseURL = URL.getOrgDomainURL().toExternalForm();
        String endpoint = sfdcBaseURL + '/services/apexrest/orders/detail/' + orderSummaryRecord.OrderNumber;

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = endpoint; //Request URL
        req.httpMethod = 'GET'; //HTTP Request Type
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        COMM_WS_GetOrderDetails.getOrderDetails();
        Test.stopTest();

        // Asserts - Expecting a success response
        Assert.areEqual(200, RestContext.response.statusCode, 'Expected a 200 HTTP status code.');
    }

    @IsTest
    static void getOrderDetailsWrongDatesTest() {

        // Build Request ApexRest
        String sfdcBaseURL = URL.getOrgDomainURL().toExternalForm();
        String endpoint = sfdcBaseURL + '/services/apexrest/orders/detail/InvalidOrderNumber';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = endpoint; //Request URL
        req.httpMethod = 'GET'; //HTTP Request Type
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        COMM_WS_GetOrderDetails.getOrderDetails();
        Test.stopTest();

        // Asserts - Expecting a failure response
        Assert.areEqual(500, RestContext.response.statusCode, 'Expected a 500 HTTP status code due to invalid input.');
    }
}